import Foundation
import SwiftUI

///InputText with a scheduled logger


class InputText: ObservableObject {
    @Published var data: String = "input"

    /// Queue for storing log lines before writing to disk
    var logQueue: [String] = []
    private var timer: Timer?

    init() {
        // Start timer to flush logs to disk every 10 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.flushLog()
        }
    }

    deinit {
        timer?.invalidate()
    }

    /// Append a new log entry
    func appendLog(eventType: String, content: String) {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        df.locale = Locale.current
        df.timeZone = TimeZone.current
        let timestamp = df.string(from: Date())
        let line = "\(timestamp), \(eventType), \(content)"
        logQueue.append(line)
    }

    /// Flush queued logs to the daily file
    func flushLog() {
        guard !logQueue.isEmpty else {
            logger.debug("logQueueが空なので無視")
            return
        }

        logger.debug("logQueueが空じゃないので以下を実行！")

        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        let fileName = df.string(from: Date()) + ".txt"

        let fileManager = FileManager.default
        let directory = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("next-toggl-track")
        let fileURL = directory.appendingPathComponent(fileName)

        logger.debug("fileURL:\(fileURL)")

        let text = logQueue.joined(separator: "\n") + "\n"
        logQueue.removeAll()

        if let data = text.data(using: .utf8) {
            if fileManager.fileExists(atPath: fileURL.path) {
                if let handle = try? FileHandle(forWritingTo: fileURL) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    try? handle.close()
                }
            } else {
                try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
                try? data.write(to: fileURL)
            }
        }
    }
}
