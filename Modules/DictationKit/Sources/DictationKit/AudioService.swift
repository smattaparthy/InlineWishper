import Foundation
import AVFoundation
import SystemKit

public final class AudioService {
    public var onAudioSamples: (([Float]) -> Void)?
    
    private let engine = AVAudioEngine()
    private let bus = 0
    private let sampleRate: Double = 16000
    private let bufferSize: AVAudioFrameCount = 1024
    private var isCapturing = false
    
    public init() {}
    
    public func startCapture() throws {
        guard !isCapturing else { return }
        
        "Starting audio capture".logInfo()
        
        // Clean up any existing tap
        engine.inputNode.removeTap(onBus: bus)
        
        // Get input format
        let inputFormat = engine.inputNode.inputFormat(forBus: bus)
        _ = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 1
        )!
        
        // Install tap on input node
        engine.inputNode.installTap(
            onBus: bus,
            bufferSize: bufferSize,
            format: inputFormat
        ) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer, time: time)
        }
        
        // Start the audio engine
        try engine.start()
        isCapturing = true
        
        "Audio capture started".logInfo()
    }
    
    public func stopCapture() {
        guard isCapturing else { return }
        
        "Stopping audio capture".logInfo()
        
        engine.inputNode.removeTap(onBus: bus)
        engine.stop()
        isCapturing = false
        
        "Audio capture stopped".logInfo()
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        var monoSamples = [Float](repeating: 0, count: frameLength)
        
        // Convert to mono and resample if needed
        let inputFormat = buffer.format
        let sampleRate = inputFormat.sampleRate
        
        if abs(sampleRate - self.sampleRate) < 1.0 {
            // Same sample rate, just convert to mono
            for i in 0..<frameLength {
                monoSamples[i] = channelData[0][i]
            }
        } else {
            // Basic resampling to 16kHz - for MVP we'll just take every nth sample
            let resamplingFactor = sampleRate / self.sampleRate
            let targetLength = Int(Double(frameLength) / resamplingFactor)
            
            monoSamples = [Float](repeating: 0, count: targetLength)
            for i in 0..<targetLength {
                let sourceIndex = Int(Double(i) * resamplingFactor)
                if sourceIndex < frameLength {
                    monoSamples[i] = channelData[0][sourceIndex]
                }
            }
        }
        
        // Send samples to callback
        onAudioSamples?(monoSamples)
    }
    
    // macOS doesn't use AVAudioSession - devices are handled differently
    public func availableInputDevices() -> [String] {
        // For MVP, return basic device info
        return ["Built-in Microphone", "Default Input Device"]
    }
    
    public func selectInputDevice(_ deviceID: String) throws {
        // For MVP, we'll just log the selection attempt
        "Attempting to select input device: \(deviceID)".logInfo()
        // Real implementation would use AVAudioEngine input selection
    }
    
    public var currentInputDevice: String? {
        return "Built-in Microphone" // Default for MVP
    }
}