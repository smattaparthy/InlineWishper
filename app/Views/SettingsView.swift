import SwiftUI
import SystemKit
import DictationKit

struct SettingsView: View {
    @AppStorage("hotkeyModifiers") private var hotkeyModifiers: Int = Int(NSEvent.ModifierFlags.option.rawValue | NSEvent.ModifierFlags.control.rawValue)
    @AppStorage("hotkeyKeyCode") private var hotkeyKeyCode: UInt16 = 2 // "D" key
    @AppStorage("selectedInputDevice") private var selectedInputDevice: String = "Default"
    @AppStorage("enableSoundEffects") private var enableSoundEffects: Bool = true
    @AppStorage("autoStartDictation") private var autoStartDictation: Bool = false
    @AppStorage("enableInsertNotification") private var enableInsertNotification: Bool = true
    
    @State private var showingHotkeyRecorder = false
    @State private var availableInputDevices: [String] = []
    @State private var isRecording = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink {
                        GeneralSettingsView()
                    } label: {
                        Label("General", systemImage: "gear")
                    }
                    
                    NavigationLink {
                        HotkeySettingsView()
                    } label: {
                        Label("Hotkeys", systemImage: "keyboard")
                    }
                    
                    NavigationLink {
                        AudioSettingsView()
                    } label: {
                        Label("Audio", systemImage: "mic")
                    }
                    
                    NavigationLink {
                        AdvancedSettingsView()
                    } label: {
                        Label("Advanced", systemImage: "slider.horizontal.3")
                    }
                    
                    NavigationLink {
                        PrivacySettingsView()
                    } label: {
                        Label("Privacy", systemImage: "hand.raised")
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            
            // Default content when nothing is selected
            VStack(spacing: 20) {
                Image(systemName: "gear")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                Text("Select a settings category")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Choose a category from the sidebar to configure InlineWhisper settings")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 800, height: 600)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("enableSoundEffects") private var enableSoundEffects: Bool = true
    @AppStorage("autoStartDictation") private var autoStartDictation: Bool = false
    @AppStorage("enableInsertNotification") private var enableInsertNotification: Bool = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Sound Effects", isOn: $enableSoundEffects)
                    .help("Play sounds when dictation starts/stops")
                
                Toggle("Show Insertion Notifications", isOn: $enableInsertNotification)
                    .help("Show notification when text is inserted into applications")
                
                Toggle("Auto-start Dictation", isOn: $autoStartDictation)
                    .help("Automatically start dictation when app launches")
            }
            
            Section {
                Button("Reset All Settings") {
                    resetSettings()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("General")
        .padding()
    }
    
    private func resetSettings() {
        // Reset general settings to defaults
        enableSoundEffects = true
        autoStartDictation = false
        enableInsertNotification = true
    }
}

struct HotkeySettingsView: View {
    @AppStorage("hotkeyModifiers") private var hotkeyModifiers: Int = Int(NSEvent.ModifierFlags.option.rawValue | NSEvent.ModifierFlags.control.rawValue)
    @AppStorage("hotkeyKeyCode") private var hotkeyKeyCode: UInt16 = 2 // "D" key
    
    @State private var showingHotkeyRecorder = false
    @State private var currentHotkeyString: String = ""
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Start/Stop Dictation:")
                    Spacer()
                    Text(currentHotkeyString)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Button(showingHotkeyRecorder ? "Recording..." : "Change") {
                        showingHotkeyRecorder.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(showingHotkeyRecorder)
                }
                
                if showingHotkeyRecorder {
                    HotkeyRecorderView(isRecording: $showingHotkeyRecorder, modifiers: $hotkeyModifiers, keyCode: $hotkeyKeyCode)
                }
            }
            
            Section {
                Text("The hotkey works system-wide, even when InlineWhisper is not the frontmost application.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Hotkeys")
        .padding()
        .onAppear {
            updateHotkeyString()
        }
        .onChange(of: hotkeyModifiers) { _ in
            updateHotkeyString()
        }
        .onChange(of: hotkeyKeyCode) { _ in
            updateHotkeyString()
        }
    }
    
    private func updateHotkeyString() {
        currentHotkeyString = hotkeyString(modifiers: hotkeyModifiers, keyCode: hotkeyKeyCode)
    }
    
    private func hotkeyString(modifiers: Int, keyCode: UInt16) -> String {
        var parts: [String] = []
        
        if modifiers & Int(NSEvent.ModifierFlags.control.rawValue) != 0 {
            parts.append("⌃")
        }
        if modifiers & Int(NSEvent.ModifierFlags.option.rawValue) != 0 {
            parts.append("⌥")
        }
        if modifiers & Int(NSEvent.ModifierFlags.command.rawValue) != 0 {
            parts.append("⌘")
        }
        if modifiers & Int(NSEvent.ModifierFlags.shift.rawValue) != 0 {
            parts.append("⇧")
        }
        
        let keyName = keyName(for: keyCode)
        parts.append(keyName)
        
        return parts.joined(separator: " + ")
    }
    
    private func keyName(for keyCode: UInt16) -> String {
        // Simple key name mapping for common keys
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 32: return "Space"
        case 36: return "Return"
        case 51: return "Delete"
        default: return "Key \(keyCode)"
        }
    }
}

struct HotkeyRecorderView: View {
    @Binding var isRecording: Bool
    @Binding var modifiers: Int
    @Binding var keyCode: UInt16
    
    @State private var eventMonitor: Any?
    
    var body: some View {
        VStack {
            Text("Press the key combination you want to use")
                .font(.headline)
            
            Text("(Press Esc to cancel)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
        .onAppear {
            startRecording()
        }
        .onDisappear {
            stopRecording()
        }
    }
    
    private func startRecording() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            handleKeyEvent(event)
        }
    }
    
