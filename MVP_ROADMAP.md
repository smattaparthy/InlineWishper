# InlineWhisper MVP Implementation Plan

## MVP Focus: Core Dictation in 4-6 Weeks

Based on your request for a faster MVP timeline focusing on core dictation functionality, this plan streamlines the implementation to deliver essential features quickly while maintaining quality and privacy standards.

---

## MVP Scope Definition

### Core Features (Must-Have)
```
✅ Basic dictation with push-to-talk
✅ Real-time transcription using Whisper
✅ Text insertion into applications (paste mode)
✅ Menu bar interface
✅ Basic settings (hotkey, input device)
✅ Whisper "tiny.en" model for speed
```

### Deferred Features (Post-MVP)
```
⏳ File transcription
⏳ Voice commands
⏳ Post-processing
⏳ Keystroke/AX insertion modes
⏳ Apple Shortcuts integration
⏳ Advanced settings
⏳ Model switching
```

---

## MVP Timeline: 4-6 Weeks

### Week 1: Foundation Setup (Days 1-7)
**Goal**: Working audio pipeline and Whisper integration

#### Day 1-2: Environment & Structure
```bash
# Setup development environment
git clone <repo>
git submodule update --init --recursive
brew install cmake xcodegen
./scripts/build_whisper.sh
xcodegen generate --spec ./configs/project.yml
```

#### Day 3-4: Core Module Structure
Create minimal module structure:
```
Modules/
├── DictationKit/ (core orchestration only)
├── WhisperBridge/ (basic integration)
└── SystemKit/ (permissions only)
```

#### Day 5-7: Audio Pipeline
- Implement [`AudioCaptureService`](Modules/DictationKit/Sources/DictationKit/AudioCaptureService.swift) with AVAudioEngine
- Create basic [`VADService`](Modules/DictationKit/Sources/DictationKit/VADService.swift) stub (always passes for MVP)
- Integrate Whisper Bridge with streaming API

**Deliverable**: Audio flows from microphone to Whisper, partial results appear in console

---

### Week 2: Basic Dictation Engine (Days 8-14)

#### Day 8-10: DictationOrchestrator
```swift
// Minimal MVP orchestrator
class DictationOrchestrator: ObservableObject {
    @Published var isListening = false
    @Published var currentText = ""
    
    func start() throws { /* MVP implementation */ }
    func stop() { /* MVP implementation */ }
    func toggleDictation() { /* MVP implementation */ }
}
```

#### Day 11-12: Menu Bar Interface
Create basic menu bar extra:
```swift
MenuBarExtra("InlineWhisper", systemImage: "mic") {
    Button(orchestrator.isListening ? "Stop" : "Start") {
        orchestrator.toggleDictation()
    }
    Divider()
    Button("Quit") { NSApp.terminate(nil) }
}
```

#### Day 13-14: Basic Settings
Create minimal settings UI:
- Hotkey selection (default: Control+Option+D)
- Input device selection
- Simple test interface

**Deliverable**: Working dictation with menu bar control, text appears in basic UI

---

### Week 3: Text Insertion (Days 15-21)

#### Day 15-17: PasteInserter Only
Implement only the paste insertion strategy:
```swift
class PasteInserter {
    func insert(_ text: String) {
        // 1. Backup clipboard
        // 2. Set text to clipboard
        // 3. Send Cmd+V
        // 4. Restore clipboard
    }
}
```

