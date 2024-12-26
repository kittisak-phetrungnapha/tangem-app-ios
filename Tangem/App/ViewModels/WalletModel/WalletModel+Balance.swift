//
//  WalletModel+Balance.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

// MARK: - BalanceState

extension WalletModel {
    /// Simple flag to check exactly BSDK balance
    var balanceState: BalanceState? {
        switch wallet.amounts[amountType]?.value {
        case .none: .none
        case .zero: .zero
        case .some: .positive
        }
    }

    enum BalanceState {
        case zero
        case positive
    }
}

extension WalletModel {
    // MARK: - Crypto

    var availableBalanceProvider: TokenBalanceProvider {
        AvailableBalanceProvider(walletModel: self)
    }

    var stakingBalanceProvider: TokenBalanceProvider {
        StakingBalanceProvider(walletModel: self)
    }

    var combineBalanceProvider: TokenBalanceProvider {
        CombineBalanceProvider(
            walletModel: self,
            availableBalanceProvider: availableBalanceProvider,
            stakingBalanceProvider: stakingBalanceProvider
        )
    }

    // MARK: - Fiat

    var availableFiatBalanceProvider: TokenBalanceProvider {
        FiatBalanceProvider(walletModel: self, cryptoBalanceProvider: availableBalanceProvider)
    }

    var stakingFiatBalanceProvider: TokenBalanceProvider {
        FiatBalanceProvider(walletModel: self, cryptoBalanceProvider: stakingBalanceProvider)
    }

    var combineFiatBalanceProvider: TokenBalanceProvider {
        FiatBalanceProvider(walletModel: self, cryptoBalanceProvider: combineBalanceProvider)
    }
}

extension WalletModel {
    struct BalanceFormatted: Hashable {
        let crypto, fiat: String
    }
}