    private func stopRecording() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            isRecording = false
            return
        }
        
        if event.type == .keyDown && !event.isARepeat {
            var newModifiers = 0
            
            if event.modifierFlags.contains(.control) {
                newModifiers |= Int(NSEvent.ModifierFlags.control.rawValue)
            }
            if event.modifierFlags.contains(.option) {
                newModifiers |= Int(NSEvent.ModifierFlags.option.rawValue)
            }
            if event.modifierFlags.contains(.command) {
                newModifiers |= Int(NSEvent.ModifierFlags.command.rawValue)
            }
            if event.modifierFlags.contains(.shift) {
                newModifiers |= Int(NSEvent.ModifierFlags.shift.rawValue)
            }
            
            // Require at least one modifier
            if newModifiers != 0 && event.keyCode != 53 {
                modifiers = newModifiers
                keyCode = event.keyCode
                isRecording = false
            }
        }
    }
}

struct AudioSettingsView: View {
    @AppStorage("selectedInputDevice") private var selectedInputDevice: String = "Default"
    @State private var availableDevices: [String] = ["Default", "Built-in Microphone"]
    @State private var isTestingAudio = false
    
    var body: some View {
        Form {
            Section {
                Picker("Input Device:", selection: $selectedInputDevice) {
                    ForEach(availableDevices, id: \.self) { device in
                        Text(device).tag(device)
                    }
                }
                .pickerStyle(.menu)
                
                HStack {
                    Button(isTestingAudio ? "Stop Test" : "Test Audio") {
                        isTestingAudio.toggle()
                        if isTestingAudio {
                            startAudioTest()
                        } else {
                            stopAudioTest()
                        }
                    }
                    
                    if isTestingAudio {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                    }
                }
            }
            
            Section {
                Text("Select the microphone you want to use for dictation. The 'Default' option uses your system's default input device.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Audio")
        .padding()
        .onAppear {
            refreshAudioDevices()
        }
    }
    
    private func refreshAudioDevices() {
        // This would typically query AVAudioSession for available devices
        // For now, we'll use a basic list
        availableDevices = ["Default", "Built-in Microphone", "External Microphone"]
    }
    
    private func startAudioTest() {
        // Start audio level monitoring
        Logger.shared.info("Starting audio test")
    }
    
    private func stopAudioTest() {
        // Stop audio level monitoring
        Logger.shared.info("Stopping audio test")
    }
}

struct AdvancedSettingsView: View {
    @AppStorage("logLevel") private var logLevel: String = "info"
    @AppStorage("enableDebugMode") private var enableDebugMode: Bool = false
    
    var body: some View {
        Form {
            Section {
                Picker("Log Level:", selection: $logLevel) {
                    Text("Debug").tag("debug")
                    Text("Info").tag("info")
                    Text("Warning").tag("warning")
                    Text("Error").tag("error")
                }
                .pickerStyle(.menu)
                
                Toggle("Debug Mode", isOn: $enableDebugMode)
                    .help("Enable additional debugging features and logging")
            }
            
            Section {
                Button("Open Log Files") {
                    openLogFiles()
                }
                
                Button("Clear Cache") {
                    clearCache()
                }
                .foregroundColor(.orange)
            }
        }
        .navigationTitle("Advanced")
        .padding()
    }
    
    private func openLogFiles() {
        // Open log directory in Finder
        if let logPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first {
            let logURL = URL(fileURLWithPath: logPath).appendingPathComponent("Logs")
            NSWorkspace.shared.open(logURL)
        }
    }
    
    private func clearCache() {
        // Clear application cache
        Logger.shared.info("Cache cleared")
    }
}

struct PrivacySettingsView: View {
    @State private var microphonePermission = false
    @State private var accessibilityPermission = false
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Microphone Access")
                                .font(.headline)
                            Text(microphonePermission ? "Granted" : "Required for dictation")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: microphonePermission ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(microphonePermission ? .green : .orange)
                    }
                    
                    Spacer()
                    
                    Button(microphonePermission ? "Granted" : "Request") {
                        requestMicrophonePermission()
                    }
                    .disabled(microphonePermission)
                }
                
                HStack {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Accessibility Access")
                                .font(.headline)
                            Text(accessibilityPermission ? "Granted" : "Required for text insertion")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: accessibilityPermission ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(accessibilityPermission ? .green : .orange)
                    }
                    
                    Spacer()
                    
                    Button(accessibilityPermission ? "Granted" : "Request") {
                        requestAccessibilityPermission()
                    }
                    .disabled(accessibilityPermission)
                }
            }
            
            Section {
                Text("Privacy Policy")
                    .foregroundColor(.blue)
                    .onTapGesture {
                        // Open privacy policy
                    }
                
                Text("InlineWhisper processes all audio and text locally on your Mac. No data is sent to external servers.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Privacy")
        .padding()
        .onAppear {
            checkPermissions()
        }
    }
    
    private func checkPermissions() {
        microphonePermission = Permissions.checkMicrophoneAccess()
        accessibilityPermission = Permissions.checkAccessibility()
    }
    
    private func requestMicrophonePermission() {
        Task {
            let granted = await Permissions.requestMicrophone()
            await MainActor.run {
                microphonePermission = granted
            }
        }
    }
    
    private func requestAccessibilityPermission() {
        Task {
            let granted = await Permissions.requestAccessibility()
            await MainActor.run {
                accessibilityPermission = granted
            }
        }
    }
}

#Preview {
    SettingsView()
}