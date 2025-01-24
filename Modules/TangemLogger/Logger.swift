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
    static func debug(
        _ category: Category,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function,
        _ message: Any...
    ) {
        log(.debug, category: category, message: "\(file):\(line):", message.describing())
    }

    /// Save some information that will be useful to find the bug
    static func info(_ category: Category, _ message: Any...) {
        log(.info, category: category, message: message)
    }

    /// Yellow background
    static func warning(_ category: Category, _ message: Any...) {
        log(.warning, category: category, message: message)
    }

    /// Red background
    static func error(_ category: Category, _ message: Any...) {
        log(.error, category: category, message: message)
    }
}

// MARK: - Helpers

private extension Logger {
    static func log(_ level: OSLog.Level, category: OSLog.Category, message: Any...) {
        let msg = message.describing()
        OSLog.logger(for: category).log(level: level, message: "\(msg)")

        guard configuration.shouldToStore(category: category, level: level) else {
            return
        }

        do {
            try OSLogFileWriter.shared.write(msg, category: category, level: level)
        } catch {
            OSLog.logger(for: .logFileWriter).fault("\(error.localizedDescription)")
        }
    }
}

private extension [Any] {
    func describing(separator: String = " ") -> String {
        map(String.init(describing:)).joined(separator: separator)
    }
}
