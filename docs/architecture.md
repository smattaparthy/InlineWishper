1) Architecture (finalized)

UI Layer (SwiftUI + AppKit)
Main window: Dictation, File Transcription, Models, Settings
Menu bar extra: State (idle/listening/transcribing), Start/Stop, device picker, last result
Onboarding wizard: Permissions, hotkey, quick test
Dictation Orchestrator
Hotkey Manager: global hold-to-talk and toggle modes
AudioCapture: AVAudioEngine, 16 kHz mono PCM feed
VAD: WebRTC VAD wrapper (configurable sensitivity)
ASR Engine: whisper.cpp (ggml) with Metal; streaming partials and finals
PostProcessor: rule-based punctuation/casing/fillers + optional tiny local polish pass
Insertion Engine: Pasteboard+Cmd+V, Keystroke (CGEvent), AX setValue; per-app presets; fallback cascade
File Transcription Pipeline
AVFoundation decode -> ASR batch -> Exporters (TXT/MD/SRT/VTT/JSON)
Model Manager
Bundled: Whisper small.en ggml f16 (copied to user space at first run)
Add/remove/select models (other ggml or CTranslate2), hash verification, metadata display
System Services
UNUserNotificationCenter local notifications
Settings & state (SQLite + file-based sessions)
Entitlements: sandbox on, mic + accessibility; no network
Data flow (dictation): Mic → AudioCapture → VAD (speech gating) → Whisper stream (partials/finals) → PostProcessor → Insertion buffer → Insertion strategy → Frontmost app
2) Key Component Designs

Hotkey Manager
Default Control+Option+D; conflict detector at onboarding
Modes: Hold-to-talk and Press-to-toggle
Event tap (CGEventTap) path for reliable global capture; requires Accessibility permission
Optional fallback: NSEvent global monitor (limited; used for local testing)
AudioCapture
AVAudioEngine input tap, 16-bit/32-bit float -> resample to 16 kHz mono Float32 using vDSP
Fixed-size frame chunks (20–30 ms) for VAD; larger window for ASR push (e.g., 320–640 ms)
VAD
WebRTC VAD with 10/20/30 ms frames; sensitivity levels 1–3
End-of-speech detection using trailing silence timeout (e.g., 300–500 ms) to close segments
Optional noise gate
WhisperBridge
Static library build of whisper.cpp with Metal enabled; ship ggml-metal.metal
Swift-friendly API for streaming:
load(modelURL)
beginStream(config, onPartial:, onFinal:)
feedAudio(samples)
endStream()
Config: threads, prompt/prefix tokens, beam/temperature, suppress_tokens, timestamps on/off
PostProcessor (Conservative polish default)
Rules:
Smart spacing and capitalization at sentence starts
Conservative punctuation inference (., ?, !, commas before conjunctions—rules are bounded)
Filler removal list (uh, um, like [optional], you know) with safeguards
Optional small local model pass (behind a toggle in Settings → Post-processing)
Runs only on final segments, never blocks partials stream
Disabled by default to minimize latency
Levels: Off, Minimal (punctuation/case), Conservative (default; + basic filler removal)
Insertion Engine
Strategies and cascade:
Default: Pasteboard + synthetic Cmd+V
Fallback 1: Keystroke typing (rate-limited, 100–140 cps configurable)
Fallback 2: AX value setting if available
Per-app profiles pick default strategy and pacing
Clipboard hygiene: preserve/restore user clipboard if replaced
Command grammar mapping (see below) evaluated on final chunks and optionally on partials for “press enter/tab” immediacy
3) Command Grammar (v1 scope)

Editing and navigation
“new line”, “new paragraph”, “press enter/return”
“tab”
“delete word”, “delete line” (guarded confirmation if destructive)
“undo last sentence” (guarded; optional)
“select previous word”, “select next word”
“move to line start/end”
Punctuation by name
“comma”, “period”, “question mark”, “exclamation mark”, “colon”, “semicolon”, “dash”
“open quote/close quote”, “open parenthesis/close parenthesis”
Safety and literal modes
“literal” mode toggle: say “literal start … literal end” to prevent command parsing
“escape” prefix (e.g., “type literally …”) forces text insertion of the phrase
Heuristics
Commands are recognized as standalone phrases separated by silence or explicit trigger (“command: …” optional)
Bias towards text if ambiguous; destructive commands require confirmation setting
4) Per-App Presets (v1 prioritized)

VS Code
Default: Paste; fallback Keystroke at 90–120 cps; “new line” → Return
Option: Always append trailing space after inserts off (code)
Convert smart quotes to straight quotes in code contexts (toggle)
Safari/Chrome
Default: Paste; fallback Keystroke
Contenteditable quirks: if paste blocked, switch to Keystroke automatically
For chat inputs (e.g., ChatGPT), enable “new line” → Shift+Return toggle
Notes
Default: Paste; AX is often available for value set
Smart quotes on; trailing newline allowed
Users can clone presets per app and customize.
5) Performance Budget and Tuning

