//
//  SpeechRecognitionService.swift
//  logcal
//
//  Records short audio on device, transcribes via OpenAI Whisper (Firebase callable).
//

import Foundation
import AVFoundation
import Combine
import OSLog

@MainActor
class SpeechRecognitionService: NSObject, ObservableObject {
    private let log = Logger(subsystem: "com.serene.logcal", category: "WhisperDictation")
    private let firebaseService = FirebaseService()
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var meteringTask: Task<Void, Never>?
    private var voicedSampleCount = 0
    private var totalMeterSamples = 0
    private var maxObservedLevel: CGFloat = 0.08

    @Published var isListening = false
    @Published var isTranscribing = false
    @Published var recognizedText = ""
    @Published var errorMessage: String?
    @Published var waveformSamples: [CGFloat] = Array(repeating: 0.08, count: 64)

    /// Called on the main actor when Whisper returns non-empty text (LogViewModel merges into `foodText`).
    var onTranscriptionResult: ((String) -> Void)?

    override init() {
        super.init()
    }

    /// Wait until any in-flight transcription finishes (e.g. before logging a meal).
    func waitUntilIdle() async {
        while isTranscribing {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
    }

    func requestMicrophoneAuthorization() async -> Bool {
        if #available(iOS 17.0, *) {
            let audioStatus = AVAudioApplication.shared.recordPermission
            if audioStatus != .granted {
                let granted = await withCheckedContinuation { continuation in
                    AVAudioApplication.requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
                if !granted {
                    errorMessage = AppError.permissionDenied("Microphone").errorDescription
                    return false
                }
            }
        } else {
            let audioStatus = AVAudioSession.sharedInstance().recordPermission
            if audioStatus != .granted {
                let granted = await withCheckedContinuation { continuation in
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
                if !granted {
                    errorMessage = AppError.permissionDenied("Microphone").errorDescription
                    return false
                }
            }
        }
        return true
    }

    func startListening() async {
        guard !isListening, !isTranscribing else {
            print("DEBUG: [SpeechRecognitionService] startListening skipped (listening=\(isListening) transcribing=\(isTranscribing))")
            return
        }

        guard await requestMicrophoneAuthorization() else {
            return
        }

        recognizedText = ""
        errorMessage = nil
        voicedSampleCount = 0
        totalMeterSamples = 0
        maxObservedLevel = 0.08

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = AppError.audioConfigurationError(error.localizedDescription).errorDescription
            print("DEBUG: [SpeechRecognitionService] Audio session error: \(error)")
            return
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("logcal-whisper-\(UUID().uuidString).m4a")
        recordingURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.isMeteringEnabled = true
            recorder.prepareToRecord()
            guard recorder.record() else {
                errorMessage = AppError.speechRecognitionError("Could not start recording").errorDescription
                recordingURL = nil
                return
            }
            audioRecorder = recorder
        } catch {
            errorMessage = AppError.audioConfigurationError(error.localizedDescription).errorDescription
            recordingURL = nil
            print("DEBUG: [SpeechRecognitionService] AVAudioRecorder error: \(error)")
            return
        }

        isListening = true
        startMetering()
        print("DEBUG: [SpeechRecognitionService] Recording started path=\(url.path)")
    }

    func stopListening() async {
        var perf = PerfLogger("speech_stop")
        guard isListening else {
            print("DEBUG: [SpeechRecognitionService] stopListening no-op (not listening)")
            perf.end("not_listening")
            return
        }

        isListening = false
        stopMetering(resetToIdle: false)
        audioRecorder?.stop()
        audioRecorder = nil
        perf.mark("recorder_stopped")

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        perf.mark("audio_session_deactivated")

        guard let url = recordingURL else {
            print("DEBUG: [SpeechRecognitionService] stopListening: missing recording URL")
            recordingURL = nil
            perf.end("missing_recording_url")
            return
        }
        recordingURL = nil

        guard FileManager.default.fileExists(atPath: url.path) else {
            print("DEBUG: [SpeechRecognitionService] Recording file missing at \(url.path)")
            try? FileManager.default.removeItem(at: url)
            perf.end("missing_recording_file")
            return
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
            perf.mark("recording_read", metadata: [
                "bytes": data.count,
            ])
        } catch {
            errorMessage = AppError.audioConfigurationError("Could not read recording").errorDescription
            try? FileManager.default.removeItem(at: url)
            print("DEBUG: [SpeechRecognitionService] Read recording failed: \(error)")
            perf.end("recording_read_failed")
            return
        }

        try? FileManager.default.removeItem(at: url)
        perf.mark("recording_removed")

        // Very small files are usually silence or a failed tap — avoid a slow network round-trip
        let minBytes = 1_500
        if data.count < minBytes {
            let msg = "Recording too short. Tap the mic, speak for a few seconds, then tap again."
            errorMessage = AppError.speechRecognitionError(msg).errorDescription
            log.warning("Audio too small (\(data.count) B) — need at least ~\(minBytes) B")
            print("DEBUG: [SpeechRecognitionService] Audio too small (\(data.count) B), skip transcription")
            perf.end("audio_too_small", metadata: [
                "bytes": data.count,
            ])
            return
        }

        // Reject clips that never showed enough real speech energy.
        if !hasClearSpeechEvidence() {
            let msg = "Couldn’t detect clear speech. Try again."
            errorMessage = AppError.speechRecognitionError(msg).errorDescription
            log.notice("Skipping transcription due to low speech evidence voiced=\(self.voicedSampleCount) total=\(self.totalMeterSamples) maxLevel=\(self.maxObservedLevel)")
            print("DEBUG: [SpeechRecognitionService] Low speech evidence, skip transcription voiced=\(voicedSampleCount) total=\(totalMeterSamples) maxLevel=\(maxObservedLevel)")
            perf.end("low_speech_evidence", metadata: [
                "maxLevel": maxObservedLevel,
                "totalSamples": totalMeterSamples,
                "voicedSamples": voicedSampleCount,
            ])
            return
        }

        isTranscribing = true
        perf.mark("transcription_started")
        defer {
            isTranscribing = false
            stopMetering(resetToIdle: true)
        }

        let t0 = CFAbsoluteTimeGetCurrent()
        do {
            print("DEBUG: [SpeechRecognitionService] Sending audio to transcribeAudio bytes=\(data.count)")
            log.debug("Sending \(data.count) bytes to transcribeAudio")
            let text = try await firebaseService.transcribeAudio(audioData: data, mimeType: "audio/m4a")
            perf.mark("transcription_response", metadata: [
                "chars": text.count,
            ])
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            recognizedText = trimmed
            let elapsed = CFAbsoluteTimeGetCurrent() - t0
            print("DEBUG: [SpeechRecognitionService] Whisper done in \(String(format: "%.2f", elapsed))s, chars=\(trimmed.count)")
            log.info("Whisper completed in \(String(format: "%.2f", elapsed))s, chars=\(trimmed.count)")
            if trimmed.isEmpty || shouldRejectTranscriptAsUnclearSpeech(trimmed) {
                let msg = "Couldn’t detect clear speech. Try again."
                errorMessage = AppError.speechRecognitionError(msg).errorDescription
                log.notice("Rejecting transcript as unclear speech")
                perf.end("transcript_rejected", metadata: [
                    "chars": trimmed.count,
                ])
            } else {
                onTranscriptionResult?(trimmed)
                perf.end("success", metadata: [
                    "chars": trimmed.count,
                ])
            }
        } catch {
            let elapsed = CFAbsoluteTimeGetCurrent() - t0
            if let appError = error as? AppError {
                errorMessage = appError.errorDescription
                print("DEBUG: [SpeechRecognitionService] Transcription failed after \(String(format: "%.2f", elapsed))s (AppError): \(appError.errorDescription ?? "")")
                log.error("Transcription failed after \(String(format: "%.2f", elapsed))s: \(appError.errorDescription ?? "")")
            } else {
                let message = error.localizedDescription
                errorMessage = AppError.speechRecognitionError(message).errorDescription
                print("DEBUG: [SpeechRecognitionService] Transcription failed after \(String(format: "%.2f", elapsed))s: \(message)")
                log.error("Transcription failed after \(String(format: "%.2f", elapsed))s: \(message)")
            }
            perf.end("failure", metadata: [
                "error": errorMessage ?? error.localizedDescription,
            ])
        }
    }

    func cancelListening() {
        guard isListening else {
            print("DEBUG: [SpeechRecognitionService] cancelListening no-op (not listening)")
            return
        }

        isListening = false
        recognizedText = ""
        errorMessage = nil
        stopMetering(resetToIdle: true)

        audioRecorder?.stop()
        audioRecorder = nil

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)

        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil

        print("DEBUG: [SpeechRecognitionService] Recording cancelled and discarded")
    }

