import SwiftUI
import DictationKit
import SystemKit

struct ContentView: View {
    @EnvironmentObject var dictationService: DictationService
    @State private var showingSettings = false
    @State private var showingOnboarding = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: dictationService.isListening ? "mic.fill" : "mic")
                            .foregroundColor(dictationService.isListening ? .red : .primary)
                            .imageScale(.large)
                        
                        Text("InlineWhisper")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    
                    Text(dictationService.isListening ? "Dictation Active" : "Ready to Transcribe")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Main control
                VStack(spacing: 16) {
                    Button(action: {
                        dictationService.toggleDictation()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: dictationService.isListening ? "stop.fill" : "play.fill")
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(dictationService.isListening ? "Stop Dictation" : "Start Dictation")
                                    .font(.headline)
                                
                                Text("Hotkey: Control + Option + D")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .keyboardShortcut("d", modifiers: [.control, .option])
                    
                    // Status indicator
                    HStack {
                        Circle()
                            .fill(dictationService.isListening ? Color.red : Color.green)
                            .frame(width: 8, height: 8)
                        
                        Text(dictationService.stateDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        AudioLevelIndicator(level: .constant(0.5), isActive: .constant(dictationService.isListening))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Audio level visualization
                if dictationService.isListening {
                    AudioLevelView()
                        .padding(.horizontal)
                }
                
                // Transcription area
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Transcription")
                            .font(.headline)
                        
                        Spacer()
                        
                        if !dictationService.currentText.isEmpty {
                            Button("Copy") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(dictationService.currentText, forType: .string)
                            }
                            .font(.caption)
                        }
                    }
                    
                    if dictationService.currentText.isEmpty {
                        Text(dictationService.isListening ? "Listening for speech..." : "Press Start to begin dictation")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(minHeight: 100, alignment: .center)
                            .frame(maxWidth: .infinity)
                    } else {
                        ScrollView {
                            Text(dictationService.currentText)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Footer
                HStack {
                    Button("Settings") {
                        showingSettings = true
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Text("Offline • Privacy-First")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("InlineWhisper")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: {
                        showingOnboarding = true
                    }) {
                        Image(systemName: "questionmark.circle")
                    }
                    .help("Show help and onboarding")
                }
                
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                    .help("Open settings")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView()
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    ContentView()
        .environmentObject(DictationService.shared)
}