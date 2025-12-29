//
//  DebugLogger.swift
//  logcal
//
//  Created for debugging
//

import Foundation

struct DebugLogger {
    private static var logPath: String {
        // Try workspace path first, fallback to documents directory
        let workspacePath = "/Users/ajohri/Documents/Antriksh Personal/LogCal/logcal/.cursor/debug.log"
        if FileManager.default.isWritableFile(atPath: "/Users/ajohri/Documents/Antriksh Personal/LogCal/logcal/.cursor") {
            return workspacePath
        }
        // Fallback to app's documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("debug.log").path
    }
    
    static func log(location: String, message: String, data: [String: Any] = [:], hypothesisId: String = "") {
        let logEntry: [String: Any] = [
            "id": "log_\(Int(Date().timeIntervalSince1970 * 1000))_\(UUID().uuidString.prefix(8))",
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
            "location": location,
            "message": message,
            "data": data,
            "sessionId": "debug-session",
            "runId": "run1",
            "hypothesisId": hypothesisId
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: logEntry),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            // Also print to console as fallback
            print("DEBUG_LOG [\(location)] \(message) - \(data)")
            return
        }
        
        let logLine = jsonString + "\n"
        let path = logPath
        
        // Ensure directory exists
        let directory = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
        
        if let fileHandle = FileHandle(forWritingAtPath: path) {
            defer { fileHandle.closeFile() }
            fileHandle.seekToEndOfFile()
            if let data = logLine.data(using: .utf8) {
                fileHandle.write(data)
            }
        } else {
            // File doesn't exist, create it with the log line
            if let data = logLine.data(using: .utf8) {
                FileManager.default.createFile(atPath: path, contents: data, attributes: nil)
            }
        }
        
        // Also print to console as fallback
        print("DEBUG_LOG [\(location)] \(message) - \(data)")
    }
}

