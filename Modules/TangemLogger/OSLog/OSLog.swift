//
//  OSLog.swift
//  TangemApp
//
//  Created by Sergey Balashov on 21.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import OSLog

typealias OSLog = os.Logger

extension OSLog {
    typealias Category = OSLogCategory
    typealias Level = OSLogType
}

extension OSLog {
    static subscript(_ category: Category) -> OSLog {
        .logger(for: category)
    }
}

private extension OSLog {
    static let subsystem = "com.tangem.os.logger"
    static var loggers: [Category: OSLog] = [:]

    static func logger(for category: Category) -> OSLog {
        if let logger = loggers[category] {
            return logger
        }

        let logger = OSLog(subsystem: subsystem, category: category.name.capitalized)
        loggers[category] = logger
        return logger
    }
}

// MARK: - Writer

extension OSLog {
    static let writer = OSLogFileWriter()
}
