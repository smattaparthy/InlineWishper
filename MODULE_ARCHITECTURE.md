# InlineWhisper Module Architecture & Dependencies

## Architecture Overview

InlineWhisper follows a modular architecture with clear separation of concerns, leveraging Swift Package Manager for dependency management. Each module has well-defined responsibilities and minimal dependencies on other modules.

---

## Module Dependency Graph

```
┌─────────────────────────────────────────────────────────────┐
│                        App Layer                            │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              InlineWhisperApp                         │  │
│  │  (SwiftUI + AppKit hybrid interface)                │  │
│  └─────────────────────┬─────────────────────────────────┘  │
│                        │                                    │
│  ┌─────────────────────▼─────────────────────────────────┐  │
│  │              Apple Shortcuts                         │  │
│  │         (AppIntents Extension)                      │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────┬───────────────────────────────────┘
                         │                                   
┌─────────────────────────▼───────────────────────────────────┐
│                    Business Logic Layer                     │
│                                                             │
│  ┌─────────────────────┬─────────────────────────────────┐  │
│  │   DictationKit      │      TranscribeKit            │  │
│  │  (Dictation Core)   │   (File Transcription)       │  │
│  └──────────┬──────────┴──────────┬────────────────────┘  │
│             │                     │                         │
│  ┌──────────▼──────────┐ ┌───────▼────────────────────┐  │
│  │   PostProcessKit    │ │      ModelsKit             │  │
│  │ (Text Processing)   │ │   (Model Management)       │  │
│  └─────────────────────┘ └────────────────────────────┘  │
└─────────────────────────┬───────────────────────────────────┘
                         │                                   
┌─────────────────────────▼───────────────────────────────────┐
│                    Service Layer                           │
│                                                             │
│  ┌─────────────────────┬─────────────────────────────────┐  │
│  │  WhisperBridge      │   WebRTCVADWrapper            │  │
│  │   (ASR Engine)      │  (Voice Detection)           │  │
│  └─────────────────────┴─────────────────────────────────┘  │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              SystemKit                                 │  │
│  │     (Permissions + Notifications + Settings)         │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Module Specifications

### 1. DictationKit
**Responsibility**: Core dictation orchestration and coordination

#### Components
```swift
// Primary Classes
public final class DictationOrchestrator: ObservableObject
public final class HotkeyManager
public final class AudioCaptureService
public final class VADService

// Insertion System
public enum InsertionStrategy { case paste, keystroke, accessibility }
public protocol Inserter { func insert(_ text: String, strategy: InsertionStrategy) throws }
public final class PasteInserter: Inserter
public final class KeystrokeInserter: Inserter  
public final class AccessibilityInserter: Inserter

// Command Processing
public final class CommandGrammar
public struct CommandMapping
```

#### Dependencies
- **WhisperBridge**: For ASR functionality
- **WebRTCVADWrapper**: For voice activity detection
- **PostProcessKit**: For text post-processing
- **ModelsKit**: For model management
- **SystemKit**: For system services

#### Public API
```swift
// DictationOrchestrator
public func start() throws
public func stop()
public func toggleDictation()
public func setInputDevice(_ deviceID: String)
public func setModel(_ model: WhisperModel)
```

---

### 2. WhisperBridge
**Responsibility**: Whisper.cpp integration with Swift interface

#### Components
```swift
// Core Protocol
public protocol WhisperEngine {
    func loadModel(at url: URL) throws
    func beginStream(config: ASRConfig, 
                    onPartial: @escaping (String) -> Void,
                    onFinal: @escaping (String) -> Void) throws
    func feed(samples: UnsafePointer<Float>, count: Int)
    func endStream()
}

// Implementation
public final class WhisperCPP: WhisperEngine
public struct ASRConfig
public enum WhisperModelSize { case tiny, base, small, medium, large }
```

#### Dependencies
- **System Libraries**: whisper.cpp (C++), Metal framework
- **No external Swift dependencies**

#### Implementation Details
- Static library linking with whisper.cpp
- Metal acceleration for Apple Silicon
- Streaming API with partial/final callbacks
- Thread-safe audio feeding

---

### 3. WebRTCVADWrapper
**Responsibility**: Voice Activity Detection using WebRTC VAD

#### Components
```swift
public final class VADService {
    func shouldAccept(samples: [Float]) -> Bool
    func setSensitivity(_ level: VADSensitivity)
    func reset()
}

public enum VADSensitivity { case low, medium, high }
public struct VADConfig
```

#### Dependencies
- **WebRTC VAD**: Embedded C library (BSD license)
- **Accelerate**: For signal processing
- **No external Swift dependencies**

#### Implementation Details
- 10/20/30ms frame processing
- Configurable sensitivity levels
- End-of-speech detection with timeout
- Thread-safe for real-time audio

---

### 4. PostProcessKit
**Responsibility**: Text post-processing and enhancement

#### Components
```swift
public final class PostProcessor {
    func process(_ text: String) -> String
    func setLevel(_ level: PostLevel)
}

