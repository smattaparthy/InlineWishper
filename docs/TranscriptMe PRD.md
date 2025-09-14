PRD: Open‑Source macOS Dictation & Transcription App (On‑Device, Privacy‑First)

Date: Sunday, September 14, 2025 UTC
License: Apache‑2.0
Platforms: macOS 15 Sequoia and macOS 26 “Tahoe” (forward‑compatible), Apple Silicon (M‑series) only
1) Summary

Build a native macOS app for fast, privacy‑first dictation and offline transcription. The app runs entirely on‑device, ships with Whisper “small.en” pre‑converted for the chosen local runtime, and inserts polished text inline into the frontmost app (VS Code, Safari/Chrome, Notes, etc.) via push‑to‑talk. No cloud calls, no telemetry. Whisper is open‑source from OpenAI and suitable for local transcription. For high‑performance Apple Silicon inference, we will use a local runtime (primary: whisper.cpp/ggml with Metal; alternative import path: CTranslate2/faster‑whisper format).
2) Goals and Non‑Goals

Goals
100% on‑device ASR with Whisper “small.en” bundled; user can add/switch Whisper models in‑app. Default = small.en.
Real‑time or faster dictation on M2+ with small.en (full‑precision default).
Push‑to‑talk: hold‑to‑talk and press‑to‑toggle modes.
Insert text inline into frontmost app with robust fallbacks (Pasteboard, keystroke, Accessibility).
Basic voice command grammar in v1 (newline, tab, delete, undo, select, etc.).
Local post‑processing in v1: punctuation cleanup, filler removal, light sentence polishing.
Native macOS tech: Swift/SwiftUI, AVFoundation, Metal/Core ML where viable, UNUserNotificationCenter, Apple Shortcuts.
Menu bar extra + full windowed app.
Direct download distribution (signed & notarized).
Apache‑2.0 licensing, permissive deps only.
Non‑Goals (v1)
No cloud calls, accounts, or telemetry.
No encryption at rest by default (can be added later).
English only in v1; multilingual in a later release.
No automatic speaker diarization in v1.
3) Primary Use Cases

Hold hotkey, speak, release: app inserts transcribed (and lightly polished) text into the focused app field/editor.
Toggle for longer dictations with streaming insertion.
Batch‑transcribe local media files and export captions/subtitles.
Use Apple Shortcuts to trigger dictation or batch transcription in automations.
4) Target Apps to Optimize

VS Code (Electron)
Safari and Chrome (browsers)
Apple Notes
Dedicated presets and insertion strategy testing for these apps in v1.
5) Functional Requirements

5.1 Input Sources
Live microphone capture (selectable device, input level meter).
Import audio/video files: WAV, MP3, M4A/AAC, AIFF, MP4/MOV via AVFoundation.
Optional folder watch (user‑granted directory via security‑scoped bookmark).
5.2 Push‑to‑Talk Dictation
Global hotkey, two modes:
Hold‑to‑talk: listen while held; on release, insert.
Press‑to‑toggle: tap to start/stop.
On‑screen overlay (OSD): input level, Listening/Transcribing state, elapsed time.
Start/stop tones; visual cues; configurable.
5.3 Inline Text Insertion
Strategies (auto‑fallback, per‑app override):
Paste mode: write to NSPasteboard and synthesize Cmd+V (fast for bulk).
Keystroke mode: synthesize characters with CGEvent (for apps that block paste).
Accessibility mode: AX API to set text value when supported.
Per‑app presets (VS Code, Safari/Chrome, Notes):
Preferred strategy, pacing (keystroke rate limit), special handling for code blocks/forms.
Command grammar (v1 “basic commands”):
“new line/new paragraph”, “tab”, “press enter/return”, “delete word/line”, “undo last sentence”, “select previous/next word”, “move to line start/end”, “insert comma/period/colon/…”.
Smart spacing and capitalization toggles; auto‑insert trailing space/newline option.
5.4 ASR Engine & Models
Bundled model: Whisper “small.en” pre‑converted for local runtime format (primary: ggml f16 for whisper.cpp; option to add quantized variants; user can install other sizes/models). Whisper is open‑source and widely used locally; CTranslate2 conversions exist for small model imports.
Real‑time streaming decoding with VAD‑gated chunking for low latency.
Configurable decoding/search params with sane defaults for dictation.
Segment timestamps; optional word‑level timestamps for file jobs.
5.5 Local Post‑Processing (v1)
All on‑device; latency‑aware, disable‑able.
Punctuation and casing normalization.
Filler removal (e.g., “uh”, “um”) with conservative rules.
Light sentence polishing (grammar tidying without semantic rewrites).
Implementation path: lightweight rule‑based + small local model pass; user can switch “ASR‑only” for minimal latency.
5.6 File Transcription (Secondary)
Batch queue with per‑job settings.
Exports: TXT, Markdown, SRT, VTT, JSON (segments/words + timestamps).
Batch export and presets.
5.7 Notifications and Feedback
Local notifications for job completion/errors (no remote).
Menu bar status: idle/listening/transcribing; last result popover.
5.8 Apple Shortcuts & Automation
Actions:
Start Dictation (with preset)
Stop Dictation
Transcribe Files (with preset)
Copy/Insert Last Transcript
Optional minimal CLI wrapper (offline) for advanced automation.
5.9 Settings
Dictation: hotkey, mode, insertion defaults, command mapping editor.
Audio: input device, noise suppression, VAD sensitivity.
Models: manage installed Whisper models; default = small.en.
Performance: threads, GPU/Metal toggle, power/thermal policy.
Privacy: no‑network mode (enforced), retention controls for temp audio/text.
File handling: copy‑in vs reference, default export folder.
5.10 Accessibility & i18n
Full VoiceOver labels, keyboard navigation.
English UI in v1; i18n‑ready.
6) Non‑Functional Requirements

