//
//  HederaAccountBalance.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 06.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct HederaAccountBalance {
    struct TokenBalanceType {
        let contractAddress: String
        /// In atomic units.
        let balance: Int
        let decimalCount: Int
    }

    /// In atomic units (i.e. Tinybars).
    let hbarBalance: Int
    let tokenBalances: [TokenBalanceType]
}
