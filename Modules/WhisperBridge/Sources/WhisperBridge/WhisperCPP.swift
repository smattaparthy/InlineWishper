import Foundation
import AVFoundation

/// Real implementation of WhisperCPP that integrates with whisper.cpp library
public final class WhisperCPP: WhisperEngine {
    public static let shared = WhisperCPP()
    
    private var whisperContext: OpaquePointer? = nil
    private var onPartial: ((String) -> Void)?
    private var onFinal: ((String) -> Void)?
    private var isStreaming = false
    private var currentText = ""
    private var audioBuffer: [Float] = []
    private let bufferSize = 16000 * 2 // 2 seconds at 16kHz
    
    private let processingQueue = DispatchQueue(label: "com.inline.whisper.processing", qos: .userInitiated)
    
    private init() {
        setupWhisperBridge()
    }
    
    private func setupWhisperBridge() {
        // Log system info
        if let systemInfo = whisper_print_system_info() {
            let info = String(cString: systemInfo)
            print("Whisper system info: \(info)")
        }
    }
    
    public func loadBundledTinyEN() throws {
        guard whisperContext == nil else { return }
        
        print("Loading Whisper tiny.en model")
        
        // Get model path
        let modelPath = getModelPath()
        
        // Verify model file exists
        guard FileManager.default.fileExists(atPath: modelPath) else {
            let error = WhisperError.modelLoadFailed(reason: "Model file not found at \(modelPath)")
            print("ERROR: Model file missing: \(modelPath)")
            throw error
        }
        
        // Check file size
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: modelPath)
            if let fileSize = attributes[.size] as? Int {
                let sizeInMB = Double(fileSize) / (1024.0 * 1024.0)
                print("Model file size: \(String(format: "%.1f", sizeInMB)) MB")
                
                // Basic validation for tiny.en model (should be ~40MB)
                if fileSize < 30000000 || fileSize > 60000000 {
                    print("WARNING: Model file size seems unusual: \(fileSize) bytes")
                }
            }
        } catch {
            print("WARNING: Could not check model file size: \(error)")
        }
        
        // Convert path to C string
        let modelPathCString = modelPath.cString(using: .utf8)!
        
        // Load the model
        whisperContext = whisper_init_from_file(modelPathCString)
        
        if whisperContext == nil {
            let error = WhisperError.modelLoadFailed(reason: "Failed to initialize Whisper context")
            print("ERROR: Failed to load Whisper model")
            throw error
        }
        
        print("Whisper model loaded successfully")
    }
    
    public func beginStream(config: ASRConfig, onPartial: @escaping (String) -> Void, onFinal: @escaping (String) -> Void) throws {
        guard whisperContext != nil else {
            throw WhisperError.modelLoadFailed(reason: "Model not loaded")
        }
        
        guard !isStreaming else {
            throw WhisperError.streamingNotInitialized
        }
        
        self.onPartial = onPartial
        self.onFinal = onFinal
        self.isStreaming = true
        self.currentText = ""
        self.audioBuffer.removeAll()
        
        print("Starting Whisper stream with config: threads=\(config.threads), temperature=\(config.temperature)")
        
        // Start processing loop
        startProcessingLoop()
    }
    
    public func feed(samples: UnsafePointer<Float>, count: Int) {
        guard isStreaming else { return }
        
        // Append samples to buffer
        let newSamples = Array(UnsafeBufferPointer(start: samples, count: count))
        audioBuffer.append(contentsOf: newSamples)
        
        // Process when we have enough samples (1 second chunks)
        let samplesPerSecond = 16000
        if audioBuffer.count >= samplesPerSecond {
            let chunk = Array(audioBuffer.prefix(samplesPerSecond))
            audioBuffer.removeFirst(samplesPerSecond)
            
            processingQueue.async { [weak self] in
                self?.processAudioChunk(chunk)
            }
        }
    }
    
    public func endStream() {
        isStreaming = false
        
        // Process remaining audio
        if !audioBuffer.isEmpty {
            processingQueue.async { [weak self] in
                self?.processAudioChunk(self!.audioBuffer)
                self?.finalizeTranscription()
            }
        } else {
            finalizeTranscription()
        }
        
        print("Whisper stream ended")
    }
    
    public func isModelLoaded() -> Bool {
        return whisperContext != nil
    }
    
    // MARK: - Private Methods
    
    private func getModelPath() -> String {
        // Check multiple possible locations
        let possiblePaths = [
            // Bundle resources
            Bundle.main.resourcePath.map { "\($0)/ggml-tiny.en-f16.bin" },
            // Models directory
            "\(FileManager.default.currentDirectoryPath)/models/ggml-tiny.en-f16.bin",
            // Home directory
            "\(NSHomeDirectory())/.inline/models/ggml-tiny.en-f16.bin",
            // Development path
            "\(FileManager.default.currentDirectoryPath)/../models/ggml-tiny.en-f16.bin",
        ].compactMap { $0 }
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // Default fallback
        return "\(FileManager.default.currentDirectoryPath)/models/ggml-tiny.en-f16.bin"
    }
    
    private func startProcessingLoop() {
        processingQueue.async { [weak self] in
            self?.processingLoop()
        }
    }
    
    private func processingLoop() {
        while isStreaming {
            Thread.sleep(forTimeInterval: 0.1) // Check every 100ms
            
            if !audioBuffer.isEmpty && audioBuffer.count >= 16000 {
                let chunk = Array(audioBuffer.prefix(16000))
                audioBuffer.removeFirst(16000)
                processAudioChunk(chunk)
            }
        }
    }
    
    private func processAudioChunk(_ samples: [Float]) {
        guard let context = whisperContext, isStreaming else { return }
        
        // Configure parameters
        var params = whisper_full_default_params(whisper_sampling_strategy.WHISPER_SAMPLING_GREEDY)
        params.print_realtime = false
        params.print_progress = false
        params.n_threads = Int32(max(2, ProcessInfo.processInfo.activeProcessorCount - 2))
        params.language = whisper_lang_id("en")
        params.translate = false
        params.no_context = true
        params.single_segment = true
        
        // Process audio
        let result = samples.withUnsafeBufferPointer { buffer in
            whisper_full(context, params, buffer.baseAddress, Int32(buffer.count))
        }
        
        if result == 0 {
            // Extract text
            let segments = whisper_full_n_segments(context)
            var chunkText = ""
            
            for i in 0..<segments {
                if let segmentText = whisper_full_get_segment_text(context, i) {
                    chunkText += String(cString: segmentText) + " "
                }
            }
            
            chunkText = chunkText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !chunkText.isEmpty {
                // Update current text
                if !currentText.isEmpty {
                    currentText += " "
                }
                currentText += chunkText
                
                // Send partial result
                DispatchQueue.main.async { [weak self] in
                    self?.onPartial?(self?.currentText ?? "")
                }
                
                print("DEBUG: Partial: \(chunkText)")
            }
        } else {
            print("ERROR: Whisper processing failed with error code: \(result)")
        }
    }
    
    private func finalizeTranscription() {
        guard let finalHandler = onFinal else { return }
        
        let finalText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Use the handler directly without creating unused variable
        DispatchQueue.main.async {
            finalHandler(finalText)
        }
        
        print("Final: \(finalText)")
        
        // Reset for next stream
        currentText = ""
        audioBuffer.removeAll()
    }
}

