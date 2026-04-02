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

    @Published var isListening = false
    @Published var isTranscribing = false
    @Published var recognizedText = ""
    @Published var errorMessage: String?

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
        print("DEBUG: [SpeechRecognitionService] Recording started path=\(url.path)")
    }

    func stopListening() async {
        guard isListening else {
            print("DEBUG: [SpeechRecognitionService] stopListening no-op (not listening)")
            return
        }

        isListening = false
        audioRecorder?.stop()
        audioRecorder = nil

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)

        guard let url = recordingURL else {
            print("DEBUG: [SpeechRecognitionService] stopListening: missing recording URL")
            recordingURL = nil
            return
        }
        recordingURL = nil

        guard FileManager.default.fileExists(atPath: url.path) else {
            print("DEBUG: [SpeechRecognitionService] Recording file missing at \(url.path)")
            try? FileManager.default.removeItem(at: url)
            return
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            errorMessage = AppError.audioConfigurationError("Could not read recording").errorDescription
            try? FileManager.default.removeItem(at: url)
            print("DEBUG: [SpeechRecognitionService] Read recording failed: \(error)")
            return
        }

        try? FileManager.default.removeItem(at: url)

        // Very small files are usually silence or a failed tap — avoid a slow network round-trip
        let minBytes = 1_500
        if data.count < minBytes {
            let msg = "Recording too short. Tap the mic, speak for a few seconds, then tap again."
            errorMessage = AppError.speechRecognitionError(msg).errorDescription
            log.warning("Audio too small (\(data.count) B) — need at least ~\(minBytes) B")
            print("DEBUG: [SpeechRecognitionService] Audio too small (\(data.count) B), skip transcription")
            return
        }

        isTranscribing = true
        defer { isTranscribing = false }

        let t0 = CFAbsoluteTimeGetCurrent()
        do {
            print("DEBUG: [SpeechRecognitionService] Sending audio to transcribeAudio bytes=\(data.count)")
            log.debug("Sending \(data.count) bytes to transcribeAudio")
            let text = try await firebaseService.transcribeAudio(audioData: data, mimeType: "audio/m4a")
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            recognizedText = trimmed
            let elapsed = CFAbsoluteTimeGetCurrent() - t0
            print("DEBUG: [SpeechRecognitionService] Whisper done in \(String(format: "%.2f", elapsed))s, chars=\(trimmed.count)")
            log.info("Whisper completed in \(String(format: "%.2f", elapsed))s, chars=\(trimmed.count)")
            if trimmed.isEmpty {
                let msg = "No speech detected. Try again, speak clearly, or check your connection."
                errorMessage = AppError.speechRecognitionError(msg).errorDescription
                log.notice("Whisper returned empty text")
            } else {
                onTranscriptionResult?(trimmed)
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
        }
    }
}
