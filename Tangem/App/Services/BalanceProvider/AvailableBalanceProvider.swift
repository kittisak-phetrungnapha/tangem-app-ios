//
//  AvailableBalanceProvider.swift
//  TangemApp
//
//  Created by Sergey Balashov on 24.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemFoundation

/// Just simple available to use (e.g. send) balance
struct AvailableBalanceProvider {
    private let walletModel: WalletModel
    private var tokenItem: TokenItem { walletModel.tokenItem }

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }
}

// MARK: - AvailableBalanceProvider

extension AvailableBalanceProvider: BalanceProvider {
    var balance: TokenBalanceType? {
        mapToAvailableTokenBalanceType(state: walletModel.state)
    }

    var balancePublisher: AnyValuePublisher<TokenBalanceType?> {
        walletModel.statePublisher
            .map { self.mapToAvailableTokenBalanceType(state: $0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension AvailableBalanceProvider {
    func mapToAvailableTokenBalanceType(state: WalletModel.State) -> TokenBalanceType? {
        switch state {
        case .loading:
            return .loading(cached: nil)
        case .loaded(let balance):
            return .loaded(balance: balance)
        case .created:
            return .cached(balance: nil)
        case .noAccount:
            return .loaded(balance: .noAccount(tokenItem: tokenItem))
        case .failed(error: let error):
            return .failure(cached: nil)
        case .noDerivation:
            return nil
        }
    }
}
