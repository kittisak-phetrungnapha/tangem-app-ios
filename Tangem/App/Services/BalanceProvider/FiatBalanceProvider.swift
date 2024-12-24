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

    init(walletModel: WalletModel, cryptoBalanceProvider: TokenBalanceProvider) {
        self.walletModel = walletModel
        self.cryptoBalanceProvider = cryptoBalanceProvider
    }
}

// MARK: - TokenBalanceProvider

extension FiatBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType {
        mapToTokenBalance(rate: walletModel.rate, balanceType: cryptoBalanceProvider.balanceType)
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        Publishers.CombineLatest(
            // Listen if rate was loaded after main balance
            walletModel.ratePublisher.removeDuplicates(),
            cryptoBalanceProvider.balanceTypePublisher.removeDuplicates()
        )
        .map { self.mapToTokenBalance(rate: $0, balanceType: $1) }
        .eraseToAnyPublisher()
    }
}

// MARK: - Private

extension FiatBalanceProvider {
    func mapToTokenBalance(rate: LoadingResult<Decimal?, Never>, balanceType: TokenBalanceType) -> TokenBalanceType {
        guard let currencyId = walletModel.tokenItem.currencyId else {
            return .empty
        }

        switch (rate, balanceType) {
        // There is no one value (no rate or no crypto balance to show)
        case (_, .empty), (.success(.none), _), (_, .failure(.none)):
            return .empty

        // There is one value is loading
        case (_, .loading), (.loading, _):
            return .loading(nil) // TODO: Add cache

        // Has some rate but only cached value
        case (.success(.some(let rate)), .failure(.some(let cached))):
            let fiat = cached.balance * rate
            return .failure(.init(balance: fiat, date: cached.date))

        // Has some rate and some value
        case (.success(.some(let rate)), .loaded(let value)):
            let fiat = value * rate
            return .loaded(fiat)
        }
    }
}
