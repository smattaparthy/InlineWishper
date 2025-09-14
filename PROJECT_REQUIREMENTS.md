# InlineWhisper Project Requirements Document

## Executive Summary

InlineWhisper is a privacy-first, on-device dictation and transcription application for macOS that uses OpenAI's Whisper AI model for speech recognition. The app operates entirely offline, inserting transcribed text directly into any application via push-to-talk functionality.

## Core Requirements

### 1. Functional Requirements

#### 1.1 Dictation Features
- **Push-to-Talk Modes**: 
  - Hold-to-talk: Listen while held, insert on release
  - Press-to-toggle: Tap to start/stop
- **Global Hotkey**: Default Control+Option+D (configurable)
- **Real-time Streaming**: Partial transcriptions visible within 500-800ms
- **Voice Commands**: Basic editing commands (newline, tab, delete, undo, etc.)
- **Inline Insertion**: Text insertion into frontmost application with multiple strategies:
  - Paste mode (NSPasteboard + Cmd+V)
  - Keystroke mode (CGEvent synthesis)
  - Accessibility mode (AX API)

#### 1.2 Transcription Features
- **File Support**: WAV, MP3, M4A/AAC, AIFF, MP4/MOV
- **Export Formats**: TXT, Markdown, SRT, VTT, JSON
- **Batch Processing**: Queue multiple files for transcription
- **Word-level Timestamps**: Optional for file transcriptions

#### 1.3 ASR Engine
- **Bundled Model**: Whisper "small.en" pre-converted to ggml format
- **Model Management**: Users can add/switch models (tiny, base, small, medium)
- **Streaming Decoding**: Real-time with VAD-gated chunking
- **Performance**: Real-time or faster on M2+ Apple Silicon

#### 1.4 Post-Processing
- **Three Levels**:
  - Off: Raw transcription
  - Minimal: Punctuation and capitalization
  - Conservative: + filler word removal (uh, um, like, you know)
- **Configurable**: User can disable post-processing for minimal latency

### 2. Technical Requirements

#### 2.1 Platform & Performance
- **Target Platform**: macOS 15 Sequoia+ (Apple Silicon M-series only)
- **Performance Targets**:
  - First partial: ≤800ms on M2+ with small.en
  - Overall: Faster than real-time transcription
  - Memory: Efficient streaming to minimize RAM usage

#### 2.2 Architecture Components
- **UI Layer**: SwiftUI + AppKit hybrid
- **Audio Pipeline**: AVAudioEngine → VAD → Whisper.cpp → Post-processing
- **Insertion Engine**: Multi-strategy with per-app profiles
- **Model Manager**: Handle bundled and user-imported models
- **System Services**: Notifications, Settings, Permissions

#### 2.3 Module Structure
```
DictationKit/ - Core dictation orchestration
WhisperBridge/ - Whisper.cpp integration with Metal
WebRTCVADWrapper/ - Voice Activity Detection
PostProcessKit/ - Text post-processing rules
TranscribeKit/ - File transcription and exports
ModelsKit/ - Model management and bundling
SystemKit/ - Permissions, notifications, settings
```

### 3. Privacy & Security Requirements

#### 3.1 Privacy-First Design
- **No Network Access**: App sandbox with no network entitlements
- **On-Device Only**: All processing local, no cloud services
- **No Telemetry**: No data collection or analytics
- **Local Storage**: Sessions stored locally in Application Support

#### 3.2 Permissions
- **Microphone Access**: Required for audio capture
- **Accessibility Access**: Required for text insertion into other apps
- **Clear Onboarding**: User-friendly permission explanations

### 4. User Experience Requirements

#### 4.1 Interface Design
- **Menu Bar Extra**: Quick access to start/stop and status
- **Main Window**: Dictation view, file transcription, settings
- **Onboarding**: Permission requests, hotkey setup, quick test
- **Settings**: Comprehensive configuration options

#### 4.2 Target Applications
- **Primary Targets**: VS Code, Safari/Chrome, Apple Notes
- **Per-App Presets**: Customized insertion strategies for each app
- **Fallback Handling**: Automatic fallback between insertion methods

### 5. Non-Functional Requirements

#### 5.1 Reliability
- **Crash Safety**: State recovery and job persistence
- **Hotkey Robustness**: Conflict detection and guidance
- **Fallback Strategies**: Multiple insertion method fallbacks

