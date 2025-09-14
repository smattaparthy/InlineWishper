import Foundation
import Combine
import AVFoundation
import WhisperBridge
import SystemKit

@MainActor
public final class DictationService: ObservableObject {
    public static let shared = DictationService()
    
    @Published public private(set) var isListening = false
    @Published public private(set) var currentText = ""
    @Published public private(set) var stateDescription = "Ready"
    
    private let audioService = AudioService()
    private let whisperService = WhisperCPP.shared
    private var cancellables = Set<AnyCancellable>()
    private var isProcessing = false
    
    private init() {
        setupBindings()
        configureAudioSession()
    }
    
    private func setupBindings() {
        audioService.onAudioSamples = { [weak self] samples in
            self?.processAudioSamples(samples)
        }
    }
    
    // macOS doesn't use AVAudioSession - audio is handled through AVAudioEngine
    private func configureAudioSession() {
        // For MVP, we'll just log that audio is ready
        "Audio engine configured for macOS (no AVAudioSession needed)".logInfo()
    }
    
    public func startDictation() async throws {
        guard !isListening else { return }
        
        "Starting dictation".logInfo()
        
        // Check permissions
        guard Permissions.checkMicrophoneAccess() else {
            throw DictationError.microphonePermissionDenied
        }
        
        // Reset state
        currentText = ""
        isListening = true
        stateDescription = "Listening..."
        
        do {
            // Start audio capture
            try audioService.startCapture()
            
            // Initialize Whisper streaming
            try whisperService.beginStream(
                config: .mvpEnglish(),
                onPartial: { [weak self] text in
                    Task { @MainActor in
                        self?.handlePartialText(text)
                    }
                },
                onFinal: { [weak self] text in
                    Task { @MainActor in
                        self?.handleFinalText(text)
                    }
                }
            )
            
            "Dictation started successfully".logInfo()
            
        } catch {
            isListening = false
            stateDescription = "Ready"
            "Failed to start dictation: \(error)".logError()
            throw error
        }
    }
    
    public func stopDictation() {
        guard isListening else { return }
        
        "Stopping dictation".logInfo()
        
        audioService.stopCapture()
        whisperService.endStream()
        
        isListening = false
        stateDescription = "Ready"
        
        "Dictation stopped".logInfo()
    }
    
    public func toggleDictation() {
        if isListening {
            stopDictation()
        } else {
            Task {
                do {
                    try await startDictation()
                } catch {
                    "Failed to toggle dictation: \(error)".logError()
                }
            }
        }
    }
    
    private func processAudioSamples(_ samples: [Float]) {
        guard isListening, !samples.isEmpty else { return }
        
        // Feed audio samples to Whisper
        samples.withUnsafeBufferPointer { buffer in
            whisperService.feed(samples: buffer.baseAddress!, count: buffer.count)
        }
    }
    
    private func handlePartialText(_ text: String) {
        currentText = text
        stateDescription = "Transcribing..."
        "Partial: \(text)".logDebug()
    }
    
    private func handleFinalText(_ text: String) {
        currentText = text
        stateDescription = "Complete"
        "Final: \(text)".logInfo()
        
        // Insert text into target application
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.insertText(text)
        }
    }
    
    private func insertText(_ text: String) {
        // Use the insertion service to insert text into target app
        InsertionService.shared.insert(text)
    }
}

public enum DictationError: Error {
    case microphonePermissionDenied
    case audioCaptureFailed
    case modelLoadFailed
    case insertionFailed
}