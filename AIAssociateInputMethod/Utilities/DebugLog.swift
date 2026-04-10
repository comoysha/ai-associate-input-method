import Foundation

enum DebugLog {
    static let logFile = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("ai_associate_debug.log")

    static func log(_ message: String, file: String = #file, function: String = #function) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let line = "[\(timestamp)] [\(fileName):\(function)] \(message)\n"
        guard let data = line.data(using: .utf8) else { return }

        if FileManager.default.fileExists(atPath: logFile.path) {
            if let handle = try? FileHandle(forWritingTo: logFile) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }
        } else {
            try? data.write(to: logFile)
        }
    }
}
