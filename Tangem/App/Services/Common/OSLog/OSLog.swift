//
//  OSLog.swift
//  TangemApp
//
//  Created by Sergey Balashov on 21.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import OSLog

public typealias OSLog = os.Logger

extension OSLog {
    static func info<T>(_ message: T, category: Category) {
        let msg = String(describing: message)
        logger(for: category).log(level: .info, "\(msg)")
        try? writer.write(msg, category: category, level: .info)
    }

    static func debug<T>(_ message: T, category: Category) {
        let msg = String(describing: message)
        logger(for: category).log(level: .debug, "\(msg)")
        try? writer.write(msg, category: category, level: .debug)
    }

    static func error<T>(_ message: T, category: Category) {
        let msg = String(describing: message)
        logger(for: category).log(level: .error, "\(msg)")
        try? writer.write(msg, category: category, level: .error)
    }

    enum Category: Hashable {
        case network
        case express
        case visa
        case staking
        case token
        case sdk
        case custom(String)

        var name: String {
            switch self {
            case .network: "network"
            case .express: "express"
            case .visa: "visa"
            case .staking: "staking"
            case .token: "token"
            case .sdk: "SDK"
            case .custom(let string): "\(string)"
            }
        }
    }
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

extension OSLog {
    private static let writer = OSLogFileWriter()
    static var logFile: URL {
        writer.logFile
    }
}
