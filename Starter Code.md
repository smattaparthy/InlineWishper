1) Directory Layout

text


InlineWhisper/
├─ app/
│  ├─ InlineWhisperApp.swift
│  ├─ ContentView.swift
│  ├─ MenuBar/StatusMenu.swift
│  ├─ Onboarding/OnboardingView.swift
│  ├─ Assets.xcassets/
│  ├─ Sounds/ (start/stop tones)
│  ├─ Info.plist
│  └─ InlineWhisper.entitlements
├─ extensions/
│  └─ Intents/              (Apple Shortcuts AppIntents extension)
│     ├─ Intents.swift
│     ├─ Info.plist
│     └─ Extension.entitlements
├─ Modules/
│  ├─ DictationKit/
│  │  ├─ Sources/DictationKit/
│  │  │  ├─ DictationOrchestrator.swift
│  │  │  ├─ HotkeyManager.swift
│  │  │  ├─ AudioCaptureService.swift
│  │  │  ├─ VADService.swift
│  │  │  ├─ Insertion/
│  │  │  │  ├─ Inserter.swift
│  │  │  │  ├─ PasteInserter.swift
│  │  │  │  ├─ KeystrokeInserter.swift
│  │  │  │  └─ AccessibilityInserter.swift
│  │  │  ├─ Commands/CommandGrammar.swift
│  │  │  └─ PerAppProfiles.swift
│  │  └─ Tests/DictationKitTests/
│  ├─ WhisperBridge/
│  │  ├─ Sources/WhisperBridge/
│  │  │  ├─ WhisperEngine.swift
│  │  │  ├─ WhisperCPP.swift
│  │  │  ├─ include/WhisperBridge-Bridging-Header.h
│  │  │  └─ csrc/ (headers if needed)
│  │  └─ Tests/WhisperBridgeTests/
│  ├─ WebRTCVADWrapper/
│  │  ├─ Sources/WebRTCVADWrapper/
│  │  │  ├─ WebRTCVAD.h
│  │  │  ├─ WebRTCVAD.c
│  │  │  └─ VADServiceAdapter.swift
│  │  └─ Tests/WebRTCVADWrapperTests/
│  ├─ PostProcessKit/
│  │  ├─ Sources/PostProcessKit/
│  │  │  ├─ PostProcessor.swift
│  │  │  └─ Rules.swift
│  │  └─ Tests/PostProcessKitTests/
│  ├─ TranscribeKit/
│  │  ├─ Sources/TranscribeKit/
│  │  │  ├─ FileTranscriber.swift
│  │  │  ├─ Exporters/{TXTExporter,SRTExporter,VTTExporter,JSONExporter}.swift
│  │  │  └─ Models/{Transcript,Segment,Word}.swift
│  │  └─ Tests/TranscribeKitTests/
│  ├─ ModelsKit/
│  │  ├─ Sources/ModelsKit/
│  │  │  ├─ ModelManager.swift
│  │  │  └─ BundledModelProvider.swift
│  │  └─ Tests/ModelsKitTests/
│  └─ SystemKit/
│     ├─ Sources/SystemKit/
│     │  ├─ Permissions.swift
│     │  ├─ Notifications.swift
│     │  ├─ Settings.swift
│     │  └─ Logging.swift
│     └─ Tests/SystemKitTests/
├─ third_party/
│  ├─ whisper.cpp/         (git submodule)
│  └─ licenses/
├─ models/
│  ├─ README.md
│  └─ ggml-small.en-f16.bin   (bundled model file placed here; copied at first run)
├─ scripts/
│  ├─ build_whisper.sh
│  ├─ entitlement_audit.sh
│  ├─ package_dmg.sh
│  ├─ notarize.sh
│  └─ verify_model_hash.sh
├─ configs/
│  ├─ project.yml            (XcodeGen config)
│  ├─ AppInfo.plist
│  └─ ExtensionInfo.plist
├─ Package.swift             (SPM workspace for modules)
├─ Makefile
├─ docs/
│  ├─ BUILD.md
│  ├─ ARCHITECTURE.md
│  └─ CONTRIBUTING.md
├─ LICENSE
└─ NOTICE
2) Prerequisites

