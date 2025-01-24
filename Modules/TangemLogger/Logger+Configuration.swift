//
//  Logger+Configuration.swift
//  TangemModules
//
//  Created by Sergey Balashov on 24.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public extension Logger {
    protocol Configuration {
        func shouldToStore(category: Category, level: Level) -> Bool
    }

    struct DefaultConfiguration: Configuration {
        public init() {}

        public func shouldToStore(category: Category, level: Level) -> Bool { level != .debug }
    }
}
