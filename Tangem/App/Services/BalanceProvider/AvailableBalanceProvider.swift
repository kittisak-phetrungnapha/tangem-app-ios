//
//  AvailableBalanceProvider.swift
//  TangemApp
//
//  Created by Sergey Balashov on 24.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Just simple available to use (e.g. send) balance
struct AvailableBalanceProvider {
    private let walletModel: WalletModel
    private var tokenItem: TokenItem { walletModel.tokenItem }

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }
}

// MARK: - TokenBalanceProvider

extension AvailableBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType {
        mapToAvailableTokenBalance(state: walletModel.state)
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        walletModel.statePublisher
            .map { self.mapToAvailableTokenBalance(state: $0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension AvailableBalanceProvider {
    func mapToAvailableTokenBalance(state: WalletModel.State) -> TokenBalanceType {
        switch state {
        case .loading:
            return .loading(nil)
        case .loaded(let balance):
            return .loaded(balance)
        case .created:
            return .empty
        case .noAccount:
            return .noAccount
        case .failed:
            return .failure(nil)
        case .noDerivation:
            return .empty
        }
    }
}