Xcode 16+ and Command Line Tools
Homebrew
brew install cmake xcodegen jq
Git LFS (optional if you store models in Git; otherwise ship models in releases)
Apple Developer ID for signing/notarization (for distribution)
3) Quickstart

Clone and init submodules:
text


git clone https://github.com/your-org/InlineWhisper.git
cd InlineWhisper
git submodule update --init --recursive
Build whisper.cpp static lib (Metal enabled):
text


./scripts/build_whisper.sh
Generate Xcode project:
text


xcodegen generate --spec ./configs/project.yml
Open and run:
text


xed .
Select the InlineWhisper scheme → Run. On first launch, grant Microphone and Accessibility permissions in onboarding.
Optional: entitlement audit before distribution:
text


./scripts/entitlement_audit.sh InlineWhisper.app
4) XcodeGen Project (configs/project.yml)

text


name: InlineWhisper
options:
  bundleIdPrefix: com.yourorg
  deploymentTarget:
    macOS: "15.0"
settings:
  BASE_SDK: macosx
  CODE_SIGN_STYLE: Automatic
  DEVELOPMENT_TEAM: ABCDE12345   # change to your team
  SWIFT_VERSION: 5.10
  ENABLE_HARDENED_RUNTIME: YES
packages:
  DictationKit:
    path: ../Modules/DictationKit
  WhisperBridge:
    path: ../Modules/WhisperBridge
  WebRTCVADWrapper:
    path: ../Modules/WebRTCVADWrapper
  PostProcessKit:
    path: ../Modules/PostProcessKit
  TranscribeKit:
    path: ../Modules/TranscribeKit
  ModelsKit:
    path: ../Modules/ModelsKit
  SystemKit:
    path: ../Modules/SystemKit
targets:
  InlineWhisper:
    type: application
    platform: macOS
    sources:
      - path: ../app
    settings:
      INFOPLIST_FILE: ../configs/AppInfo.plist
      CODE_SIGN_ENTITLEMENTS: ../app/InlineWhisper.entitlements
      OTHER_LDFLAGS: ["-lc++", "-ObjC"]
    dependencies:
      - package: DictationKit
      - package: WhisperBridge
      - package: WebRTCVADWrapper
      - package: PostProcessKit
      - package: TranscribeKit
      - package: ModelsKit
      - package: SystemKit
      - sdk: AVFoundation.framework
      - sdk: AppKit.framework
      - sdk: UserNotifications.framework
      - sdk: Accelerate.framework
    entitlements:
      com.apple.security.app-sandbox: true
      com.apple.security.device.microphone: true
  InlineWhisperIntents:
    type: app-extension
    platform: macOS
    sources:
      - path: ../extensions/Intents
    settings:
      INFOPLIST_FILE: ../configs/ExtensionInfo.plist
      CODE_SIGN_ENTITLEMENTS: ../extensions/Intents/Extension.entitlements
    dependencies:
      - target: InlineWhisper
5) Entitlements (app/InlineWhisper.entitlements)

text


<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>com.apple.security.app-sandbox</key><true/>
  <key>com.apple.security.device.microphone</key><true/>
  <!-- No network entitlements -->
  <!-- Accessibility is a TCC permission; no entitlement required -->
</dict></plist>
Extension entitlements can be minimal sandbox.
6) Info.plist (configs/AppInfo.plist)

text


<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist ...>
<plist version="1.0"><dict>
  <key>CFBundleDisplayName</key><string>InlineWhisper</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
  <key>NSMicrophoneUsageDescription</key><string>InlineWhisper requires microphone access to transcribe your speech on-device.</string>
  <key>NSAppleEventsUsageDescription</key><string>Used to insert text into other apps when needed. No data leaves your Mac.</string>
  <key>NSHumanReadableCopyright</key><string>© 2025 Your Org</string>