public enum PostLevel { case off, minimal, conservative }
public struct ProcessingRules

// Rule implementations
enum PunctuationRules
enum CapitalizationRules  
enum FillerRemovalRules
```

#### Dependencies
- **Foundation**: For string processing
- **No external dependencies**

#### Processing Pipeline
```
Raw Text → Punctuation → Capitalization → Filler Removal → Polished Text
```

---

### 5. TranscribeKit
**Responsibility**: File-based transcription and export

#### Components
```swift
public final class FileTranscriber {
    func transcribe(_ file: URL, 
                   progress: @escaping (Double) -> Void) async throws -> Transcript
    func transcribeBatch(_ files: [URL]) async throws -> [Transcript]
}

public final class TranscriptExporter {
    func export(_ transcript: Transcript, 
               format: ExportFormat) throws -> URL
}

public enum ExportFormat { case txt, markdown, srt, vtt, json }
public struct Transcript
public struct Segment
public struct Word
```

#### Dependencies
- **ModelsKit**: For model management
- **WhisperBridge**: For transcription
- **AVFoundation**: For media processing
- **SystemKit**: For file operations

#### Supported Formats
- **Input**: WAV, MP3, M4A, AIFF, MP4, MOV
- **Output**: TXT, MD, SRT, VTT, JSON with timestamps

---

### 6. ModelsKit
**Responsibility**: Model management and distribution

#### Components
```swift
public final class ModelManager {
    func availableModels() -> [ModelInfo]
    func importModel(from url: URL) throws
    func setDefaultModel(_ model: ModelInfo)
    func removeModel(_ model: ModelInfo) throws
}

public final class BundledModelProvider {
    func provideBundledSmallEN() throws -> URL
}

public struct ModelInfo {
    let id: String
    let name: String
    let size: Int64
    let format: ModelFormat
    let language: String
}
```

#### Dependencies
- **Foundation**: For file management
- **CryptoKit**: For hash verification
- **No external dependencies**

#### Model Formats
- **Primary**: ggml (whisper.cpp format)
- **Secondary**: CTranslate2 (faster-whisper)
- **Bundled**: small.en ggml f16

---

### 7. SystemKit
**Responsibility**: System integration and services

#### Components
```swift
// Permissions
public enum Permissions {
    static func requestMicrophone() async -> Bool
    static func checkAccessibility() -> Bool
    static func requestAccessibility() async -> Bool
}

// Notifications
public final class NotificationService {
    func showNotification(_ notification: UserNotification)
}

// Settings
public final class Settings {
    func value<T>(for key: SettingKey) -> T?
    func setValue<T>(_ value: T, for key: SettingKey)
}

// Logging
public final class Logger {
    static func debug(_ message: String)
    static func info(_ message: String)
    static func error(_ message: String)
}
```

#### Dependencies
- **AVFoundation**: For microphone permissions
- **UserNotifications**: For local notifications
- **AppKit**: For accessibility APIs

#### Privacy-First Design
- No network access (sandboxed)
- Local-only data storage
- Optional debug logging (user controlled)
- Clear permission explanations

---

## Data Flow Architecture

### Dictation Pipeline
```
Microphone → AudioCapture → VAD → Whisper.cpp → PostProcess → Insertion → Target App
     │            │          │        │            │           │         │
     ▼            ▼          ▼        ▼            ▼           ▼         ▼
Permissions   16kHz Mono  Speech?  Streaming   Polish     Strategy  Paste/Keystroke
             Float32               Transcription Rules      Selection     /AX
```

### File Transcription Pipeline
```
Media File → AVFoundation → Audio Extract → Resample → Whisper.cpp → PostProcess → Export
     │            │              │           16kHz        Streaming     Rules     Format
     ▼            ▼              ▼                         ▼            ▼         ▼
Supported    Decode Audio    Clean Audio              Transcription   Polish    TXT/SRT
Formats      Streams        Remove Video                                        VTT/JSON
```

---

## Communication Patterns

### Inter-Module Communication

#### Observer Pattern (Combine)
```swift
// DictationOrchestrator publishes state changes
@Published var isListening: Bool
@Published var currentText: String
@Published var stateDescription: String