Targets on M2 or later
First partial within 500–800 ms from speech onset
Faster than real-time overall for small.en f16
Tuning levers
VAD silence threshold and frame size
Streaming window size and partial cadence (e.g., emit every 300–500 ms)
Threads = number of performance cores by default
Optional quantized model import (Q5/Q6) for throughput at slight accuracy trade-off
Post-processing runs only on finals by default; partials are minimally touched
6) Models: Bundling, Import, “Download”

Bundled
Whisper small.en ggml f16 inside the app; copied to ~/Library/Application Support/AppName/Models on first run
Hash verified for integrity
Import
In-app “Add Model” to import local files (ggml, CTranslate2)
“Download” and no-network policy
Default build has no network entitlement; in-app “Get models…” opens a local help page with links for manual download and drag-in
Optional separate helper (signed, opt-in) could provide background downloads in a future variant; not part of v1 default
7) Permissions and Onboarding Copy

Microphone: “We capture your microphone audio on-device for dictation. Audio never leaves your Mac.”
Accessibility: “We need Accessibility access to deliver keystrokes and insert text into other apps. Data never leaves your Mac.”
Hotkey: default Control+Option+D; guide to rebind; conflict detector suggests alternatives
Quick Test: auto-launch TextEdit, insert-on-release demo
8) Storage, Privacy, and Telemetry

Storage
Sessions DB (SQLite) and transcript files under Application Support
Temp audio buffers purged on completion by default
Privacy
No networking code paths; no network entitlements
No telemetry; optional local debug logs (user toggle, easy purge)
9) CI/CD, Packaging, and Tooling

Build
Xcode workspace; SPM modules for all kits; Release and Debug configs
whisper.cpp compiled as static lib with Metal; include ggml-metal.metal
CI
GitHub Actions/macOS runners: build + unit tests + basic UI smoke
Scripts: entitlement audit (no com.apple.security.network.*), model hash check
Packaging
Signed and notarized .app; DMG with LICENSE/NOTICE and first-run README
“Check for Updates” opens Releases page (no background polling)
10) Code Scaffolding (initial)

Workspace layout
text


/app
/modules
  /DictationKit
  /TranscribeKit
  /ModelsKit
  /SystemKit
  /PostProcessKit
  /WhisperBridge   (C++ + bridging header + ggml-metal)
  /WebRTCVADWrapper
/resources
/models             (bundled small.en ggml f16)
/scripts
/configs            (plist, entitlements)
/tests
/docs
WhisperEngine protocol
text


public protocol WhisperEngine {
    func loadModel(at url: URL) throws
    func beginStream(config: ASRConfig,
                     onPartial: @escaping (String) -> Void,
                     onFinal:   @escaping (String) -> Void) throws
    func feed(samples: UnsafePointer<Float>, count: Int)
    func endStream()
}
Insertion strategy interface
text


enum InsertionStrategy { case paste, keystroke, accessibility }

protocol Inserter {
    func insert(_ text: String, preferred: InsertionStrategy, appProfile: AppProfile) throws
}
11) Sprint Plan (6–8 weeks to v1 RC)

Sprint 1: Pipeline Foundations (2 weeks)
WhisperBridge static lib with Metal; load small.en; console E2E transcription of mic
AVAudioEngine + VAD gating; partial/final callbacks
Global hotkey + OSD prototype (levels, states)
Insert-on-release via Paste mode; clipboard hygiene
Sprint 2: Insertion Robustness + Presets (2 weeks)
Keystroke insertion + rate limiter; AX insertion path
Strategy fallback cascade; per-app profiles (VS Code, Safari, Chrome, Notes)
Onboarding wizard (permissions + hotkey + quick test)
Model Manager UI (view/bundle/import/remove, hash check)
Sprint 3: Performance + Post-Processing (2 weeks)
Latency tuning, partial cadence, thread counts, Metal config
PostProcessor: Minimal and Conservative levels; toggles; tests
Shortcuts actions (Start/Stop Dictation, Transcribe Files, Copy/Insert Last)
Hardening & RC (1–2 weeks)
QA pass on target apps, accessibility checks, stress runs
Notarization pipeline, DMG packaging, docs/readme
v1.0 Release Candidate
12) Acceptance Criteria (v1)

Dictation latency: first partial ≤ 800 ms on M2+ with small.en f16; overall faster than real-time
Inline insertion succeeds in VS Code, Safari, Chrome, Notes via default strategy or fallback
Push-to-talk works (hold and toggle); OSD and tones reflect state; hotkey rebindable
Post-processing “Conservative” improves readability; Off/Minimal available
App runs fully offline; no network entitlements; bundled model loads at first run
Users can import quantized small.en and switch models in Settings
13) Risks & Mitigations

Paste blocked in some contexts
Auto-fallback to keystroke; per-app overrides; AX path when available
Accessibility permission friction
Onboarding with live validation and retry guidance
Latency variance across hardware
VAD tuning; partial cadence; user-selectable model sizes and quantized imports
“In-app download” vs no-network policy
Default build: import local files; “Get models” opens instructions page
Future optional helper for downloads (separate binary, opt-in)