#### Day 18-19: Basic Target App Support
Test and validate with primary targets:
- TextEdit (for testing)
- Notes (Apple's app)
- One more simple app

#### Day 20-21: Error Handling & Edge Cases
- Clipboard access failures
- Paste prevention (some apps block paste)
- Basic error messaging to user

**Deliverable**: Dictation inserts text into target applications

---

### Week 4: Polish & Testing (Days 22-28)

#### Day 22-24: UI Polish
- Improve menu bar interface
- Add basic onboarding (permission requests)
- Create simple settings window
- Add audio level indication

#### Day 25-26: Testing & Bug Fixes
- Manual testing across target apps
- Fix critical bugs
- Performance optimization for real-time response

#### Day 27-28: MVP Packaging
- Create basic documentation
- Package for distribution
- Prepare for user testing

**Deliverable**: MVP ready for user testing

---

### Week 5-6: Buffer for Refinement (Optional)

#### Performance Optimization
- Optimize audio pipeline latency
- Tune Whisper parameters for speed
- Reduce memory usage

#### User Feedback Integration
Based on initial testing:
- Fix critical usability issues
- Improve insertion reliability
- Add any essential missing features

#### Distribution Preparation
- Set up Apple Developer account
- Prepare for notarization
- Create distribution website/materials

---

## Accelerated Development Strategy

### Use Starter Code Liberally
The [`Starter Code.md`](Starter_Code.md) contains working implementations for most components. Adapt these rather than writing from scratch.

### Prioritize Proven Technologies
- **Whisper.cpp**: Already has Swift bridge examples
- **AVAudioEngine**: Well-documented audio API
- **SwiftUI**: Rapid UI development
- **Paste insertion**: Most reliable method

### Accept Technical Debt
For MVP, accept:
- Hardcoded values instead of configurable
- Basic error handling instead of comprehensive
- Simple UI instead of polished
- Single insertion mode instead of multiple

### Parallel Development
Work on multiple components simultaneously:
- Audio pipeline + Whisper integration
- Menu bar + basic UI
- Settings + onboarding
- Insertion system + testing

---

## MVP Technical Decisions

### Model Selection
**Use Whisper "tiny.en" for MVP**:
- ~40MB download vs 200MB for small.en
- 2x faster inference
- Good enough accuracy for MVP
- Easy upgrade path to small.en later

### Architecture Simplification
```swift
// MVP Architecture
MVPApp/
├── MVPApp.swift (main entry)
├── MenuBarView.swift (menu bar UI)
├── SettingsView.swift (basic settings)
└── Services/
    ├── DictationService.swift (orchestration)
    ├── AudioService.swift (audio capture)
    ├── WhisperService.swift (ASR)
    └── InsertionService.swift (paste only)
```

### Minimal Dependencies
Only essential external dependencies:
- whisper.cpp (compiled locally)
- System frameworks (AVFoundation, AppKit)

---

## MVP Success Criteria

### Core Functionality
- [ ] Push-to-talk works with hotkey (Control+Option+D)
- [ ] Real-time transcription appears within 2 seconds
- [ ] Text inserts into TextEdit, Notes, and VS Code
- [ ] Menu bar shows recording status
- [ ] Basic settings work (hotkey, input device)

### Performance Targets
- **First partial**: ≤2 seconds (vs 800ms target for full version)
- **Memory usage**: ≤300MB peak (vs 500MB target)
- **Model size**: ≤50MB download
- **App size**: ≤100MB total

### Quality Gates
- [ ] No crashes in normal usage
- [ ] Text insertion works 90% of the time
- [ ] Audio capture is clean and clear
- [ ] Settings persist between launches

---

## Post-MVP Enhancement Path

### Immediate (Weeks 7-8)
1. **Upgrade to Whisper "base.en" model**
2. **Add voice commands** (newline, tab, delete)
3. **Implement post-processing** (punctuation, capitalization)
4. **Add Settings UI** for post-processing options

### Short-term (Months 2-3)
1. **Add keystroke insertion mode** (fallback from paste)
2. **Implement per-app profiles**
3. **Add Apple Shortcuts integration**
4. **Upgrade to Whisper "small.en" model**

### Medium-term (Months 4-6)
1. **File transcription capabilities**
2. **Advanced voice command grammar**
3. **Model management and switching**
4. **Accessibility features**

---

## Risk Mitigation for MVP

### High Risk Items
1. **Whisper integration complexity**
   - Mitigation: Use starter code, test early and often
   - Fallback: CPU-only mode if Metal fails

2. **Audio pipeline reliability**
   - Mitigation: Simple implementation, robust error handling
   - Fallback: Restart audio if failures occur

3. **Text insertion failures**
   - Mitigation: Test thoroughly in target apps
   - Fallback: Show error to user, suggest manual copy/paste

### Medium Risk Items
1. **Permission handling**
   - Mitigation: Simple onboarding with clear instructions
   - Fallback: Manual permission setup instructions

2. **Performance issues**
   - Mitigation: Use tiny model, optimize where possible
   - Fallback: Reduce audio quality if needed

---

## MVP Development Kit

### Essential Files to Create
```
MVP/
├── MVPApp.swift (main app)
├── MenuBarView.swift (menu bar UI)
├── SettingsView.swift (settings)
├── Services/
│   ├── DictationService.swift
│   ├── AudioService.swift
│   ├── WhisperService.swift
│   └── InsertionService.swift
└── Resources/
    └── ggml-tiny.en-f16.bin
```

### Quick Start Script
```bash
#!/bin/bash
# mvp_quickstart.sh

echo "🚀 InlineWhisper MVP Quick Start"
echo "==============================="

# 1. Setup environment
./scripts/setup_mvp_environment.sh

# 2. Download tiny model
curl -L -o models/ggml-tiny.en-f16.bin https://example.com/tiny.en.ggml

# 3. Build whisper.cpp
./scripts/build_whisper.sh Release

# 4. Generate project
xcodegen generate --spec configs/mvp_project.yml

# 5. Open in Xcode
xed .

echo "✅ Ready for development! Start with AudioService.swift"
```

This MVP plan gets you to a working dictation app in 4-6 weeks by focusing on core functionality and leveraging existing code patterns. The streamlined approach prioritizes speed to market while maintaining quality and privacy standards.