import SwiftUI
import Combine
import DictationKit
import SystemKit

struct AudioLevelView: View {
    @EnvironmentObject var dictationService: DictationService
    @State private var audioLevels: [Float] = Array(repeating: 0.0, count: 50)
    @State private var currentLevel: Float = 0.0
    @State private var isMonitoring = false
    @State private var monitoringCancellable: AnyCancellable?
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 8) {
            // Visual audio meter
            HStack(spacing: 2) {
                ForEach(0..<audioLevels.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(audioLevelColor(for: audioLevels[index]))
                        .frame(width: 4, height: levelHeight(for: audioLevels[index]))
                }
            }
            .frame(height: 40)
            
            // Current level indicator
            HStack {
                Text("Audio Level")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(currentLevel * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(audioLevelColor(for: currentLevel))
            }
            .padding(.horizontal, 4)
            
            // Control button
            Button(action: {
                toggleMonitoring()
            }) {
                Image(systemName: isMonitoring ? "stop.circle" : "play.circle")
                Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
        .onAppear {
            startAudioMonitoring()
        }
        .onDisappear {
            stopAudioMonitoring()
        }
    }
    
    private func toggleMonitoring() {
        if isMonitoring {
            stopAudioMonitoring()
        } else {
            startAudioMonitoring()
        }
    }
    
    private func startAudioMonitoring() {
        guard !isMonitoring else { return }
        
        Logger.shared.info("Starting audio level monitoring")
        isMonitoring = true
        
        // Create a mock audio level monitor for MVP
        monitoringCancellable = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                updateAudioLevels()
            }
    }
    
    private func stopAudioMonitoring() {
        guard isMonitoring else { return }
        
        Logger.shared.info("Stopping audio level monitoring")
        isMonitoring = false
        monitoringCancellable?.cancel()
        monitoringCancellable = nil
        
        // Reset levels
        audioLevels = Array(repeating: 0.0, count: 50)
        currentLevel = 0.0
    }
    
    private func updateAudioLevels() {
        // Mock audio level generation for MVP
        // In a real implementation, this would come from the audio service
        
        let targetLevel = isMonitoring ? Float.random(in: 0.0...0.8) : 0.0
        let smoothingFactor: Float = 0.3
        
        // Update current level with smoothing
        currentLevel = currentLevel * (1.0 - smoothingFactor) + targetLevel * smoothingFactor
        
        // Shift audio levels array and add new level
        audioLevels.removeFirst()
        audioLevels.append(currentLevel)
        
        // Add some variation based on dictation state
        if dictationService.isListening {
            // Make levels more dynamic when listening
            let variation = Float.random(in: -0.1...0.1)
            currentLevel = max(0.0, min(1.0, currentLevel + variation))
        }
    }
    
    private func audioLevelColor(for level: Float) -> Color {
        if level < 0.1 {
            return .green
        } else if level < 0.5 {
            return .yellow
        } else if level < 0.8 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func levelHeight(for level: Float) -> CGFloat {
        let minHeight: CGFloat = 2
        let maxHeight: CGFloat = 40
        return minHeight + (maxHeight - minHeight) * CGFloat(level)
    }
}

// MARK: - Extended Audio Level View for Settings

struct AudioSettingsLevelView: View {
    @State private var audioLevel: Float = 0.0
    @State private var isTesting = false
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 16) {
            // Large audio level meter
            VStack(spacing: 4) {
                HStack(spacing: 2) {
                    ForEach(0..<30, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(audioLevelColor(for: audioLevel))
                            .frame(
                                width: 8,
                                height: isTesting ? CGFloat(randomLevel() * 120) : 4
                            )
                    }
                }
                .frame(height: 120)
                .animation(.easeInOut(duration: 0.1), value: audioLevel)
                
                HStack {
                    Text("Level: \(Int(audioLevel * 100))%")
                        .font(.headline)
                        .foregroundColor(audioLevelColor(for: audioLevel))
                    
                    Spacer()
                    
                    if isTesting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                    }
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
            
            // Test controls
            HStack {
                Button(action: {
                    toggleTesting()
                }) {
                    Image(systemName: isTesting ? "stop.circle.fill" : "play.circle.fill")
                    Text(isTesting ? "Stop Test" : "Start Test")
                }
                .buttonStyle(.borderedProminent)
                
                Button("Reset") {
                    resetAudioLevels()
                }
                .buttonStyle(.bordered)
                .disabled(!isTesting)
            }
            
            // Audio device info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Sample Rate:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("16 kHz")
                        .font(.caption)
                }
                
                HStack {
                    Text("Format:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("16-bit PCM")
                        .font(.caption)
                }
                
                HStack {
                    Text("Latency:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("< 100ms")
                        .font(.caption)
                }
            }
            .padding(8)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(6)
        }
    }
    
    private func toggleTesting() {
        if isTesting {
            stopTesting()
        } else {
            startTesting()
        }
    }
    
    private func startTesting() {
        isTesting = true
        audioLevel = 0.0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            updateAudioLevel()
        }
        
        Logger.shared.info("Starting audio level test")
    }
    
    private func stopTesting() {
        isTesting = false
        timer?.invalidate()
        timer = nil
        audioLevel = 0.0
        
        Logger.shared.info("Stopping audio level test")
    }
    
    private func resetAudioLevels() {
        audioLevel = 0.0
        Logger.shared.info("Audio levels reset")
    }
    
    private func updateAudioLevel() {
        // Simulate varying audio levels
        let targetLevel = Float.random(in: 0.1...0.8)
        let smoothingFactor: Float = 0.2
        
        audioLevel = audioLevel * (1.0 - smoothingFactor) + targetLevel * smoothingFactor
    }
    
    private func randomLevel() -> Float {
        return Float.random(in: 0.0...1.0)
    }
    
    private func audioLevelColor(for level: Float) -> Color {
        if level < 0.1 {
            return .green.opacity(0.6)
        } else if level < 0.4 {
            return .yellow.opacity(0.7)
        } else if level < 0.7 {
            return .orange.opacity(0.8)
        } else {
            return .red.opacity(0.9)
        }
    }
}

// MARK: - Compact Audio Level Indicator

struct AudioLevelIndicator: View {
    @Binding var level: Float
    @Binding var isActive: Bool
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<10, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(barColor(for: index))
                    .frame(width: 2, height: barHeight(for: index))
            }
        }
        .frame(height: 8)
        .opacity(isActive ? 1.0 : 0.5)
    }
    
    private func barColor(for index: Int) -> Color {
        let threshold = Float(index) / Float(10)
        if level >= threshold {
            if index < 3 {
                return .green
            } else if index < 7 {
                return .yellow
            } else {
                return .red
            }
        } else {
            return .secondary.opacity(0.3)
        }
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        let threshold = Float(index) / Float(10)
        if level >= threshold {
            return 6
        } else {
            return 2
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AudioLevelView()
            .environmentObject(DictationService.shared)
        
        AudioSettingsLevelView()
    }
    .padding()
}