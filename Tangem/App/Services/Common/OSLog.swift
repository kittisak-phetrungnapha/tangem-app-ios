//
//  OSLog.swift
//  TangemApp
//
//  Created by Sergey Balashov on 21.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import OSLog

public typealias OSLog = os.Logger

public extension OSLog {
    static func log<T>(message: T) {
        let msg = String(describing: message)
        common.info("\(msg)")

        do {
            let store = try OSLogStore(scope: OSLogStore.Scope.currentProcessIdentifier)
            let date = store.position(timeIntervalSinceEnd: -60.0)
            let entries = try store.getEntries(at: date)

            print(entries.map {
                "\(($0.date, $0.composedMessage))\n"
            }
            )
        } catch {
            common.error("\(error.localizedDescription)")
        }
    }
}

private extension String {
    var encode: String { replacingOccurrences(of: "\n", with: "@new-line@") }
}

extension OSLog {
    /// Using your bundle identifier is a great way to ensure a unique identifier.
    private static var subsystem = Bundle.main.bundleIdentifier!

    static let common = OSLog(subsystem: subsystem, category: "viewcycle")

    static let api = OSLog(subsystem: subsystem, category: "API")
}
