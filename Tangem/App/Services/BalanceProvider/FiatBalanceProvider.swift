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

/// a.k.a Fiat converter
struct FiatBalanceProvider {
    private let walletModel: WalletModel
    private let cryptoBalanceProvider: TokenBalanceProvider

    private var currencyId: String? { walletModel.tokenItem.currencyId }
    private let converter = BalanceConverter()

    init(walletModel: WalletModel, cryptoBalanceProvider: TokenBalanceProvider) {
        self.walletModel = walletModel
        self.cryptoBalanceProvider = cryptoBalanceProvider
    }
}

// MARK: - TokenBalanceProvider

extension FiatBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType? {
        mapToTokenBalanceType(balanceType: cryptoBalanceProvider.balanceType)
    }

    var balanceTypePublisher: AnyValuePublisher<TokenBalanceType?> {
        Publishers.CombineLatest(
            // Listen if rate was loaded after main balance
            walletModel.ratePublisher.removeDuplicates(),
            cryptoBalanceProvider.balanceTypePublisher
        )
        .map { self.mapToTokenBalanceType(balanceType: $1) }
        .eraseToAnyPublisher()
    }
}

// MARK: - Private

extension FiatBalanceProvider {
    func mapToTokenBalanceType(balanceType: TokenBalanceType?) -> TokenBalanceType? {
        guard let balance = balanceType?.balance,
              let currencyId = currencyId,
              let fiat = converter.convertToFiat(balance.value, currencyId: currencyId) else {
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
