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
    static func debug<T>(_ category: Category, _ message: @autoclosure () -> T) {
        let message = String(describing: message())
        log(message: message, category: category, level: .debug)
    }

    /// Save some information that will be useful to find the bug
    static func info<T>(_ category: Category, _ message: @autoclosure () -> T) {
        let message = String(describing: message())
        log(message: message, category: category, level: .info)
    }

    /// Yellow background
    static func warning<T>(_ category: Category, _ message: @autoclosure () -> T) {
        let message = String(describing: message())
        log(message: message, category: category, level: .error)
    }

    /// Red background
    static func error<T>(_ category: Category, _ message: @autoclosure () -> T) {
        let message = String(describing: message())
        log(message: message, category: category, level: .fault)
    }
}

// MARK: - Helpers

private extension Logger {
    static func log(message: String, category: OSLog.Category, level: OSLog.Level) {
        do {
            OSLog[category].log(level: level, "\(message)")
            try OSLog.writer.write(message, category: category, level: level)
        } catch {
            OSLog[.logFileWriter].fault("\(error.localizedDescription)")
        }
    }
}
