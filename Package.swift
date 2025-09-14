// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "InlineWhisperModules",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "DictationKit", targets: ["DictationKit"]),
        .library(name: "WhisperBridge", targets: ["WhisperBridge"]),
        .library(name: "SystemKit", targets: ["SystemKit"]),
    ],
    targets: [
        // Core dictation module (simplified for MVP)
        .target(
            name: "DictationKit",
            dependencies: ["WhisperBridge", "SystemKit"],
            path: "Modules/DictationKit/Sources"
        ),
        
        // Whisper.cpp integration (core to MVP)
        .target(
            name: "WhisperBridge",
            dependencies: [],
            path: "Modules/WhisperBridge/Sources",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
                .headerSearchPath("csrc"),
                .unsafeFlags(["-Wno-shorten-64-to-32"])
            ],
            linkerSettings: [
                .linkedLibrary("c++"),
                .linkedFramework("Metal"),
                .linkedFramework("Foundation")
            ]
        ),
        
        // System services (permissions, etc.)
        .target(
            name: "SystemKit",
            dependencies: [],
            path: "Modules/SystemKit/Sources",
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("AppKit"),
                .linkedFramework("UserNotifications")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