Privacy & Security
App Sandbox enabled; no network entitlement in default build.
Microphone and Accessibility permissions with clear onboarding.
No telemetry; optional local debug logs (user‑toggled, easy delete).
Performance
Target: real‑time or faster on M2+ with Whisper small.en (full‑precision default).
First visible partial ≈ 500–800 ms after speech onset (tunable via VAD/partial cadence).
Metal‑accelerated path preferred; CPU fallback available. whisper.cpp provides a portable, on‑device path for Apple Silicon.
Reliability
Robust hotkey handling; conflict detection and guidance.
Graceful fallback among insertion strategies; per‑app overrides.
Crash‑safe state and job recovery.
Offline
Fully functional offline at first launch (bundled model).
User can import additional models locally (ggml or CTranslate2).
Power
Battery‑aware throttling; “Full speed when plugged in” option.
7) Technical Architecture

7.1 Stack
Swift + SwiftUI (primary UI); AppKit for menu bar and advanced controls.
AVFoundation/AVAudioEngine for capture and decode.
Combine/Swift Concurrency for streaming and cancellation.
UNUserNotificationCenter for local notifications.
SQLite (or lightweight file DB) for sessions/projects.
7.2 ASR Runtime
Primary backend: whisper.cpp (ggml) with Metal acceleration on Apple Silicon; proven on‑device, C/C++ port of Whisper.
Bundled model: small.en in ggml f16. Optional quantized models (e.g., Q5) as user‑selectable for speed/size trade‑offs.
Alternative import path: accept CTranslate2 “faster‑whisper” models, including small model conversions.
7.3 VAD & Preprocessing
WebRTC VAD (permissive license) for endpoints; configurable sensitivity.
Accelerate/vDSP for resampling and basic DSP.
7.4 Post‑Processing Engine
Two‑stage:
Deterministic rules: punctuation, spacing, common fillers.
Optional local “polish” model pass with very small promptable model; can be disabled for lowest latency.
7.5 Dictation & Insertion Pipeline
Hotkey manager:
Default proposed: Control+Option+Space (conflict check at onboarding; prompt to rebind if used by Input Sources).
Support double‑tap variants if desired.
Audio -> VAD -> streaming ASR -> optional polishing -> insertion buffer.
Insertion strategies:
Pasteboard + Cmd+V (default), Keystroke typing with rate control, AX‑set value where available.
Per‑app profile selection and fallback cascade.
7.6 Permissions
NSMicrophoneUsageDescription.
Accessibility (AXIsProcessTrusted) for keystroke and AX insertion.
No network entitlement in provisioning profile.
7.7 Data & Storage
Project/session structure on disk.
Temp audio buffers auto‑deleted per retention setting.
Model directory with metadata and integrity checks (hash).
8) UX Outline