</dict></plist>
Note: Insertion via CGEvent/AX does not strictly require NSAppleEventsUsageDescription unless you send Apple Events; we include the key for clarity if you later add Apple Events.
7) Swift Package manifest (Package.swift)

text


import PackageDescription

let package = Package(
    name: "InlineWhisperModules",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "DictationKit", targets: ["DictationKit"]),
        .library(name: "WhisperBridge", targets: ["WhisperBridge"]),
        .library(name: "WebRTCVADWrapper", targets: ["WebRTCVADWrapper"]),
        .library(name: "PostProcessKit", targets: ["PostProcessKit"]),
        .library(name: "TranscribeKit", targets: ["TranscribeKit"]),
        .library(name: "ModelsKit", targets: ["ModelsKit"]),
        .library(name: "SystemKit", targets: ["SystemKit"]),
    ],
    targets: [
        .target(name: "DictationKit", dependencies: ["WhisperBridge", "WebRTCVADWrapper", "PostProcessKit", "ModelsKit", "SystemKit"]),
        .testTarget(name: "DictationKitTests", dependencies: ["DictationKit"]),
        .target(name: "WhisperBridge", dependencies: [], path: "Modules/WhisperBridge/Sources/WhisperBridge",
                publicHeadersPath: "include",
                cSettings: [.headerSearchPath("../../../../third_party/whisper.cpp/include")],
                linkerSettings: [.linkedLibrary("c++"), .linkedFramework("Metal")]),
        .testTarget(name: "WhisperBridgeTests", dependencies: ["WhisperBridge"]),
        .target(name: "WebRTCVADWrapper", dependencies: [], path: "Modules/WebRTCVADWrapper/Sources/WebRTCVADWrapper"),
        .testTarget(name: "WebRTCVADWrapperTests", dependencies: ["WebRTCVADWrapper"]),
        .target(name: "PostProcessKit"),
        .testTarget(name: "PostProcessKitTests", dependencies: ["PostProcessKit"]),
        .target(name: "TranscribeKit", dependencies: ["ModelsKit"]),
        .testTarget(name: "TranscribeKitTests", dependencies: ["TranscribeKit"]),
        .target(name: "ModelsKit"),
        .testTarget(name: "ModelsKitTests", dependencies: ["ModelsKit"]),
        .target(name: "SystemKit"),
        .testTarget(name: "SystemKitTests", dependencies: ["SystemKit"]),
    ]
)
Adjust header search paths if you locate whisper headers differently.
8) Scripts

scripts/build_whisper.sh
text


#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/third_party/whisper.cpp/build"
mkdir -p "$BUILD"
cd "$BUILD"
cmake -DCMAKE_BUILD_TYPE=Release \
      -DGGML_METAL=ON \
      -DWHISPER_COREML=OFF \
      -DWHISPER_METAL_EMBED_LIBRARY=ON \
      ..
cmake --build . --config Release
# Copy static lib and metal files for linking
mkdir -p "$ROOT/Modules/WhisperBridge/Sources/WhisperBridge/csrc"
cp libwhisper.a "$ROOT/Modules/WhisperBridge/Sources/WhisperBridge/csrc/"
cp -r ../ggml/src/ggml-metal.metal "$ROOT/Modules/WhisperBridge/Sources/WhisperBridge/csrc/" || true
echo "whisper.cpp built. Static lib at Modules/WhisperBridge/Sources/WhisperBridge/csrc/libwhisper.a"
scripts/entitlement_audit.sh
text


#!/usr/bin/env bash
set -euo pipefail
APP="$1"
echo "Entitlements for $APP"
codesign -d --entitlements :- "$APP"
echo "Linked frameworks:"
otool -L "$APP/Contents/MacOS/"* | sed 's/^/  /'
echo "Networking symbols (should be none):"
nm -um "$APP/Contents/MacOS/"* | egrep -i "CFNetwork|NSURLSession|NSURLConnection|getaddrinfo|CFStream" || echo "No obvious networking symbols."
scripts/verify_model_hash.sh
text