    private func startMetering() {
        stopMetering(resetToIdle: true)
        meteringTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled, self.isListening {
                if let recorder = self.audioRecorder {
                    recorder.updateMeters()
                    let averagePower = recorder.averagePower(forChannel: 0)
                    let normalizedLevel = self.normalizePowerLevel(averagePower)
                    self.pushWaveformSample(normalizedLevel)
                }
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }

    private func stopMetering(resetToIdle: Bool) {
        meteringTask?.cancel()
        meteringTask = nil
        if resetToIdle {
            waveformSamples = Array(repeating: 0.08, count: waveformSamples.count)
        }
    }

    private func normalizePowerLevel(_ power: Float) -> CGFloat {
        guard power.isFinite else { return 0.08 }
        let minDb: Float = -55
        let clamped = max(power, minDb)
        let amplitude = pow(10, clamped / 20)
        return max(0.08, min(1.0, CGFloat(amplitude) * 2.4))
    }

    private func pushWaveformSample(_ sample: CGFloat) {
        totalMeterSamples += 1
        maxObservedLevel = max(maxObservedLevel, sample)
        if sample > 0.16 {
            voicedSampleCount += 1
        }
        var next = waveformSamples
        if !next.isEmpty {
            next.removeFirst()
        }
        let previous = next.last ?? 0.08
        let smoothed = (previous * 0.45) + (sample * 0.55)
        next.append(smoothed)
        waveformSamples = next
    }

    private func hasClearSpeechEvidence() -> Bool {
        guard totalMeterSamples > 0 else { return false }
        let voicedRatio = CGFloat(voicedSampleCount) / CGFloat(totalMeterSamples)
        return maxObservedLevel >= 0.22 || voicedSampleCount >= 4 || voicedRatio >= 0.12
    }

    private func shouldRejectTranscriptAsUnclearSpeech(_ text: String) -> Bool {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return true }

        // If the clip barely registered any speech energy but the model still produced text,
        // treat it as a likely hallucinated transcription.
        if !hasClearSpeechEvidence() {
            return true
        }

        return false
    }
}
