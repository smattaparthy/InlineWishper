import Foundation
import AppKit
import SystemKit
import UserNotifications

public final class InsertionService {
    public static let shared = InsertionService()
    
    private let pasteboard = NSPasteboard.general
    private var isInserting = false
    
    private init() {}
    
    public func insert(_ text: String) {
        guard !text.isEmpty, !isInserting else { return }
        
        isInserting = true
        Logger.shared.info("Inserting text: \"\(text)\"")
        
        do {
            try performRealInsertion(text)
            Logger.shared.info("Text insertion completed successfully")
        } catch {
            Logger.shared.error("Text insertion failed: \(error)")
            showInsertionError(text, error: error)
        }
        
        isInserting = false
    }
    
    private func performRealInsertion(_ text: String) throws {
        // Step 1: Backup current clipboard content
        let originalDataTypes = pasteboard.types ?? []
        var originalData: [NSPasteboard.PasteboardType: Data] = [:]
        
        for type in originalDataTypes {
            if let data = pasteboard.data(forType: type) {
                originalData[type] = data
            }
        }
        
        // Step 2: Clear clipboard and set new text
        pasteboard.clearContents()
        let textSetSuccessfully = pasteboard.setString(text, forType: .string)
        
        guard textSetSuccessfully else {
            throw InsertionError.clipboardAccessFailed
        }
        
        // Small delay to ensure clipboard is updated
        Thread.sleep(forTimeInterval: 0.05)
        
        // Step 3: Send Cmd+V keystroke to paste
        try sendPasteCommand()
        
        // Step 4: Restore original clipboard content after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.restoreOriginalClipboard(originalData)
        }
    }
    
    private func sendPasteCommand() throws {
        // Create event source
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            throw InsertionEventError.eventSourceCreationFailed
        }
        
        // Create V key down event
        guard let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) else {
            throw InsertionEventError.eventCreationFailed
        }
        
        // Create V key up event
        guard let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            throw InsertionEventError.eventCreationFailed
        }
        
        // Set command modifier
        vDown.flags = .maskCommand
        vUp.flags = .maskCommand
        
        // Post events
        vDown.post(tap: .cghidEventTap)
        vUp.post(tap: .cghidEventTap)
        
        // Small delay to allow paste to complete
        Thread.sleep(forTimeInterval: 0.05)
    }
    
    private func restoreOriginalClipboard(_ originalData: [NSPasteboard.PasteboardType: Data]) {
        // Only restore if we're not currently inserting
        guard !isInserting else { return }
        
        pasteboard.clearContents()
        
        for (type, data) in originalData {
            pasteboard.setData(data, forType: type)
        }
        
        Logger.shared.debug("Original clipboard content restored")
    }
    
    private func showInsertionError(_ text: String, error: Error) {
        // Show notification to user using modern UserNotifications
        showNotification(title: "InlineWhisper",
                          body: "Could not insert text. It has been copied to your clipboard instead.")
        
        // Fallback: just copy to clipboard
        fallbackToClipboard(text)
    }
    
    private func fallbackToClipboard(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        Logger.shared.info("Text copied to clipboard as fallback")
    }
    
    // MARK: - Legacy Simulation (for testing)
    
    private func simulateInsertion(_ text: String) {
        // Simulate the insertion process for testing
        print("📝 SIMULATED: Inserting text into frontmost application")
        print("📝 Text to insert: \"\(text)\"")
        
        // Show a notification instead of actual insertion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showInsertionNotification(text)
        }
    }
    
    private func showInsertionNotification(_ text: String) {
        // For testing, just print the action
        print("📝 SIMULATED: Would insert text:")
        print("📝 \"\(text)\"")
        print("📝 Insertion simulation complete")
    }
    
    private func showNotification(title: String, body: String) {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = nil
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "inline-whisper-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        // Add to notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
}

// MARK: - Error Types

public enum InsertionError: Error, LocalizedError {
    case clipboardAccessFailed
    case pasteCommandFailed
    case accessibilityPermissionDenied
    
    public var errorDescription: String? {
        switch self {
        case .clipboardAccessFailed:
            return "Could not access the clipboard"
        case .pasteCommandFailed:
            return "Could not send paste command to the application"
        case .accessibilityPermissionDenied:
            return "Accessibility permission is required for text insertion"
        }
    }
}

public enum InsertionEventError: Error, LocalizedError {
    case eventSourceCreationFailed
    case eventCreationFailed
    case eventPostingFailed
    
    public var errorDescription: String? {
        switch self {
        case .eventSourceCreationFailed:
            return "Could not create event source for keyboard simulation"
        case .eventCreationFailed:
            return "Could not create keyboard events"
        case .eventPostingFailed:
            return "Could not post keyboard events"
        }
    }
}

// MARK: - Testing Extension

extension InsertionService {
    public func enableSimulationMode() {
        // For testing purposes only
        Logger.shared.warning("InsertionService running in simulation mode")
    }
}