#!/usr/bin/env bash
set -euo pipefail
MODEL="models/ggml-small.en-f16.bin"
EXPECTED="<put-your-sha256-here>"
ACTUAL=$(shasum -a 256 "$MODEL" | awk '{print $1}')
if [[ "$ACTUAL" != "$EXPECTED" ]]; then
  echo "Hash mismatch! Expected $EXPECTED, got $ACTUAL"
  exit 1
fi
echo "Model hash OK."
scripts/package_dmg.sh and scripts/notarize.sh can be standard templates; fill your team ID and credentials.
9) Starter App Code

app/InlineWhisperApp.swift
text


import SwiftUI
import DictationKit
import SystemKit

@main
struct InlineWhisperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var orchestrator = DictationOrchestrator.shared

    var body: some Scene {
        MenuBarExtra("InlineWhisper", systemImage: orchestrator.menuBarIconName) {
            StatusMenu(orchestrator: orchestrator)
        }
        WindowGroup {
            ContentView()
                .environmentObject(orchestrator)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 980, height: 680)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Permissions.ensureMicrophone()
        Permissions.ensureAccessibilityPromptIfNeeded()
    }
}
app/MenuBar/StatusMenu.swift
text


import SwiftUI
import DictationKit

struct StatusMenu: View {
    @ObservedObject var orchestrator: DictationOrchestrator

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(orchestrator.stateDescription).font(.headline)
            Button(orchestrator.isListening ? "Stop Dictation" : "Start Dictation") {
                orchestrator.toggleDictation()
            }
            Divider()
            Picker("Input", selection: $orchestrator.selectedInputID) {
                ForEach(orchestrator.availableInputs, id: \.self) { id in
                    Text(id).tag(id)
                }
            }
            .pickerStyle(.menu)
            Divider()
            Button("Settings…") { orchestrator.openSettings() }
            Button("Quit") { NSApp.terminate(nil) }
        }.padding(10).frame(width: 260)
    }
}
app/ContentView.swift
text


import SwiftUI
import DictationKit

struct ContentView: View {
    @EnvironmentObject var orchestrator: DictationOrchestrator

    var body: some View {
        VStack(alignment: .leading) {
            Text("InlineWhisper").font(.largeTitle).bold()
            Text("Privacy-first on-device dictation & transcription").foregroundStyle(.secondary)
            Divider().padding(.vertical, 8)
            HStack {
                Button(orchestrator.isListening ? "Stop Dictation" : "Start Dictation") {
                    orchestrator.toggleDictation()
                }
                .keyboardShortcut("d", modifiers: [.control, .option])
                Text("Hotkey: Control+Option+D").font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
            TextEditor(text: .constant(orchestrator.debugPreview))
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 240)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            Spacer()
        }.padding()
    }
}
10) Dictation Core Stubs

Modules/DictationKit/Sources/DictationKit/DictationOrchestrator.swift
text


import Foundation
import Combine
import AVFoundation
import WebRTCVADWrapper
import WhisperBridge
import PostProcessKit

public final class DictationOrchestrator: ObservableObject {
    public static let shared = DictationOrchestrator()
    @Published public private(set) var isListening = false
    @Published public var selectedInputID: String = ""
    @Published public private(set) var availableInputs: [String] = []
    @Published public private(set) var stateDescription = "Idle"
    @Published public private(set) var menuBarIconName = "mic"
    @Published public private(set) var debugPreview = ""

    private let audio = AudioCaptureService()
    private let vad = VADService()
    private let engine: WhisperEngine = WhisperCPP.shared
    private let post = PostProcessor(level: .conservative)

    private var cancellables = Set<AnyCancellable>()

