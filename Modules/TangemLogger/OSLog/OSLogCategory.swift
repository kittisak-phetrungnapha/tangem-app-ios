//
//  OSLogCategory.swift
//  TangemModules
//
//  Created by Sergey Balashov on 23.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public enum OSLogCategory: Hashable {
    case network
    case express
    case visa
    case staking
    case token
    case tangemSDK
    case blockchainSDK
    case logFileWriter
    case custom(String)

    var name: String {
        switch self {
        case .network: "Network"
        case .express: "Express"
        case .visa: "Visa"
        case .staking: "Staking"
        case .token: "Token"
        case .tangemSDK: "TangemSDK"
        case .blockchainSDK: "BlockchainSDK"
        case .logFileWriter: "LogFileWriter"
        case .custom(let string): "\(string)"
        }
    }
}