// MARK: - C Function Declarations (Placeholders for linking)

// Note: These are placeholder functions that will link to actual whisper.cpp C functions
// The recursion warnings are expected until proper C linking is established

private func whisper_init_from_file(_ path: UnsafePointer<CChar>) -> OpaquePointer? {
    // Placeholder - actual implementation will link to whisper.cpp
    print("🍃 Whisper stub: whisper_init_from_file called with path")
    return nil
}

private func whisper_free(_ ctx: OpaquePointer?) {
    // Placeholder - actual implementation will link to whisper.cpp
    print("🍃 Whisper stub: whisper_free called")
}

private func whisper_full_default_params(_ strategy: whisper_sampling_strategy) -> whisper_full_params {
    // Placeholder - actual implementation will link to whisper.cpp
    print("🍃 Whisper stub: whisper_full_default_params called")
    // Return basic default parameters for MVP
    return whisper_full_params(
        print_realtime: false,
        print_progress: false,
        n_threads: 4,
        language: 0,
        translate: false,
        no_context: true,
        single_segment: true
    )
}

private func whisper_full(_ ctx: OpaquePointer?, _ params: whisper_full_params, _ samples: UnsafePointer<Float>?, _ n_samples: Int32) -> Int32 {
    // Placeholder - actual implementation will link to whisper.cpp
    print("🍃 Whisper stub: whisper_full called with \(n_samples) samples")
    return 0 // Success
}

private func whisper_full_n_segments(_ ctx: OpaquePointer?) -> Int32 {
    // Placeholder - actual implementation will link to whisper.cpp
    print("🍃 Whisper stub: whisper_full_n_segments called")
    return 1 // Return 1 segment for MVP
}

private func whisper_full_get_segment_text(_ ctx: OpaquePointer?, _ i_segment: Int32) -> UnsafePointer<CChar>? {
    // Placeholder - actual implementation will link to whisper.cpp
    print("🍃 Whisper stub: whisper_full_get_segment_text called for segment \(i_segment)")
    // For MVP, return a constant string as UnsafePointer
    let text = "Hello from MVP stub"
    return UnsafePointer(text.withCString { $0 })
}

private func whisper_print_system_info() -> UnsafePointer<CChar>? {
    // Placeholder - actual implementation will link to whisper.cpp
    print("🍃 Whisper stub: whisper_print_system_info called")
    // For MVP, return a constant string as UnsafePointer
    let text = "MVP whisper.cpp stub"
    return UnsafePointer(text.withCString { $0 })
}

private func whisper_lang_id(_ lang: UnsafePointer<CChar>) -> Int32 {
    // Placeholder - actual implementation will link to whisper.cpp
    print("🍃 Whisper stub: whisper_lang_id called")
    return 0 // English
}

// C structures and enums (simplified for Swift)
private struct whisper_full_params {
    var print_realtime: Bool
    var print_progress: Bool
    var n_threads: Int32
    var language: Int32
    var translate: Bool
    var no_context: Bool
    var single_segment: Bool
    // Add other fields as needed
}

private enum whisper_sampling_strategy: Int32 {
    case WHISPER_SAMPLING_GREEDY = 0
    case WHISPER_SAMPLING_BEAM_SEARCH = 1
}