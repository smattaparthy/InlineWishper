import XCTest
@testable import DictationKit
import SystemKit

final class DictationKitTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: - DictationService Tests
    
    func testDictationServiceSingleton() {
        let service1 = DictationService.shared
        let service2 = DictationService.shared
        
        XCTAssertTrue(service1 === service2, "DictationService should be a singleton")
    }
    
    func testDictationInitialState() {
        let service = DictationService.shared
        
        XCTAssertFalse(service.isListening, "Dictation should not be listening by default")
        XCTAssertEqual(service.currentText, "", "Current text should be empty by default")
        XCTAssertEqual(service.stateDescription, "Ready", "Initial state should be 'Ready'")
    }
    
    func testDictationToggle() {
        let service = DictationService.shared
        
        // Test toggle when not listening - should not throw in simulation mode
        XCTAssertNoThrow({
            service.toggleDictation()
            // The actual state change happens asynchronously, so we can't assert on it immediately
        }(), "Toggling dictation should not throw an error")
    }
    
    // MARK: - InsertionService Tests
    
    func testInsertionServiceSingleton() {
        let service1 = InsertionService.shared
        let service2 = InsertionService.shared
        
        XCTAssertTrue(service1 === service2, "InsertionService should be a singleton")
    }
    
    func testInsertionEmptyText() {
        let service = InsertionService.shared
        
        // Should not throw or cause issues with empty text
        XCTAssertNoThrow({
            service.insert("")
        }(), "Inserting empty text should not cause errors")
    }
    
    func testInsertionNormalText() {
        let service = InsertionService.shared
        
        let testText = "Hello, this is a test"
        
        XCTAssertNoThrow({
            service.insert(testText)
        }(), "Inserting normal text should not cause errors")
    }
    
    func testInsertionLongText() {
        let service = InsertionService.shared
        
        let testText = String(repeating: "This is a long test sentence. ", count: 10)
        
        XCTAssertNoThrow({
            service.insert(testText)
        }(), "Inserting long text should not cause errors")
    }
    
    // MARK: - AudioService Tests
    
    func testAudioServiceSingleton() {
        let service1 = AudioService.shared
        let service2 = AudioService.shared
        
        XCTAssertTrue(service1 === service2, "AudioService should be a singleton")
    }
    
    func testAudioServiceInitialization() {
        let service = AudioService.shared
        
        // AudioService should initialize without errors
        XCTAssertNotNil(service, "AudioService should initialize properly")
    }
    
    func testAvailableInputDevices() {
        let service = AudioService.shared
        
        let devices = service.availableInputDevices()
        
        XCTAssertFalse(devices.isEmpty, "Should have at least one input device")
        XCTAssertTrue(devices.contains("Built-in Microphone") || devices.contains("Default"), "Should have basic device options")
    }
    
    func testDeviceSelection() {
        let service = AudioService.shared
        
        XCTAssertNoThrow({
            try service.selectInputDevice("Default")
        }(), "Selecting a valid device should not throw")
        
        // Should handle invalid device gracefully (for MVP)
        XCTAssertNoThrow({
            try service.selectInputDevice("NonExistentDevice")
        }(), "Selecting an invalid device should not crash")
    }
    
    // MARK: - Error Handling Tests
    
    func testDictationErrors() {
        let errors: [DictationError] = [
            .microphonePermissionDenied,
            .audioCaptureFailed,
            .modelLoadFailed,
            .insertionFailed
        ]
        
        for error in errors {
            XCTAssertNotNil(error.localizedDescription, "Error should have a localized description")
        }
    }
    
    func testInsertionErrors() {
        let errors: [InsertionError] = [
            .clipboardAccessFailed,
            .pasteCommandFailed,
            .accessibilityPermissionDenied
        ]
        
        for error in errors {
            XCTAssertNotNil(error.localizedDescription, "Error should have a localized description")
        }
    }
    
    // MARK: - Integration Tests
    
    func testServiceIntegration() {
        let dictationService = DictationService.shared
        let insertionService = InsertionService.shared
        let audioService = AudioService.shared
        
        // All services should coexist without conflicts
        XCTAssertNotNil(dictationService, "DictationService should be available")
        XCTAssertNotNil(insertionService, "InsertionService should be available")
        XCTAssertNotNil(audioService, "AudioService should be available")
    }
}

// MARK: - Mock Services for Testing

class MockDictationService: DictationService {
    override func toggleDictation() {
        // Mock implementation for testing
        if isListening {
            stopDictation()
        } else {
            // Simulate successful start
            DispatchQueue.main.async {
                self.isListening = true
                self.stateDescription = "Listening..."
            }
        }
    }
    
    override func stopDictation() {
        // Mock implementation for testing
        DispatchQueue.main.async {
            self.isListening = false
            self.stateDescription = "Ready"
        }
    }
}

// MARK: - Performance Tests

extension DictationKitTests {
    
    func testAudioServicePerformance() {
        let service = AudioService.shared
        
        measure {
            // Test performance of device enumeration
            _ = service.availableInputDevices()
        }
    }
    
    func testInsertionServicePerformance() {
        let service = InsertionService.shared
        let testText = "Performance test text"
        
        measure {
            // Test performance of text insertion
            service.insert(testText)
        }
    }
}

// MARK: - Error Recovery Tests

extension DictationKitTests {
    
    func testAudioServiceRecovery() {
        let service = AudioService.shared
        
        // Test recovery after multiple start/stop cycles
        for _ in 0..<5 {
            XCTAssertNoThrow({
                try service.startCapture()
            }(), "Audio service should recover from multiple start cycles")
            
            XCTAssertNoThrow({
                service.stopCapture()
            }(), "Audio service should recover from multiple stop cycles")
        }
    }
}