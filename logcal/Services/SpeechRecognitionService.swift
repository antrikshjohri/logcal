//
//  SpeechRecognitionService.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation
import Speech
import AVFoundation
import AVFAudio
import Combine

@MainActor
class SpeechRecognitionService: NSObject, ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: Constants.Locale.speechRecognition))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var isListening = false
    @Published var recognizedText = ""
    @Published var errorMessage: String?
    
    private var isUserInitiatedStop = false
    
    override init() {
        super.init()
    }
    
    func requestAuthorization() async -> Bool {
        // Request speech recognition authorization
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        if speechStatus != .authorized {
            errorMessage = AppError.permissionDenied("Speech recognition").errorDescription
            return false
        }
        
        // Use AVAudioApplication for iOS 17+ (deprecated APIs replaced)
        // Fallback to AVAudioSession for older iOS versions
        if #available(iOS 17.0, *) {
            // AVAudioApplication uses class methods, not instance methods
            let audioStatus = AVAudioApplication.shared.recordPermission
            
            // Check if permission is granted (enum comparison)
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
            // Fallback for iOS < 17
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
        guard !isListening else {
            return
        }
        
        // Check authorization
        guard await requestAuthorization() else {
            return
        }
        
        // Cancel previous task if exists
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = AppError.audioConfigurationError(error.localizedDescription).errorDescription
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = AppError.speechRecognitionError("Failed to create recognition request").errorDescription
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: Constants.Audio.bufferSize, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            errorMessage = AppError.audioConfigurationError(error.localizedDescription).errorDescription
            return
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcribedText = result.bestTranscription.formattedString
                Task { @MainActor in
                    self.recognizedText = transcribedText
                }
            }
            
            if let error = error {
                Task { @MainActor in
                    // Only show error if it wasn't a user-initiated cancellation
                    if !self.isUserInitiatedStop {
                        // Check if it's a cancellation error (which is expected when user stops)
                        let nsError = error as NSError
                        if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216 {
                            // This is a cancellation error, don't show it
                        } else {
                            // It's a real error, show it
                            self.errorMessage = AppError.speechRecognitionError(error.localizedDescription).errorDescription
                        }
                    }
                    self.stopListening()
                }
            }
        }
        
        isListening = true
        recognizedText = ""
        errorMessage = nil
        isUserInitiatedStop = false // Reset flag when starting
    }
    
    func stopListening() {
        guard isListening else {
            return
        }
        
        // Mark as user-initiated stop to avoid showing cancellation errors
        isUserInitiatedStop = true
        
        // Clear any error message since this is intentional
        errorMessage = nil
        
        // Set isListening to false first to update UI immediately
        isListening = false
        
        // Stop audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Deactivate audio session
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }
}