    private init() {
        availableInputs = audio.availableInputIDs()
        selectedInputID = audio.defaultInputID() ?? ""
        audio.onSamples = { [weak self] samples in self?.handleAudio(samples) }
        configureModel()
    }

    private func configureModel() {
        do {
            try engine.loadBundledSmallEN()
        } catch {
            print("Model load error: \(error)")
        }
    }

    public func toggleDictation() {
        isListening ? stop() : start()
    }

    public func start() {
        guard !isListening else { return }
        do {
            try audio.start(deviceID: selectedInputID)
            try engine.beginStream(config: .lowLatencyEnglish(),
                                   onPartial: { [weak self] text in
                                       DispatchQueue.main.async { self?.previewPartial(text) }
                                   },
                                   onFinal: { [weak self] text in
                                       DispatchQueue.main.async { self?.emitFinal(text) }
                                   })
            isListening = true
            stateDescription = "Listening…"
            menuBarIconName = "mic.fill"
        } catch {
            print("Start error: \(error)")
        }
    }

    public func stop() {
        audio.stop()
        engine.endStream()
        isListening = false
        stateDescription = "Idle"
        menuBarIconName = "mic"
    }

    private func handleAudio(_ samples: [Float]) {
        // Gate via VAD before feeding engine
        if vad.shouldAccept(samples: samples) {
            engine.feed(samples: samples, count: samples.count)
        }
    }

    private func previewPartial(_ text: String) {
        debugPreview = text
        // Optional: stream into frontmost app if streaming mode is enabled
    }

    private func emitFinal(_ text: String) {
        let polished = post.process(text)
        debugPreview = polished
        // Route to Inserter according to per-app strategy (paste/keystroke/AX)
        // Inserter.shared.insert(polished, preferred: .paste, appProfile: PerAppProfiles.detect())
    }

    public func openSettings() {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
}
Modules/DictationKit/Sources/DictationKit/AudioCaptureService.swift
text


import AVFoundation

final class AudioCaptureService {
    private let engine = AVAudioEngine()
    private let bus = 0
    var onSamples: (([Float]) -> Void)?

    func availableInputIDs() -> [String] {
        AVAudioSession.sharedInstance().availableInputs?.map { $0.uid } ?? []
    }

    func defaultInputID() -> String? {
        AVAudioSession.sharedInstance().preferredInput?.uid
    }

    func start(deviceID: String?) throws {
        let input = engine.inputNode
        let format = input.inputFormat(forBus: bus)
        let targetSampleRate: Double = 16000
        let frameSize: AVAudioFrameCount = 1024

        input.removeTap(onBus: bus)
        input.installTap(onBus: bus, bufferSize: frameSize, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let channelData = buffer.floatChannelData![0]
            let frames = Int(buffer.frameLength)
            var mono = [Float](repeating: 0, count: frames)
            // Assuming mono mic; if stereo, average channels
            for i in 0..<frames { mono[i] = channelData[i] }
            // Resample to 16 kHz if needed (use vDSP in production)
            self.onSamples?(mono)
        }
        try engine.start()
    }

    func stop() {
        engine.inputNode.removeTap(onBus: bus)
        engine.stop()
    }
}
Modules/WebRTCVADWrapper/Sources/WebRTCVADWrapper/VADServiceAdapter.swift
text


import Foundation

public final class VADService {
    private var enabled = true
    public init() {}
    public func shouldAccept(samples: [Float]) -> Bool {
        // TODO: Implement with WebRTC VAD frames (10/20/30 ms)
        return true
    }
}
Modules/WhisperBridge/Sources/WhisperBridge/WhisperEngine.swift
text


import Foundation

public struct ASRConfig {
    public var threads: Int = max(2, ProcessInfo.processInfo.activeProcessorCount - 2)
    public var temperature: Float = 0.0
    public var englishOnly: Bool = true
    public static func lowLatencyEnglish() -> ASRConfig { ASRConfig() }
}

public protocol WhisperEngine {
    func loadBundledSmallEN() throws
    func beginStream(config: ASRConfig,
                     onPartial: @escaping (String) -> Void,
                     onFinal:   @escaping (String) -> Void) throws
    func feed(samples: UnsafePointer<Float>, count: Int)
    func endStream()
}
Modules/WhisperBridge/Sources/WhisperBridge/WhisperCPP.swift
text


import Foundation

public final class WhisperCPP: WhisperEngine {
    public static let shared = WhisperCPP()
    private var onPartial: ((String) -> Void)?
    private var onFinal: ((String) -> Void)?

