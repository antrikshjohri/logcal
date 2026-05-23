//
//  PerfLogger.swift
//  logcal
//
//  Lightweight timing logs for local performance diagnosis.
//

import Foundation

struct PerfLogger {
    private let label: String
    private let startTime: CFAbsoluteTime
    private var lastMarkTime: CFAbsoluteTime

    init(_ label: String) {
        let now = CFAbsoluteTimeGetCurrent()
        self.label = label
        self.startTime = now
        self.lastMarkTime = now
        print("PERF [\(label)] start")
    }

    mutating func mark(_ stage: String, metadata: [String: Any] = [:]) {
        let now = CFAbsoluteTimeGetCurrent()
        let delta = now - lastMarkTime
        let total = now - startTime
        lastMarkTime = now

        var message = "PERF [\(label)] \(stage) +\(format(delta))s total=\(format(total))s"
        if !metadata.isEmpty {
            let details = metadata
                .map { "\($0.key)=\($0.value)" }
                .sorted()
                .joined(separator: " ")
            message += " \(details)"
        }
        print(message)
    }

    func end(_ stage: String = "end", metadata: [String: Any] = [:]) {
        let total = CFAbsoluteTimeGetCurrent() - startTime
        var message = "PERF [\(label)] \(stage) total=\(format(total))s"
        if !metadata.isEmpty {
            let details = metadata
                .map { "\($0.key)=\($0.value)" }
                .sorted()
                .joined(separator: " ")
            message += " \(details)"
        }
        print(message)
    }

    private func format(_ value: CFAbsoluteTime) -> String {
        String(format: "%.3f", value)
    }
}
