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
    var balanceType: TokenBalanceType {
        mapToTokenBalance(balanceType: cryptoBalanceProvider.balanceType)
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        Publishers.CombineLatest(
            // Listen if rate was loaded after main balance
            walletModel.ratePublisher.removeDuplicates(),
            cryptoBalanceProvider.balanceTypePublisher
        )
        .map { self.mapToTokenBalance(balanceType: $1) }
        .eraseToAnyPublisher()
    }
}

// MARK: - Private

extension FiatBalanceProvider {
    func mapToTokenBalance(balanceType: TokenBalanceType) -> TokenBalanceType {
        guard let balance = balanceType.value,
              let currencyId = currencyId,
              let fiat = converter.convertToFiat(balance, currencyId: currencyId) else {
            return .empty
        }

        switch balanceType {
        case .empty:
            return .empty
        case .loading:
            return .loading(fiat)
        case .failure(let cached):
            return .failure(cached.flatMap { .init(balance: fiat, date: $0.date) })
        case .loaded:
            return .loaded(fiat)
        }
    }
}