// UI components subscribe to changes
orchestrator.$isListening.sink { [weak self] isListening in
    self?.updateUI(isListening: isListening)
}
```

#### Delegate Pattern
```swift
// WhisperEngine uses delegates for callbacks
protocol WhisperEngineDelegate {
    func didReceivePartial(_ text: String)
    func didReceiveFinal(_ text: String)
    func didEncounterError(_ error: Error)
}
```

#### Notification Pattern
```swift
// System-wide notifications
extension Notification.Name {
    static let dictationStarted = Notification.Name("dictationStarted")
    static let dictationStopped = Notification.Name("dictationStopped")
    static let modelChanged = Notification.Name("modelChanged")
}
```

---

## Error Handling Strategy

### Error Types by Module

#### DictationKit Errors
```swift
public enum DictationError: Error {
    case microphoneUnavailable
    case hotkeyRegistrationFailed
    case insertionFailed(underlying: Error)
    case invalidState transition
}
```

#### WhisperBridge Errors
```swift
public enum WhisperError: Error {
    case modelLoadFailed(reason: String)
    case audioFeedFailed
    case streamingNotInitialized
    case metalAccelerationUnavailable
}
```

#### SystemKit Errors
```swift
public enum SystemError: Error {
    case permissionDenied(PermissionType)
    case notificationDeliveryFailed
    case settingsCorrupted
}
```

### Error Recovery
```swift
// Graceful degradation
func handleInsertionFailure(_ error: Error) {
    // Try next strategy in cascade
    switch currentStrategy {
    case .paste:
        try keystrokeInserter.insert(text)
    case .keystroke:
        try accessibilityInserter.insert(text)
    case .accessibility:
        throw DictationError.insertionFailed(underlying: error)
    }
}
```

---

## Testing Architecture

### Unit Testing Strategy

#### Mock Implementations
```swift
// Mock WhisperEngine for testing
class MockWhisperEngine: WhisperEngine {
    var shouldFail: Bool = false
    var mockTranscription: String = "Test transcription"
    
    func feed(samples: UnsafePointer<Float>, count: Int) {
        if !shouldFail {
            onPartial?(mockTranscription)
            onFinal?(mockTranscription)
        }
    }
}
```

#### Test Coverage Targets
- **DictationKit**: 85% (complex orchestration logic)
- **WhisperBridge**: 80% (integration with C++ code)
- **PostProcessKit**: 90% (pure logic, easily testable)
- **SystemKit**: 75% (system integration challenges)
- **TranscribeKit**: 80% (file I/O and format handling)
- **ModelsKit**: 85% (model management logic)
- **WebRTCVADWrapper**: 80% (audio processing)

### Integration Testing
```swift
// End-to-end dictation test
func testEndToEndDictation() {
    // Given
    let expectation = XCTestExpectation(description: "Dictation completes")
    
    // When
    orchestrator.start()
    audioPlayer.play(testAudioFile)
    
    // Then
    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
        XCTAssertFalse(self.orchestrator.isListening)
        XCTAssertFalse(self.orchestrator.currentText.isEmpty)
        expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 10)
}
```

---

## Performance Considerations

### Threading Model
```swift
// Audio thread (real-time)
DispatchQueue(label: "audio.capture", qos: .userInteractive)

// Processing thread (background)
DispatchQueue(label: "whisper.processing", qos: .userInitiated)

// UI thread (main)
DispatchQueue.main // For UI updates only

// Background thread (utility)
DispatchQueue.global(qos: .utility) // For file I/O
```

### Memory Management
```swift
// Audio buffer pooling
class AudioBufferPool {
    private var availableBuffers: [AudioBuffer] = []
    private let maxBuffers: Int = 10
    
    func acquire() -> AudioBuffer {
        return availableBuffers.popLast() ?? AudioBuffer()
    }
    
    func release(_ buffer: AudioBuffer) {
        if availableBuffers.count < maxBuffers {
            availableBuffers.append(buffer)
        }
    }
}
```

### Performance Monitoring
```swift
// Real-time performance metrics
class PerformanceMonitor {
    func measureAudioLatency() -> TimeInterval
    func measureTranscriptionSpeed() -> Float // RTF (Real-Time Factor)
    func measureMemoryUsage() -> (peak: UInt64, current: UInt64)
    func measureCPUUsage() -> Float // Percentage
}
```

---

## Security Architecture

### Privacy-First Design
```swift
// No network access verification
class PrivacyValidator {
    func verifyNoNetworkAccess() -> Bool {
        // Check entitlements
        // Verify no URLSession usage
        // Confirm no CFNetwork symbols
        return true
    }
}
```

### Data Protection
```swift
// Local-only storage
class SecureStorage {
    func saveTranscript(_ transcript: Transcript) throws {
        // Save to Application Support
        // No cloud sync
        // No external sharing
    }
}
```

### Permission Transparency
```swift
// Clear permission explanations
struct PermissionExplanation {
    let microphone: String = "We capture your microphone audio on-device for dictation. Audio never leaves your Mac."
    let accessibility: String = "We need Accessibility access to deliver keystrokes and insert text into other apps. Data never leaves your Mac."
}
```

This architecture provides a solid foundation for building InlineWhisper with clear module boundaries, proper dependency management, and scalable design patterns.