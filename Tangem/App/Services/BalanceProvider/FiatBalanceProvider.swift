//
//  FiatBalanceProvider.swift
//  TangemApp
//
//  Created by Sergey Balashov on 24.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemStaking

/// Just simple available to use (e.g. send) balance
struct FiatBalanceProvider {
    private let cryptoBalanceProvider: BalanceProvider
    private let currencyId: String?

    private let converter = BalanceConverter()

    init(cryptoBalanceProvider: BalanceProvider, currencyId: String?) {
        self.cryptoBalanceProvider = cryptoBalanceProvider
        self.currencyId = currencyId
    }
}

// MARK: - AvailableBalanceProvider

extension FiatBalanceProvider: BalanceProvider {
    var balance: TokenBalanceType? {
        mapToTokenBalanceType(balanceType: cryptoBalanceProvider.balance)
    }

    var balancePublisher: AnyValuePublisher<TokenBalanceType?> {
        cryptoBalanceProvider.balancePublisher
            .map { self.mapToTokenBalanceType(balanceType: $0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

extension FiatBalanceProvider {
    func mapToTokenBalanceType(balanceType: TokenBalanceType?) -> TokenBalanceType? {
        guard let balance = balanceType?.balance,
              let currencyId = currencyId,
              let fiat = converter.convertToFiat(balance.balance, currencyId: currencyId) else {
            return nil
        }

        switch balanceType {
        case .none: return .none
        case .cached(let balance):
            return .cached(balance: balance.map { $0.updated(balance: fiat) })
        case .loading(let balance):
            return .loading(cached: balance.map { $0.updated(balance: fiat) })
        case .failure(let balance):
            return .failure(cached: balance.map { $0.updated(balance: fiat) })
        case .loaded(let balance):
            return .loaded(balance: balance.updated(balance: fiat))
        }
    }
}
