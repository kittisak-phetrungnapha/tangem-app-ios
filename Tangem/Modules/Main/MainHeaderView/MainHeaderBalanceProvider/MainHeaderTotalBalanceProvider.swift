//
//  MainHeaderTotalBalanceProvider.swift
//  Tangem
//
//  Created by Andrew Son on 09/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol MainHeaderBalanceProvider {
    var balanceProvider: AnyPublisher<LoadingResult<AttributedString?, Never>, Never> { get }
}

class CommonMainHeaderBalanceProvider {
    private let totalBalanceProvider: TotalBalanceProviding
    private let userWalletStateInfoProvider: MainHeaderUserWalletStateInfoProvider
    private let mainBalanceFormatter: MainHeaderBalanceFormatter

    private let headerBalanceSubject = CurrentValueSubject<LoadingResult<AttributedString?, Never>, Never>(.loading)
    private var balanceSubscription: AnyCancellable?

    init(
        totalBalanceProvider: TotalBalanceProviding,
        userWalletStateInfoProvider: MainHeaderUserWalletStateInfoProvider,
        mainBalanceFormatter: MainHeaderBalanceFormatter
    ) {
        self.totalBalanceProvider = totalBalanceProvider
        self.userWalletStateInfoProvider = userWalletStateInfoProvider
        self.mainBalanceFormatter = mainBalanceFormatter

        bind()
    }

    private func bind() {
        balanceSubscription = totalBalanceProvider
            .totalBalancePublisher
            .sink(receiveValue: { [weak self] newValue in
                guard let self else {
                    return
                }

                if userWalletStateInfoProvider.isUserWalletLocked {
                    return
                }

                switch newValue {
                case .empty, .failed(.none, _):
                    // We didn't show any error in header, so no need to specify error
                    headerBalanceSubject.send(.success(.none))
                case .loading:
                    headerBalanceSubject.send(.loading)
                case .loaded(let balance):
                    var balanceToFormat = balance
                    if userWalletStateInfoProvider.isTokensListEmpty {
                        balanceToFormat = 0
                    }

                    let formattedForMainBalance = mainBalanceFormatter.formatBalance(balance: balanceToFormat)
                    headerBalanceSubject.send(.success(formattedForMainBalance))
                case .failed(.some(let cached), _):
                    // TODO: Check it
                    let formattedForMainBalance = mainBalanceFormatter.formatBalance(balance: cached)
                    headerBalanceSubject.send(.success(formattedForMainBalance))
                }
            })
    }
}

// MARK: - MainHeaderBalanceProvider

extension CommonMainHeaderBalanceProvider: MainHeaderBalanceProvider {
    var balanceProvider: AnyPublisher<LoadingResult<AttributedString?, Never>, Never> {
        headerBalanceSubject.eraseToAnyPublisher()
    }
}
