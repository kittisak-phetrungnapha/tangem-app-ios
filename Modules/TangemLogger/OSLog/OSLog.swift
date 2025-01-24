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
    typealias Level = OSLogLevel
}

extension OSLog {
    func log<T>(level: Level, message: @autoclosure () -> T) {
        let msg = String(describing: message())

        switch level {
        case .debug: debug("\(msg, privacy: .auto)")
        case .info: info("\(msg, privacy: .auto)")
        case .warning: error("\(msg, privacy: .auto)")
        case .error: fault("\(msg, privacy: .auto))")
        }
    }
}

extension OSLog {
    private static let queue = DispatchQueue(label: subsystem, attributes: .concurrent)
    private static let subsystem = "com.tangem.os.logger"
    private static var loggers: [Category: OSLog] = [:]

    static func logger(for category: Category) -> OSLog {
        queue.sync {
            if let logger = loggers[category] {
                return logger
            }

            let logger = OSLog(subsystem: subsystem, category: category.name.capitalized)
            loggers[category] = logger
            return logger
        }
    }
}
