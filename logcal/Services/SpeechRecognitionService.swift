//
//  SpeechRecognitionService.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation
import Speech
import AVFoundation
import Combine

@MainActor
class SpeechRecognitionService: NSObject, ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var isListening = false
    @Published var recognizedText = ""
    @Published var errorMessage: String?
    
    private var isUserInitiatedStop = false
    
    override init() {
        super.init()
        print("DEBUG: SpeechRecognitionService initialized")
    }
    
    func requestAuthorization() async -> Bool {
        print("DEBUG: Requesting speech recognition authorization")
        
        // Request speech recognition authorization
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        let audioStatus = AVAudioSession.sharedInstance().recordPermission
        
        print("DEBUG: Speech authorization status: \(speechStatus.rawValue)")
        print("DEBUG: Audio authorization status: \(audioStatus.rawValue)")
        
        if speechStatus != .authorized {
            errorMessage = "Speech recognition permission denied"
            print("DEBUG: Speech recognition not authorized")
            return false
        }
        
        if audioStatus != .granted {
            print("DEBUG: Requesting microphone permission")
            let granted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
            if !granted {
                errorMessage = "Microphone permission denied"
                print("DEBUG: Microphone permission denied")
                return false
            }
        }
        
        print("DEBUG: All permissions granted")
        return true
    }
    
    func startListening() async {
        guard !isListening else {
            print("DEBUG: Already listening, ignoring start request")
            return
        }
        
        print("DEBUG: Starting speech recognition")
        
        // Check authorization
        guard await requestAuthorization() else {
            print("DEBUG: Authorization failed, cannot start listening")
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
            print("DEBUG: Audio session configured")
        } catch {
            print("DEBUG: Failed to configure audio session: \(error.localizedDescription)")
            errorMessage = "Failed to configure audio: \(error.localizedDescription)"
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("DEBUG: Failed to create recognition request")
            errorMessage = "Failed to create recognition request"
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            print("DEBUG: Audio engine started")
        } catch {
            print("DEBUG: Failed to start audio engine: \(error.localizedDescription)")
            errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
            return
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcribedText = result.bestTranscription.formattedString
                Task { @MainActor in
                    self.recognizedText = transcribedText
                    print("DEBUG: Recognized text: \(transcribedText)")
                }
            }
            
            if let error = error {
                print("DEBUG: Recognition error: \(error.localizedDescription)")
                Task { @MainActor in
                    // Only show error if it wasn't a user-initiated cancellation
                    if !self.isUserInitiatedStop {
                        // Check if it's a cancellation error (which is expected when user stops)
                        let nsError = error as NSError
                        if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216 {
                            // This is a cancellation error, don't show it
                            print("DEBUG: Recognition cancelled (expected)")
                        } else {
                            // It's a real error, show it
                            self.errorMessage = error.localizedDescription
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
        print("DEBUG: Speech recognition started successfully")
    }
    
    func stopListening() {
        guard isListening else {
            print("DEBUG: Not listening, ignoring stop request")
            return
        }
        
        print("DEBUG: Stopping speech recognition")
        
        // Mark as user-initiated stop to avoid showing cancellation errors
        isUserInitiatedStop = true
        
        // Clear any error message since this is intentional
        errorMessage = nil
        
        // Set isListening to false first to update UI immediately
        isListening = false
        
        // Stop audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
            do {
                audioEngine.inputNode.removeTap(onBus: 0)
            } catch {
                print("DEBUG: Error removing tap: \(error.localizedDescription)")
            }
        }
        
        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Deactivate audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            print("DEBUG: Audio session deactivated")
        } catch {
            print("DEBUG: Failed to deactivate audio session: \(error.localizedDescription)")
        }
        
        print("DEBUG: Speech recognition stopped")
    }
}

