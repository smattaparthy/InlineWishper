import SwiftUI
import DictationKit
import SystemKit

@main
struct InlineWhisperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var dictationService = DictationService.shared
    @State private var showingOnboarding = false
    @State private var showingSettings = false
    
    var body: some Scene {
        MenuBarExtra("InlineWhisper", systemImage: dictationService.isListening ? "mic.fill" : "mic") {
            MenuBarView()
                .environmentObject(dictationService)
                .sheet(isPresented: $showingOnboarding) {
                    OnboardingView()
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
        }
        .menuBarExtraStyle(.window)
        
        WindowGroup {
            ContentView()
                .environmentObject(dictationService)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 600, height: 400)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About InlineWhisper") {
                    NSApp.orderFrontStandardAboutPanel()
                }
            }
            
            CommandGroup(after: .appInfo) {
                Divider()
                Button("Settings...") {
                    showingSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        "InlineWhisper starting up".logInfo()
        
        // Request permissions
        Permissions.ensureMicrophone()
        Permissions.ensureAccessibilityPromptIfNeeded()
        
        // Initialize Whisper
        Task {
            do {
                try WhisperCPP.shared.loadBundledTinyEN()
                "Whisper model initialized".logInfo()
            } catch {
                "Failed to initialize Whisper model: \(error)".logError()
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        DictationService.shared.stopDictation()
        "InlineWhisper shutting down".logInfo()
    }
}