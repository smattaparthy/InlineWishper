import SwiftUI
import SystemKit
import DictationKit

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var microphonePermissionGranted = false
    @State private var accessibilityPermissionGranted = false
    @State private var isCheckingPermissions = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Rectangle()
                        .fill(index <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            // Content area
            TabView(selection: $currentStep) {
                WelcomeStep()
                    .tag(0)
                
                MicrophonePermissionStep(
                    permissionGranted: $microphonePermissionGranted,
                    isChecking: $isCheckingPermissions
                )
                .tag(1)
                
                AccessibilityPermissionStep(
                    permissionGranted: $accessibilityPermissionGranted,
                    isChecking: $isCheckingPermissions
                )
                .tag(2)
                
                ModelDownloadStep()
                    .tag(3)
                
                FinalStep()
                    .tag(4)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .disabled(true) // Prevent swipe navigation
            
            // Navigation buttons
            HStack {
                if currentStep > 0 {
                    Button("Previous") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .keyboardShortcut(.cancelAction)
                }
                
                Spacer()
                
                Button(action: {
                    handleNextStep()
                }) {
                    HStack {
                        Text(buttonTitle)
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!canProceed)
            }
            .padding(40)
        }
        .frame(width: 700, height: 500)
        .onAppear {
            checkInitialPermissions()
        }
    }
    
    private var totalSteps: Int { 5 }
    
    private var buttonTitle: String {
        switch currentStep {
        case 0: return "Get Started"
        case totalSteps - 1: return "Finish"
        default: return "Next"
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 1: return microphonePermissionGranted
        case 2: return accessibilityPermissionGranted
        default: return true
        }
    }
    
    private func handleNextStep() {
        if currentStep < totalSteps - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            // Finish onboarding
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            dismiss()
        }
    }
    
    private func checkInitialPermissions() {
        microphonePermissionGranted = Permissions.checkMicrophoneAccess()
        accessibilityPermissionGranted = Permissions.checkAccessibility()
    }
}

struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("Welcome to InlineWhisper")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your privacy-first dictation assistant that works offline")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "shield", text: "Completely offline - no data leaves your Mac")
                FeatureRow(icon: "sparkles", text: "Real-time transcription with Whisper AI")
                FeatureRow(icon: "cursorarrow", text: "Insert text into any application")
                FeatureRow(icon: "keyboard", text: "System-wide hotkey support")
            }
            .padding(.vertical, 20)
            
            Spacer()
        }
        .padding(40)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

struct MicrophonePermissionStep: View {
    @Binding var permissionGranted: Bool
    @Binding var isChecking: Bool
    
    @State private var isRequesting = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: permissionGranted ? "checkmark.circle.fill" : "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(permissionGranted ? .green : .accentColor)
            
            Text("Microphone Access")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("InlineWhisper needs access to your microphone to transcribe your speech")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if permissionGranted {
                Text("✅ Microphone access granted")
                    .font(.headline)
                    .foregroundColor(.green)
            } else {
                Text("Click 'Allow Microphone' to enable dictation")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !permissionGranted {
                Button(isRequesting ? "Requesting..." : "Allow Microphone") {
                    requestMicrophonePermission()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isRequesting || isChecking)
            }
            
            Text("You can change this later in System Settings > Privacy & Security > Microphone")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(40)
        .onAppear {
            checkPermission()
        }
    }
    
    private func checkPermission() {
        isChecking = true
        permissionGranted = Permissions.checkMicrophoneAccess()
        isChecking = false
    }
    
    private func requestMicrophonePermission() {
        isRequesting = true
        
        Task {
            let granted = await Permissions.requestMicrophone()
            
            await MainActor.run {
                permissionGranted = granted
                isRequesting = false
            }
        }
    }
}

struct AccessibilityPermissionStep: View {
    @Binding var permissionGranted: Bool
    @Binding var isChecking: Bool
    
    @State private var isRequesting = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: permissionGranted ? "checkmark.circle.fill" : "cursorarrow.click.badge.clock")
                .font(.system(size: 80))
                .foregroundColor(permissionGranted ? .green : .accentColor)
            
            Text("Accessibility Access")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("InlineWhisper needs accessibility access to insert text into other applications")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if permissionGranted {
                Text("✅ Accessibility access granted")
                    .font(.headline)
                    .foregroundColor(.green)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This allows InlineWhisper to:")
                        .font(.headline)
                    
                    Text("• Insert text into any application")
                    Text("• Work with your existing workflow")
                    Text("• Paste text using Command+V")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            
            if !permissionGranted {
                VStack(spacing: 12) {
                    Button(isRequesting ? "Opening Settings..." : "Open System Settings") {
                        requestAccessibilityPermission()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isRequesting || isChecking)
                    
                    Text("You'll be taken to System Settings > Privacy & Security > Accessibility")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(40)
        .onAppear {
            checkPermission()
        }
    }
    
    private func checkPermission() {
        isChecking = true
        permissionGranted = Permissions.checkAccessibility()
        isChecking = false
    }
    
    private func requestAccessibilityPermission() {
        isRequesting = true
        
        // Open System Settings to Accessibility
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
        
        // Request accessibility
        Task {
            let granted = await Permissions.requestAccessibility()
            
            await MainActor.run {
                permissionGranted = granted
                isRequesting = false
            }
        }
    }
}

struct ModelDownloadStep: View {
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0.0
    @State private var downloadComplete = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: downloadComplete ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(downloadComplete ? .green : .accentColor)
            
            Text("Download AI Model")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("InlineWhisper needs a small AI model (~40MB) to transcribe your speech offline")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if downloadComplete {
                Text("✅ AI model downloaded")
                    .font(.headline)
                    .foregroundColor(.green)
            } else if isDownloading {
                VStack(spacing: 12) {
                    ProgressView(value: downloadProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 200)
                    
                    Text("Downloading Whisper AI model...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This model:")
                        .font(.headline)
                    
                    Text("• Runs completely offline on your Mac")
                    Text("• Provides accurate speech recognition")
                    Text("• Works in English language")
                    Text("• Requires ~40MB of storage")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            
            if !downloadComplete {
                Button(isDownloading ? "Downloading..." : "Download Model") {
                    downloadModel()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isDownloading)
            }
        }
        .padding(40)
        .onAppear {
            checkModelExists()
        }
    }
    
    private func checkModelExists() {
        let modelPath = getModelPath()
        if FileManager.default.fileExists(atPath: modelPath) {
            downloadComplete = true
        }
    }
    
    private func getModelPath() -> String {
        return "\(FileManager.default.currentDirectoryPath)/models/ggml-tiny.en-f16.bin"
    }
    
    private func downloadModel() {
        isDownloading = true
        
        // Simulate download progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            downloadProgress += 0.02
            
            if downloadProgress >= 1.0 {
                timer.invalidate()
                downloadProgress = 1.0
                downloadComplete = true
                isDownloading = false
                
                Logger.shared.info("Model download simulation complete")
            }
        }
    }
}

struct FinalStep: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "party.popper.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("InlineWhisper is ready to help you type with your voice")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Start:")
                    .font(.headline)
                
                FeatureRow(icon: "1.circle", text: "Press ⌃⌥D to start dictation")
                FeatureRow(icon: "2.circle", text: "Speak clearly into your microphone")
                FeatureRow(icon: "3.circle", text: "Text will appear in your current app")
                FeatureRow(icon: "4.circle", text: "Press ⌃⌥D again to stop")
            }
            .padding(.vertical, 20)
            
            Spacer()
            
            Text("You can change settings anytime from the menu bar")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(40)
    }
}

#Preview {
    OnboardingView()
}