Menu Bar Extra
Status indicator: idle/listening/transcribing.
Start/Stop, device selector, last transcript preview/copy.
Quick toggle for insertion strategy and post‑processing.
Main Window
Home: Start Dictation, Transcribe Files, recent sessions.
Dictation view: live waveform, partial/final text, command feedback, per‑app preset indicator.
Editor: media player + transcript with timestamps; search, split/merge segments.
Models: Manage models, set default, show size/perf tips.
Settings: Dictation, Commands, Insertion, Models, Performance, Privacy, Automation.
Onboarding
Grant mic + accessibility.
Hotkey selection with conflict detector.
Quick test into TextEdit.
9) Distribution & Updates

Direct download (DMG/ZIP), signed and notarized.
No auto‑update service by default; “Check for Updates” opens releases page.
Optional separate, opt‑in updater can be offered later with clear disclosure.
10) Licensing & Third‑Party Policy

App: Apache‑2.0.
Dependencies: MIT/BSD/Apache only.
Avoid GPL/LGPL in default bundle (use AVFoundation for decode; optionally let user point to their own ffmpeg).
Whisper models: OpenAI Whisper is open‑source; confirm redistribution terms for bundled small.en weights and converted formats. Guidance for users to import other models (ggml or CTranslate2).
11) QA & Test Plan

Unit Tests
VAD gating and end‑of‑speech detection.
Streaming buffer management; partial cadence control.
Command grammar parser; insertion formatter.
Export formatting (TXT/SRT/VTT/JSON).
Integration Tests
End‑to‑end dictation into VS Code, Notes, Safari, Chrome.
Strategy fallbacks (Paste -> Keystroke -> AX).
Live streaming vs insert‑on‑release modes.
Model switching and performance sanity.
Performance Tests
Latency and throughput on M2/M3 with small.en (f16 vs quantized).
Thermal stability in 30‑minute sessions.
Accessibility Tests
VoiceOver labels; keyboard‑only control.
Privacy Tests
Entitlement audit (no network).
Static scan for networking APIs.
Permission prompts clarity.
12) Roadmap & Milestones

Milestone 0: Spec Lock (1–2 weeks)
Confirm bundled model format (ggml f16 small.en), post‑processing defaults, hotkey default.
Milestone 1: Dictation Core (4–6 weeks)
Hotkey + mic capture + VAD + streaming Whisper (whisper.cpp).
Insert‑on‑release via Paste mode; menu bar + OSD.
Bundle small.en (ggml f16); model manager (view/remove/add).
Milestone 2: Insertion & Apps (3–4 weeks)
Per‑app presets for VS Code, Safari/Chrome, Notes.
Keystroke and AX insertion; fallback logic; rate control.
Basic command grammar end‑to‑end.
Milestone 3: Performance & Post‑Processing (3–4 weeks)
Metal tuning; partials cadence; latency targets.
Punctuation/fillers cleanup and light polish; toggleable.
Milestone 4: File Transcription & Exports (3–4 weeks)
Batch queue; TXT/SRT/VTT/JSON exports; editor for corrections.
Milestone 5: Automation & Release (2–3 weeks)
Apple Shortcuts actions; optional minimal CLI.
Accessibility polish; signing/notarization; docs and v1.0 release.
Post‑v1: Multilingual models, richer command grammar, wake‑word, advanced polishing presets, diarization (local).
13) Acceptance Criteria (v1)

Dictation produces visible partials within ~800 ms on M2+ with small.en; stable <1.0x real‑time end‑to‑end.
Inline insertion works in VS Code, Safari, Chrome, and Notes using at least one strategy; automatic fallback covers failure cases.
Hotkey supports hold‑to‑talk and press‑to‑toggle with user‑configurable binding and conflict detection.
Post‑processing improves readability without adding hallucinated content; can be disabled.
App runs fully offline; no network entitlement present.
Bundled Whisper small.en loads at first launch; user can add/select other Whisper models.
14) Implementation Notes

Runtime choice
Primary: whisper.cpp (ggml) with Metal for Apple Silicon; battle‑tested local inference path.
Import: CTranslate2 (faster‑whisper) models supported in model manager.
Model size/perf guidance
Default small.en for accuracy/speed balance; allow users to add base/tiny for lower latency or medium for higher accuracy.
Command grammar
Simple phrase recognizer maps to edit actions and punctuation. Guardrails to avoid accidental destructive actions (e.g., require confirmation phrase for “delete line”).
