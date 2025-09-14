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
