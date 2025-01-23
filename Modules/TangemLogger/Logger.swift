//
//  Logger.swift
//  TangemModules
//
//  Created by Sergey Balashov on 23.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum Logger {
    public typealias Category = OSLogCategory

    static var logFile: URL { OSLog.writer.logFile }
}

public extension Logger {
    static func debug(_ category: Category, _ message: Any...) {
        log(message: message, category: category, level: .debug)
    }

    /// Some info
    static func info(_ category: Category, _ message: Any...) {
        log(message: message, category: category, level: .info)
    }

    /// Yellow background
    static func warning(_ category: Category, _ message: Any...) {
        log(message: message, category: category, level: .error)
    }

    /// Red background
    static func error(_ category: Category, _ message: Any...) {
        log(message: message, category: category, level: .fault)
    }
}

// MARK: - Helpers

private extension Logger {
    static func log(message: Any..., category: OSLog.Category, level: OSLog.Level) {
        do {
            let message = message.map(String.init(describing:)).joined(separator: ", ")
            OSLog[category].log(level: level, "\(message)")
            try OSLog.writer.write(message, category: category, level: level)
        } catch {
            OSLog[.logFileWriter].fault("\(error.localizedDescription)")
        }
    }
}
