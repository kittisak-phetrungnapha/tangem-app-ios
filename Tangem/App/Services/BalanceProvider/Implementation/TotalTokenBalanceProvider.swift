//
//  TotalTokenBalanceProvider.swift
//  TangemApp
//
//  Created by Sergey Balashov on 24.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemStaking

/// Total crypto balance (available+staking)
struct TotalTokenBalanceProvider {
    private let walletModel: WalletModel
    private let balanceFormatter = BalanceFormatter()

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }
}

// MARK: - TokenBalanceProvider

extension TotalTokenBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType {
        mapToAvailableTokenBalance(walletState: walletModel.state, stakingState: walletModel.stakingManagerState)
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        Publishers.CombineLatest(
            walletModel.statePublisher,
            walletModel.stakingManagerStatePublisher
        )
        .map { self.mapToAvailableTokenBalance(walletState: $0, stakingState: $1) }
        .eraseToAnyPublisher()
    }

    var formattedBalanceType: FormattedTokenBalanceType {
        mapToFormattedTokenBalanceType(type: balanceType)
    }

    var formattedBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        balanceTypePublisher
            .map { self.mapToFormattedTokenBalanceType(type: $0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension TotalTokenBalanceProvider {
    func mapToAvailableTokenBalance(walletState: WalletModel.State, stakingState: StakingManagerState) -> TokenBalanceType {
        switch (walletState, stakingState) {
        // Token doesn't support staking
        // Then only available balance
        case (.loaded(let balance), .notEnabled):
            return .loaded(balance)

        // Token support staking but don't have any stakes
        // Token support staking but it temporary unavailable
        // Then only available balance
        case (.loaded(let balance), .availableToStake),
             (.loaded(let balance), .temporaryUnavailable):
            return .loaded(balance)

        // One on them have error
        // Then show cached with error
        case (.failed, _), (_, .loadingError):
            return .failure(nil)

        // Both was loaded
        // Then show the sum of both
        case (.loaded(let balance), .staked(let balances)):
            let staked = balances.balances.blocked().sum()
            return .loaded(balance + staked)

        // Token hasn't account
        // Then show the zero of both
        case (.noAccount, _):
            return .noAccount

        // One on them is loading
        case (.loading, _), (_, .loading):
            return .loading(nil)

        // No balances cases
        case (.created, _), (.noDerivation, _):
            return .empty(.noData)
        }
    }

    func mapToFormattedTokenBalanceType(type: TokenBalanceType) -> FormattedTokenBalanceType {
        let builder = FormattedTokenBalanceTypeBuilder(format: { value in
            balanceFormatter.formatCryptoBalance(value, currencyCode: walletModel.tokenItem.currencySymbol)
        })

        return builder.mapToFormattedTokenBalanceType(type: type)
    }
}
