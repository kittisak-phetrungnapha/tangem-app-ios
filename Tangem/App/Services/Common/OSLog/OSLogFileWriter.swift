//
//  OSLogFileWriter.swift
//  TangemApp
//
//  Created by Sergey Balashov on 22.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import OSLog

class OSLogFileWriter {
    private let fileName = "oslog.csv"
    private let separator = ","
    private let numberOfDaysUntilExpiration = 7
    private let loggerSerialQueue = DispatchQueue(label: "com.tangem.OSLogFileWriter.queue")

    private lazy var fileManager: FileManager = .default

    private lazy var logFileURL: URL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter
    }()

    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss:SSS"
        return formatter
    }()

    init() {
        try? fileManager.removeItem(at: logFileURL)
        try? removeLogFileIfNeeded()
        try? createLogFileIfNeeded()
    }

    var logFile: URL { logFileURL }

    func write(_ message: String, category: OSLog.Category, level: OSLogEntryLog.Level, date: Date = .now) throws {
        if message.contains("\n") {
            try message.components(separatedBy: "\n").forEach {
                try write($0, category: category, level: level, date: date)
            }
            return
        }

        assert(!message.contains("\n"), "Should be separated by a few messages")

        if message.isEmpty {
            assertionFailure("Message can not be empty")
            return
        }

        let encoded = message
            // "This symbol `,` will be replaced to `;`"
            .replacingOccurrences(of: separator, with: ";")
            // Just in case
            .replacingOccurrences(of: "\n", with: "@new-line@")

        let data = [
            dateFormatter.string(from: date),
            timeFormatter.string(from: date),
            category.name,
            level.name,
            encoded,
        ]
        let message = "\n\(data.joined(separator: separator))"
        try write(message: message)
    }

    private func write(message: String) throws {
        try loggerSerialQueue.sync {
            guard let data = message.data(using: .utf8) else {
                throw Errors.wrongData
            }

            let handler = try FileHandle(forWritingTo: logFileURL)
            try handler.seekToEnd()
            try handler.write(contentsOf: data)
            try handler.close()
        }
    }

    private func createLogFileIfNeeded() throws {
        guard !fileManager.fileExists(atPath: logFileURL.relativePath) else {
            return
        }

        fileManager.createFile(atPath: logFileURL.relativePath, contents: nil)

        let header = ["date", "time", "category", "level", "message"].joined(separator: separator)
        try write(message: header)
    }

    private func removeLogFileIfNeeded() throws {
        let fileAttributes = try fileManager.attributesOfItem(atPath: logFileURL.relativePath)

        guard let creationDate = fileAttributes[.creationDate] as? Date,
              let expirationDate = Calendar.current.date(byAdding: .day, value: numberOfDaysUntilExpiration, to: creationDate),
              expirationDate < Date() else {
            return
        }

        try fileManager.removeItem(at: logFileURL)
    }
}

extension OSLogFileWriter {
    enum Errors: LocalizedError {
        case wrongData

        var errorDescription: String? {
            switch self {
            case .wrongData: "Wrong data"
            }
        }
    }

    struct LogMessage: Hashable {
        let date: String
        let time: String
        let category: String
        let level: String
        let message: String
    }
}

private extension OSLogEntryLog.Level {
    var name: String {
        switch self {
        case .undefined: "Undefined"
        case .debug: "Debug"
        case .info: "Info"
        case .notice: "Notice"
        case .error: "Error"
        case .fault: "Fault"
        @unknown default: "@unknown default"
        }
    }
}