    private init() {}

    public func loadBundledSmallEN() throws {
        // Copy from app bundle to Application Support on first launch (ModelsKit can handle).
        // Then pass the file URL to whisper_init_from_file.
    }

    public func beginStream(config: ASRConfig,
                            onPartial: @escaping (String) -> Void,
                            onFinal:   @escaping (String) -> Void) throws {
        self.onPartial = onPartial
        self.onFinal = onFinal
        // Initialize whisper context, set decode params for streaming
    }

    public func feed(samples: UnsafePointer<Float>, count: Int) {
        // Push audio to whisper.cpp streaming API; emit partials via callback
    }

    public func endStream() {
        // Flush, produce final result, teardown
    }
}
Modules/WhisperBridge/Sources/WhisperBridge/include/WhisperBridge-Bridging-Header.h
text


// Bridge whisper.cpp APIs:
// #include "whisper.h"
Modules/PostProcessKit/Sources/PostProcessKit/PostProcessor.swift
text


import Foundation

public enum PostLevel { case off, minimal, conservative }

public final class PostProcessor {
    private let level: PostLevel
    public init(level: PostLevel) { self.level = level }
    public func process(_ text: String) -> String {
        switch level {
        case .off: return text
        case .minimal: return Rules.applyPunctuationAndCase(text)
        case .conservative:
            return Rules.removeFillers(Rules.applyPunctuationAndCase(text))
        }
    }
}
Modules/PostProcessKit/Sources/PostProcessKit/Rules.swift
text


import Foundation

enum Rules {
    static func applyPunctuationAndCase(_ text: String) -> String {
        // Minimal viable rule set: capitalize sentence starts, add final period if missing.
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return trimmed }
        var s = trimmed.prefix(1).uppercased() + trimmed.dropFirst()
        if !s.hasSuffix(".") && !s.hasSuffix("?") && !s.hasSuffix("!") {
            s += "."
        }
        return s
    }

    static func removeFillers(_ text: String) -> String {
        // Conservative removal of common fillers when standalone
        let fillers = [" uh ", " um ", " you know ", " like "]
        var s = " " + text + " "
        for f in fillers { s = s.replacingOccurrences(of: f, with: " ") }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
Modules/DictationKit/Sources/DictationKit/Insertion/PasteInserter.swift
text


import AppKit

public final class PasteInserter {
    public static let shared = PasteInserter()
    private init() {}
    public func insert(_ text: String) {
        let pb = NSPasteboard.general
        let old = pb.string(forType: .string)
        pb.clearContents()
        pb.setString(text, forType: .string)
        // Cmd+V
        postKeyCombo(key: 9, flags: .maskCommand) // kVK_ANSI_V = 9
        // Restore clipboard
        if let old { pb.clearContents(); pb.setString(old, forType: .string) }
    }
    private func postKeyCombo(key: CGKeyCode, flags: CGEventFlags) {
        let down = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: true)
        down?.flags = flags
        down?.post(tap: .cghidEventTap)
        let up = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: false)
        up?.flags = flags
        up?.post(tap: .cghidEventTap)
    }
}
Modules/SystemKit/Sources/SystemKit/Permissions.swift
text


import AppKit
import AVFoundation

public enum Permissions {
    public static func ensureMicrophone() {
        AVAudioApplication.requestRecordPermission { _ in }
    }
    public static func ensureAccessibilityPromptIfNeeded() {
        let trusted = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary)
        if !trusted {
            print("Accessibility permission requested; user must approve in System Settings > Privacy & Security > Accessibility.")
        }
    }
}
11) Models