#### 5.2 Accessibility
- **VoiceOver Support**: Full accessibility labels and navigation
- **Keyboard Navigation**: Complete keyboard control
- **High Contrast**: Support for accessibility display modes

#### 5.3 Internationalization
- **English v1**: English-only interface and models
- **i18n Ready**: Architecture prepared for future localization

### 6. Integration Requirements

#### 6.1 Apple Ecosystem
- **Shortcuts Support**: Apple Shortcuts app integration
- **Notifications**: Local notifications for completion
- **System Integration**: Native macOS look and feel

#### 6.2 Distribution
- **Direct Download**: Signed and notarized .app
- **No Auto-Update**: Manual update checks only
- **Apache 2.0 License**: Open source with permissive licensing

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)
- Set up development environment and dependencies
- Create project structure with Swift Package Manager
- Implement basic Whisper.cpp integration
- Set up audio capture pipeline

### Phase 2: Core Dictation (Weeks 3-4)
- Implement VAD and streaming ASR
- Create dictation orchestrator
- Build basic insertion engine (paste mode)
- Add menu bar interface

### Phase 3: Insertion Robustness (Weeks 5-6)
- Implement keystroke and accessibility insertion
- Create per-app profiles and fallback logic
- Add hotkey manager with conflict detection
- Build onboarding flow

### Phase 4: Polish & Performance (Weeks 7-8)
- Optimize latency and performance
- Implement post-processing pipeline
- Add voice command grammar
- Create settings interface

### Phase 5: File Transcription (Weeks 9-10)
- Build file transcription pipeline
- Create export functionality (TXT, SRT, VTT, JSON)
- Add batch processing capabilities
- Implement transcript editor

### Phase 6: Automation & Release (Weeks 11-12)
- Add Apple Shortcuts integration
- Implement model management UI
- Complete accessibility features
- Package, sign, and notarize for release

## Technical Dependencies

### Core Dependencies
- **whisper.cpp**: C++ implementation of Whisper with Metal support
- **WebRTC VAD**: Voice Activity Detection library
- **Swift Package Manager**: Module management
- **AVFoundation**: Audio capture and processing
- **AppKit/SwiftUI**: User interface framework

### Development Tools
- **Xcode 16+**: Primary development environment
- **CMake**: For building whisper.cpp
- **XcodeGen**: Project file generation
- **Git LFS**: Large file storage for models

### Build Requirements
- **macOS 15+**: Development and target platform
- **Apple Silicon**: M-series processor required
- **Developer ID**: For code signing and notarization

## Testing Strategy

### Unit Testing
- Audio pipeline components
- VAD logic and thresholds
- Post-processing rules
- Export format validation
- Command grammar parsing

### Integration Testing
- End-to-end dictation flow
- Multi-app insertion testing
- Model switching and performance
- Hotkey conflict resolution
- Permission flow validation

### Performance Testing
- Latency measurements across hardware
- Memory usage profiling
- Thermal stability testing
- Battery impact assessment

### Accessibility Testing
- VoiceOver navigation
- Keyboard-only operation
- High contrast display support
- Screen reader compatibility

## Risk Assessment & Mitigation

### Technical Risks
- **Paste Blocking**: Fallback to keystroke and accessibility modes
- **Accessibility Permission**: Clear onboarding with retry guidance
- **Model Performance**: Provide multiple model size options
- **Hardware Variation**: Extensive testing across M-series processors

### Privacy Risks
- **Data Leakage**: Network entitlement audit and static analysis
- **Clipboard Access**: Implement clipboard hygiene (restore after use)
- **Permission Abuse**: Clear user consent and minimal permission scope

### User Experience Risks
- **Hotkey Conflicts**: Detection and alternative suggestion system
- **App Compatibility**: Extensive testing with target applications
- **Learning Curve**: Comprehensive onboarding and help system

## Success Criteria

### Version 1.0 Acceptance Criteria
- [ ] Dictation latency ≤800ms first partial on M2+
- [ ] Inline insertion works in VS Code, Safari, Chrome, Notes
- [ ] Hotkey supports hold-to-talk and press-to-toggle modes
- [ ] Post-processing improves readability without hallucination
- [ ] App runs fully offline with no network entitlements
- [ ] Bundled Whisper model loads at first launch
- [ ] Users can import and switch between models
- [ ] Accessibility features fully implemented
- [ ] Signed and notarized for distribution
- [ ] Comprehensive documentation and user guide

This document serves as the authoritative requirements specification for the InlineWhisper project and should be reviewed and approved before implementation begins.