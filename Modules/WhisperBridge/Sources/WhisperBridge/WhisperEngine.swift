import Foundation

public struct ASRConfig {
    public var threads: Int = max(2, ProcessInfo.processInfo.activeProcessorCount - 2)
    public var temperature: Float = 0.0
    public var englishOnly: Bool = true
    public var translate: Bool = false
    public var noContext: Bool = true
    
    public static func mvpEnglish() -> ASRConfig {
        return ASRConfig()
    }
}

public protocol WhisperEngine {
    func loadBundledTinyEN() throws
    func beginStream(config: ASRConfig, onPartial: @escaping (String) -> Void, onFinal: @escaping (String) -> Void) throws
    func feed(samples: UnsafePointer<Float>, count: Int)
    func endStream()
    func isModelLoaded() -> Bool
}

public enum WhisperError: Error {
    case modelLoadFailed(reason: String)
    case streamingNotInitialized
    case audioFeedFailed
    case invalidModelFormat
}

public enum WhisperModelSize {
    case tiny
    case base
    case small
    case medium
    case large
    
    public var description: String {
        switch self {
        case .tiny: return "tiny.en"
        case .base: return "base.en"
        case .small: return "small.en"
        case .medium: return "medium.en"
        case .large: return "large"
        }
    }
}