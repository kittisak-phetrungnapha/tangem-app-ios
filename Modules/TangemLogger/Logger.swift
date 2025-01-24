//
//  Logger.swift
//  TangemModules
//
//  Created by Sergey Balashov on 23.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import OSLog

public enum Logger {
    public typealias Category = OSLogCategory
    public typealias Level = OSLogLevel

    public static var configuration = DefaultConfiguration()
    public static var logFile: URL { OSLogFileWriter.shared.logFile }
}

public extension Logger {
    static func debug(_ category: Category, _ message: Any...) {
        log(category: category, level: .debug, message: message)
    }

    /// Save some information that will be useful to find the bug
    static func info(_ category: Category, _ message: Any...) {
        log(category: category, level: .info, message: message)
    }

    /// Yellow background
    static func warning(_ category: Category, _ message: Any...) {
        log(category: category, level: .warning, message: message)
    }

    /// Red background
    static func error(_ category: Category, _ message: Any...) {
        log(category: category, level: .error, message: message)
    }
}

// MARK: - Helpers

private extension Logger {
    static func log(category: OSLog.Category, level: OSLog.Level, message: Any...) {
        let message = message.map(String.init(describing:)).joined(separator: ", ")
        OSLog.logger(for: category).log(level: level, message: "\(message)")

        guard configuration.shouldToStore(category: category, level: level) else {
            return
        }

        do {
            try OSLogFileWriter.shared.write(message, category: category, level: level)
        } catch {
            OSLog.logger(for: .logFileWriter).fault("\(error.localizedDescription)")
        }
    }
}
