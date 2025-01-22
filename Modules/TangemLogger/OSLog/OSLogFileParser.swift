//
//  OSLogFileParser.swift
//  TangemModules
//
//  Created by Sergey Balashov on 23.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum OSLogFileParser {
    public static let logFile: URL = OSLog.writer.logFile

    public static func entries() throws -> [OSLogEntry] {
        let content = try String(contentsOf: logFile)
        var rows: [String] = content.components(separatedBy: "\n")
        // Drop Header
        _ = rows.dropFirst()

        let cvs = rows.map { $0.components(separatedBy: ",") }
        return []
    }
}
