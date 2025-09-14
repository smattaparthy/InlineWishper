import Foundation

public final class Logger {
    public static let shared = Logger()
    
    private init() {}
    
    public func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log("🐛 DEBUG", message, file: file, function: function, line: line)
    }
    
    public func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log("ℹ️ INFO", message, file: file, function: function, line: line)
    }
    
    public func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log("⚠️ WARNING", message, file: file, function: function, line: line)
    }
    
    public func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log("❌ ERROR", message, file: file, function: function, line: line)
    }
    
    private func log(_ level: String, _ message: String, file: String, function: String, line: Int) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[\(timestamp)] \(level) [\(fileName):\(line)] \(function): \(message)")
        #endif
    }
}

// Convenience extensions
public extension String {
    func logDebug(file: String = #file, function: String = #function, line: Int = #line) {
        Logger.shared.debug(self, file: file, function: function, line: line)
    }
    
    func logInfo(file: String = #file, function: String = #function, line: Int = #line) {
        Logger.shared.info(self, file: file, function: function, line: line)
    }
    
    func logWarning(file: String = #file, function: String = #function, line: Int = #line) {
        Logger.shared.warning(self, file: file, function: function, line: line)
    }
    
    func logError(file: String = #file, function: String = #function, line: Int = #line) {
        Logger.shared.error(self, file: file, function: function, line: line)
    }
}