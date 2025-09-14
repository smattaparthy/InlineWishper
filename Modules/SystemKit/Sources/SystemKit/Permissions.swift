import Foundation
import AVFoundation
import AppKit

public enum Permissions {
    public static func requestMicrophone() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    public static func checkMicrophoneAccess() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        return status == .authorized
    }
    
    public static func ensureMicrophone() {
        if !checkMicrophoneAccess() {
            AVAudioApplication.requestRecordPermission { _ in }
        }
    }
    
    public static func checkAccessibility() -> Bool {
        // Check if app has accessibility permissions
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    public static func requestAccessibility() async -> Bool {
        return await withCheckedContinuation { continuation in
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            let trusted = AXIsProcessTrustedWithOptions(options)
            continuation.resume(returning: trusted)
        }
    }
    
    public static func ensureAccessibilityPromptIfNeeded() {
        let trusted = AXIsProcessTrustedWithOptions(nil)
        if !trusted {
            print("Accessibility permission requested; user must approve in System Settings > Privacy & Security > Accessibility.")
        }
    }
}

public enum PermissionType {
    case microphone
    case accessibility
    
    public var description: String {
        switch self {
        case .microphone:
            return "Microphone access for audio capture"
        case .accessibility:
            return "Accessibility access for text insertion"
        }
    }
}