Place ggml-small.en-f16.bin in models/. At first launch, copy it to:
~/Library/Application Support/InlineWhisper/Models/ggml-small.en-f16.bin
Provide SHA256 in scripts/verify_model_hash.sh.
ModelsKit/BundledModelProvider.swift handles the copy-on-first-run pattern and returns file URLs to WhisperBridge.
12) Hotkey

Default: Control+Option+D mapped via an event tap in HotkeyManager.swift (use CGEventTap and key code detection).
Onboarding should allow rebind and test. Ensure you gate with Accessibility permission.
13) Apple Shortcuts (extensions/Intents/Intents.swift)

text


import AppIntents
import DictationKit

struct StartDictationIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Dictation"
    func perform() async throws -> some IntentResult {
        await MainActor.run { DictationOrchestrator.shared.start() }
        return .result()
    }
}

struct StopDictationIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Dictation"
    func perform() async throws -> some IntentResult {
        await MainActor.run { DictationOrchestrator.shared.stop() }
        return .result()
    }
}
Add additional intents for file transcription and copy/insert last transcript.
14) Makefile

text


APP=InlineWhisper

.PHONY: bootstrap build run test package audit

bootstrap:
\tgit submodule update --init --recursive
\tbrew bundle || true
\t./scripts/build_whisper.sh
\txcodegen generate --spec ./configs/project.yml

build:
\txcodebuild -project $(APP).xcodeproj -scheme $(APP) -configuration Debug -destination 'platform=macOS' build

run:
\txed .

test:
\txcodebuild -project $(APP).xcodeproj -scheme InlineWhisperModules-Package -destination 'platform=macOS' test

package:
\t./scripts/package_dmg.sh

audit:
\t./scripts/entitlement_audit.sh build/Release/$(APP).app
Optionally add a Brewfile for cmake, xcodegen, jq.
15) BUILD.md (docs/BUILD.md)

Prereqs
Clone + submodules
./scripts/build_whisper.sh
xcodegen generate → xed .
Grant permissions in onboarding
Model integrity check with ./scripts/verify_model_hash.sh
No-network guarantee and entitlement audit
16) Code Quality & Best Practices

Strict module boundaries: UI doesn’t touch whisper APIs directly; it goes via DictationOrchestrator and WhisperEngine protocol.
Testability: WhisperEngine has a mock implementation; VADService can be mocked for unit tests.
Concurrency: Use Swift concurrency or dedicated queues; never block audio callback threads.
Accessibility: Full labels; keyboard ops; VoiceOver friendly controls.
No-network: No URLSession/CFNetwork; entitlement audits in CI.
Signing/Hardening: Hardened runtime on; sandbox on; only microphone entitlement.
Licensing: Apache-2.0 for the app; third-party NOTICE file; permissive-only deps.
17) Next Steps Checklist

Fill your Team ID in project.yml.
Drop the small.en model into models/ and add its SHA256 to verify script.
Implement real VAD frames in WebRTCVADWrapper (add BSD-licensed WebRTC VAD C files if not present).
Wire WhisperBridge to call into whisper.cpp (include whisper.h, link libwhisper.a, call init/stream/feed/end APIs).
Implement per-app insertion profiles and fallback cascade (Paste → Keystroke → AX).
Build onboarding UI (mic + accessibility) and hotkey capture UI.
Add Apple Shortcuts intents for transcribe files and insert/copy last transcript.
Start Sprint 1: end-to-end mic → partials → insert-on-release into TextEdit.
18) Optional Enhancements (ready for later)

Quantized model import UX (Q5/Q6 display) and quick switch.
Streaming insertion toggle and cadence tuning UI.
Post-processing “Minimal/Conservative” sliders with preview.
CLI tool (offline) for scripting: inlinewhisper dictation --start/--stop, inlinewhisper transcribe file.m4a.