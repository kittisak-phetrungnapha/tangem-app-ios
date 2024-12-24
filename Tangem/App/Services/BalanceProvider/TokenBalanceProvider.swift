//
//  TokenBalanceProvider.swift
//  TangemApp
//
//  Created by Sergey Balashov on 24.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemStaking

/// Just simple available to use (e.g. send) balance
struct TokenBalanceProvider {
    private let walletModel: WalletModel
    private var tokenItem: TokenItem { walletModel.tokenItem }

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }
}

// MARK: - AvailableBalanceProvider

extension TokenBalanceProvider: BalanceProvider {
    var balance: TokenBalanceType? {
        mapToAvailableTokenBalanceType(walletState: walletModel.state, stakingState: walletModel.stakingManagerState)
    }

    var balancePublisher: AnyValuePublisher<TokenBalanceType?> {
        Publishers.CombineLatest(
            walletModel.statePublisher,
            walletModel.stakingManagerStatePublisher
        )

        .map { self.mapToAvailableTokenBalanceType(walletState: $0, stakingState: $1) }
        .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension TokenBalanceProvider {
    func mapToAvailableTokenBalanceType(walletState: WalletModel.State, stakingState: StakingManagerState) -> TokenBalanceType? {
        switch (walletState, stakingState) {
        // Token doesn't support staking
        // Then only available balance
        case (.loaded(let balance), .notEnabled):
            return .loaded(balance: balance)

        // Token support staking but don't have any stakes
        // Token support staking but it temporary unavailable
        // Then only available balance
        case (.loaded(let balance), .availableToStake),
             (.loaded(let balance), .temporaryUnavailable):
            return .loaded(balance: balance)

        // One on them have error
        // Then show cached with error
        case (.failed(let error), _), (_, .loadingError(let error)):
            return .failure(cached: nil)

        // Both was loaded
        // Then show the sum of both
        case (.loaded(let balance), .staked(let balances)):
            let staked = balances.balances.blocked().sum()
            return .loaded(balance: balance)

        // Token hasn't account
        // Then show the zero of both
        case (.noAccount, _):
            return .loaded(balance: .noAccount(tokenItem: tokenItem))

        // One on them is loading
        case (.loading, _), (_, .loading):
            return .loading(cached: nil)

        // No balances cases
        case (.created, _), (.noDerivation, _):
            return nil
        }
    }
}
