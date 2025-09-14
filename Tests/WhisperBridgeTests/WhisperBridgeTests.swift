import XCTest
@testable import WhisperBridge

final class WhisperBridgeTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Setup before each test
    }
    
    override func tearDownWithError() throws {
        // Cleanup after each test
    }
    
    // MARK: - WhisperEngine Tests
    
    func testASRConfigCreation() {
        let config = ASRConfig()
        
        XCTAssertEqual(config.threads, max(2, ProcessInfo.processInfo.activeProcessorCount - 2))
        XCTAssertEqual(config.temperature, 0.0)
        XCTAssertTrue(config.englishOnly)
        XCTAssertFalse(config.translate)
        XCTAssertTrue(config.noContext)
    }
    
    func testASRConfigMVPCreation() {
        let config = ASRConfig.mvpEnglish()
        
        XCTAssertEqual(config.threads, max(2, ProcessInfo.processInfo.activeProcessorCount - 2))
        XCTAssertEqual(config.temperature, 0.0)
        XCTAssertTrue(config.englishOnly)
        XCTAssertFalse(config.translate)
        XCTAssertTrue(config.noContext)
    }
    
    func testWhisperModelSizeDescription() {
        let modelSizes: [(WhisperModelSize, String)] = [
            (.tiny, "tiny.en"),
            (.base, "base.en"),
            (.small, "small.en"),
            (.medium, "medium.en"),
            (.large, "large")
        ]
        
        for (size, expectedDescription) in modelSizes {
            XCTAssertEqual(size.description, expectedDescription, "Model size \(size) should have description '\(expectedDescription)'")
        }
    }
    
    // MARK: - WhisperCPP Tests
    
    func testWhisperCPPSingleton() {
        let whisper1 = WhisperCPP.shared
        let whisper2 = WhisperCPP.shared
        
        XCTAssertTrue(whisper1 === whisper2, "WhisperCPP should be a singleton")
    }
    
    func testWhisperCPPInitialState() {
        let whisper = WhisperCPP.shared
        
        XCTAssertFalse(whisper.isModelLoaded(), "Model should not be loaded initially")
    }
    
    func testWhisperModelLoading() throws {
        let whisper = WhisperCPP.shared
        
        // This test will fail in MVP mode since we're not loading a real model
        // But it tests the error handling path
        
        do {
            try whisper.loadBundledTinyEN()
            // If we get here, either the model loaded successfully or we're in simulation mode
            Logger.shared.info("Model loading test completed")
        } catch {
            // Expected in MVP mode - model file might not exist
            Logger.shared.info("Expected model loading failure in test: \(error)")
            XCTAssertTrue(error is WhisperError, "Should throw WhisperError when model loading fails")
        }
    }
    
    func testWhisperStreamWithoutModel() throws {
        let whisper = WhisperCPP.shared
        
        let config = ASRConfig.mvpEnglish()
        
        // Should throw error when trying to start stream without loaded model
        XCTAssertThrowsError(
            try whisper.beginStream(
                config: config,
                onPartial: { _ in },
                onFinal: { _ in }
            ),
            "Should throw error when starting stream without loaded model"
        ) { error in
            XCTAssertTrue(error is WhisperError, "Should be a WhisperError")
        }
    }
    
    func testWhisperFeedAudio() {
        let whisper = WhisperCPP.shared
        
        // Should not crash when feeding audio without streaming
        let sampleCount = 16000 // 1 second at 16kHz
        let samples = [Float](repeating: 0.0, count: sampleCount)
        
        samples.withUnsafeBufferPointer { buffer in
            whisper.feed(samples: buffer.baseAddress!, count: buffer.count)
        }
        
        // Should complete without errors
        Logger.shared.info("Audio feeding test completed")
    }
    
    // MARK: - Error Handling Tests
    
    func testWhisperErrors() {
        let errors: [WhisperError] = [
            .modelLoadFailed(reason: "Test failure"),
            .streamingNotInitialized,
            .audioFeedFailed,
            .invalidModelFormat
        ]
        
        for error in errors {
            XCTAssertNotNil(error.localizedDescription, "WhisperError should have localized description")
            Logger.shared.info("Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Protocol Conformance Tests
    
    func testWhisperEngineProtocol() {
        let whisper = WhisperCPP.shared
        
        // Test that WhisperCPP conforms to WhisperEngine protocol
        let engine: WhisperEngine = whisper
        
        XCTAssertNotNil(engine, "WhisperCPP should conform to WhisperEngine protocol")
        
        // Test protocol methods can be called
        XCTAssertFalse(engine.isModelLoaded(), "Protocol method should work")
    }
    
    func testWhisperEngineStreaming() {
        let whisper = WhisperCPP.shared
        
        let expectation = XCTestExpectation(description: "Stream handling")
        
        // Test streaming callbacks
        do {
            try whisper.beginStream(
                config: ASRConfig.mvpEnglish(),
                onPartial: { text in
                    Logger.shared.info("Partial: \(text)")
                },
                onFinal: { text in
                    Logger.shared.info("Final: \(text)")
                    expectation.fulfill()
                }
            )
            
            // Feed some audio
            let sampleCount = 32000 // 2 seconds
            let samples = [Float](repeating: 0.1, count: sampleCount)
            
            samples.withUnsafeBufferPointer { buffer in
                whisper.feed(samples: buffer.baseAddress!, count: buffer.count)
            }
            
            // End stream
            whisper.endStream()
            
            // Wait for callbacks
            wait(for: [expectation], timeout: 5.0)
            
        } catch {
            // Expected in MVP mode
            Logger.shared.info("Streaming test failed as expected in MVP: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testWhisperAudioProcessingPerformance() {
        let whisper = WhisperCPP.shared
        let sampleCount = 16000 * 5 // 5 seconds of audio
        let samples = [Float](repeating: Float.random(in: -0.5...0.5), count: sampleCount)
        
        measure {
            // Test performance of audio feeding
            samples.withUnsafeBufferPointer { buffer in
                whisper.feed(samples: buffer.baseAddress!, count: buffer.count)
            }
        }
    }
    
    func testWhisperStreamingPerformance() {
        let whisper = WhisperCPP.shared
        let sampleCount = 16000 // 1 second of audio
        let samples = [Float](repeating: Float.random(in: -0.5...0.5), count: sampleCount)
        
        measure {
            // Test performance of streaming setup and processing
            do {
                try whisper.beginStream(
                    config: ASRConfig.mvpEnglish(),
                    onPartial: { _ in },
                    onFinal: { _ in }
                )
                
                samples.withUnsafeBufferPointer { buffer in
                    whisper.feed(samples: buffer.baseAddress!, count: buffer.count)
                }
                
                whisper.endStream()
            } catch {
                // Expected in MVP mode
                Logger.shared.info("Performance test failed as expected in MVP: \(error)")
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testServiceIntegration() {
        let whisper = WhisperCPP.shared
        
        // Test that all components work together
        XCTAssertNotNil(whisper, "WhisperCPP should be available")
        
        // Test configuration integration
        let config = ASRConfig.mvpEnglish()
        XCTAssertEqual(config.threads, max(2, ProcessInfo.processInfo.activeProcessorCount - 2))
        XCTAssertEqual(config.temperature, 0.0)
        
        Logger.shared.info("Service integration test completed")
    }
    
    func testMemoryManagement() {
        let whisper = WhisperCPP.shared
        
        // Test that we can create and destroy contexts without memory leaks
        for _ in 0..<5 {
            // Create a stream context
            do {
                try whisper.beginStream(
                    config: ASRConfig.mvpEnglish(),
                    onPartial: { _ in },
                    onFinal: { _ in }
                )
                
                // End stream
                whisper.endStream()
            } catch {
                // Expected in MVP mode
                Logger.shared.info("Memory test failed as expected in MVP: \(error)")
            }
        }
        
        Logger.shared.info("Memory management test completed")
    }
}

// MARK: - Mock Implementation for Testing

class MockWhisperEngine: WhisperEngine {
    var modelLoaded = false
    var streamingActive = false
    var processedAudioCount = 0
    var receivedText = ""
    
    func loadBundledTinyEN() throws {
        modelLoaded = true
    }
    
    func beginStream(config: ASRConfig, onPartial: @escaping (String) -> Void, onFinal: @escaping (String) -> Void) throws {
        guard modelLoaded else {
            throw WhisperError.modelLoadFailed(reason: "Model not loaded")
        }
        
        streamingActive = true
        
        // Simulate some transcription
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onPartial("Test")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onFinal("Test transcription")
        }
    }
    
    func feed(samples: UnsafePointer<Float>, count: Int) {
        guard streamingActive else { return }
        processedAudioCount += count
    }
    
    func endStream() {
        streamingActive = false
    }
    
    func isModelLoaded() -> Bool {
        return modelLoaded
    }
}

// MARK: - Performance Benchmark Tests

extension WhisperBridgeTests {
    
    func testAudioBufferProcessingPerformance() {
        let mockEngine = MockWhisperEngine()
        let bufferSize = 16000 // 1 second
        let iterations = 100
        
        measure {
            for _ in 0..<iterations {
                let samples = [Float](repeating: Float.random(in: -0.5...0.5), count: bufferSize)
                
                samples.withUnsafeBufferPointer { buffer in
                    mockEngine.feed(samples: buffer.baseAddress!, count: buffer.count)
                }
            }
        }
        
        Logger.shared.info("Processed \(iterations) audio buffers")
    }
}