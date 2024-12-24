//
//  DefaultTokenItemInfoProvider.swift
//  Tangem
//
//  Created by Andrew Son on 11/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class DefaultTokenItemInfoProvider {
    private let walletModel: WalletModel
    private let balanceProvider: TokenBalanceProvider
    private let fiatBalanceProvider: TokenBalanceProvider

    init(walletModel: WalletModel) {
        self.walletModel = walletModel

        balanceProvider = TotalTokenBalanceProvider(walletModel: walletModel)
        fiatBalanceProvider = FiatBalanceProvider(walletModel: walletModel, cryptoBalanceProvider: balanceProvider)
    }
}

extension DefaultTokenItemInfoProvider: TokenItemInfoProvider {
    var id: Int { walletModel.id }

    var tokenItem: TokenItem { walletModel.tokenItem }

    var hasPendingTransactions: Bool { walletModel.hasPendingTransactions }

    var quote: TokenQuote? { walletModel.quote }

    var isZeroBalanceValue: Bool {
        balanceProvider.balanceType.value ?? 0 > 0
    }

    var tokenItemState: TokenItemViewState {
        TokenItemViewState(walletModel: walletModel)
    }

    var tokenItemStatePublisher: AnyPublisher<TokenItemViewState, Never> {
        walletModel.walletDidChangePublisher
            .withWeakCaptureOf(self)
            .map { provider, _ in
                TokenItemViewState(walletModel: provider.walletModel)
            }
            .eraseToAnyPublisher()
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        balanceProvider.balanceTypePublisher
    }

    var fiatBalanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        fiatBalanceProvider.balanceTypePublisher
    }

    var actionsUpdatePublisher: AnyPublisher<Void, Never> { walletModel.actionsUpdatePublisher }

    var isStakedPublisher: AnyPublisher<Bool, Never> {
        walletModel.stakingManagerStatePublisher
            .filter { $0 != .loading }
            .map { state in
                switch state {
                case .staked: true
                case .loading, .availableToStake, .notEnabled, .temporaryUnavailable, .loadingError: false
                }
            }
            .eraseToAnyPublisher()
    }
}
