import SwiftUI
import DictationKit
import SystemKit

struct MenuBarView: View {
    @EnvironmentObject var dictationService: DictationService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: dictationService.isListening ? "mic.fill" : "mic")
                    .foregroundColor(dictationService.isListening ? .red : .primary)
                    .imageScale(.large)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("InlineWhisper")
                        .font(.headline)
                    
                    Text(dictationService.stateDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Control button
            Button(action: {
                dictationService.toggleDictation()
            }) {
                HStack {
                    Image(systemName: dictationService.isListening ? "stop.fill" : "play.fill")
                    Text(dictationService.isListening ? "Stop Dictation" : "Start Dictation")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            // Current text preview (if available)
            if !dictationService.currentText.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Text:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(dictationService.currentText)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
            
            Divider()
            
            // Settings and quit
            Button("Settings...") {
                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            }
            
            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding()
        .frame(width: 280)
    }
}

#Preview {
    MenuBarView()
        .environmentObject(DictationService.shared)
}