//
//  TotalBalanceProvider.swift
//  Tangem
//
//  Created by Sergey Balashov on 16.09.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import BlockchainSdk

class TotalBalanceProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let userWalletId: UserWalletId
    private let walletModelsManager: WalletModelsManager
    private let derivationManager: DerivationManager?

    private let totalBalanceSubject = CurrentValueSubject<TotalBalanceState, Never>(.empty)

    private var walletModelsSubscription: AnyCancellable?
    private var updateSubscription: AnyCancellable?

    init(
        userWalletId: UserWalletId,
        walletModelsManager: WalletModelsManager,
        derivationManager: DerivationManager?
    ) {
        self.userWalletId = userWalletId
        self.walletModelsManager = walletModelsManager
        self.derivationManager = derivationManager

        bind()
    }
}

// MARK: - TotalBalanceProviding protocol conformance

extension TotalBalanceProvider: TotalBalanceProviding {
    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> {
        totalBalanceSubject.eraseToAnyPublisher()
    }
}

// MARK: - Private implementation

private extension TotalBalanceProvider {
    func bind() {
        let hasEntriesWithoutDerivationPublisher = derivationManager?.hasPendingDerivations ?? .just(output: false)

        // Subscription to handle token changes
        walletModelsSubscription = walletModelsManager
            .walletModelsPublisher
            .combineLatest(
                AppSettings.shared.$selectedCurrencyCode.delay(for: 0.3, scheduler: DispatchQueue.main),
                hasEntriesWithoutDerivationPublisher
            )
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { balanceProvider, input in
                let (walletModels, currencyCode, hasEntriesWithoutDerivation) = input
                balanceProvider.contextDidChange(
                    walletModels: walletModels, currencyCode: currencyCode, hasEntriesWithoutDerivation: hasEntriesWithoutDerivation
                )
//
//                balanceProvider.updateSubscription = nil
//
//                if !walletModels.isEmpty {
//                    balanceProvider.subscribeToUpdates(
//                        walletModels: walletModels,
//                        hasEntriesWithoutDerivation: hasEntriesWithoutDerivation
//                    )
//                }
//
//                let hasLoadingWalletModels = walletModels.contains { $0.isLoading }
//
//                // We should wait for balance loading to complete
//                if hasLoadingWalletModels {
//                    balanceProvider.totalBalanceSubject.send(.loading)
//                    return
//                }
//
//                balanceProvider.updateTotalBalance(
//                    withCurrencyCode: currencyCode,
//                    walletModels: walletModels,
//                    hasEntriesWithoutDerivation: hasEntriesWithoutDerivation
//                )
            }
    }

    // Listen any wallet models count / app's currency code change / or has entries without derivation
    func contextDidChange(walletModels: [WalletModel], currencyCode: String, hasEntriesWithoutDerivation: Bool) {
        // Clear previous
        updateSubscription = nil

        trackTokenBalanceLoaded(walletModels: walletModels)

        let providers = walletModels.map {
            let cryptoBalanceProvider = TotalTokenBalanceProvider(walletModel: $0)
            return FiatBalanceProvider(walletModel: $0, cryptoBalanceProvider: cryptoBalanceProvider)
        }

        if !providers.isEmpty {
            // Setup updating listener
            subscribeToUpdates(
                providers: providers,
                currencyCode: currencyCode,
                hasEntriesWithoutDerivation: hasEntriesWithoutDerivation
            )
        }

        // Update with data which already have
        updateTotalBalance(
            balances: providers.map { $0.balanceType
            },
            currencyCode: currencyCode,
            hasEntriesWithoutDerivation: hasEntriesWithoutDerivation
        )
    }

    func subscribeToUpdates(providers: [TokenBalanceProvider], currencyCode: String, hasEntriesWithoutDerivation: Bool) {
        // Subscription to handle balance loading completion
        updateSubscription = providers
            .map { $0.balanceTypePublisher }
            .merge()
            .mapToValue(providers)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { balanceProvider, providers in
                let balances = providers.map { $0.balanceType }
                balanceProvider.updateTotalBalance(
                    balances: balances,
                    currencyCode: currencyCode,
                    hasEntriesWithoutDerivation: hasEntriesWithoutDerivation
                )
            }
    }

    func updateTotalBalance(balances: [TokenBalanceType], currencyCode: String, hasEntriesWithoutDerivation: Bool) {
        let state = mapToTotalBalance(balances: balances, currencyCode: currencyCode, hasEntriesWithoutDerivation: hasEntriesWithoutDerivation)
        totalBalanceSubject.send(state)
    }

    func mapToTotalBalance(balances: [TokenBalanceType], currencyCode: String, hasEntriesWithoutDerivation: Bool) -> TotalBalanceState {
        if balances.isEmpty {
            return .loaded(balance: 0, currencyCode: currencyCode)
        }

        AppLog.shared.debug("balances ->> \(balances)")

        let cachedBalance = cachedBalance(balances: balances)
        let hasLoading = balances.contains { $0.isLoading }

        if hasLoading {
            // Show it in loading state if only one is in loading process
            return .loading(cached: cachedBalance)
        }

        // Show empty only when all balances is loaded
        if hasEntriesWithoutDerivation {
            return .empty
        }

        let hasError = balances.contains { $0.isFailure }
        if hasError {
            // If has error and cached balance show failed state with cached balances
            // Otherwise just show `empty`
            return cachedBalance.map { .failed(cached: $0) } ?? .empty
        }

        guard let loadedBalance = loadedBalance(balances: balances) else {
            // some tokens don't have balance
            return .empty
        }

        // It is also empty when derivation is missing
        if !hasEntriesWithoutDerivation {
            Analytics.logTopUpIfNeeded(balance: loadedBalance, for: userWalletId)
        }

        let hasCustomToken = balances.contains { $0.isEmpty(for: .custom) }
        let parameterValue = mapToBalanceParameterValue(
            hasBlockchainBalanceLoadingError: hasError,
            emptyRatesBecauseCustomToken: hasCustomToken,
            balance: loadedBalance
        )

        Analytics.log(
            event: .balanceLoaded,
            params: [
                .balance: parameterValue.rawValue,
                .tokensCount: String(balances.count),
            ],
            limit: .userWalletSession(userWalletId: userWalletId)
        )

        return .loaded(balance: loadedBalance, currencyCode: currencyCode)
    }

    func trackTokenBalanceLoaded(walletModels: [WalletModel]) {
        let mainCoinModels = walletModels.filter { $0.isMainToken }
        let trackedModels = mainCoinModels.filter {
            switch $0.blockchainNetwork.blockchain {
            case .polkadot, .kusama, .azero:
                return true
            default:
                return false
            }
        }

        for trackedModel in trackedModels {
            let positiveBalance = trackedModel.balanceState == .positive

            Analytics.log(
                event: .tokenBalanceLoaded,
                params: [
                    .token: trackedModel.blockchainNetwork.blockchain.currencySymbol,
                    .state: positiveBalance ? Analytics.ParameterValue.full.rawValue : Analytics.ParameterValue.empty.rawValue,
                ],
                limit: .userWalletSession(userWalletId: userWalletId, extraEventId: trackedModel.blockchainNetwork.blockchain.currencySymbol)
            )
        }
    }

    func loadedBalance(balances: [TokenBalanceType]) -> Decimal? {
        let loadedBalance = balances.compactMap { balance in
            switch balance {
            case .loaded(let balance):
                return balance
            // If we don't balance because custom token don't have rates
            // Just calculate it as `.zero`
            case .empty(.custom):
                return .zero
            default:
                assertionFailure("Balance not found \(balance)")
                return nil
            }
        }

        return loadedBalance.reduce(0, +)
    }

    func cachedBalance(balances: [TokenBalanceType]) -> TokenBalanceType.Cached? {
        //        var balance: Decimal? = nil
        //        var allHasCached: Bool = false
        //        var date: Date?

        let cachedBalance = balances.compactMap { balanceType in
            switch balanceType {
            case .loading(.some(let cached)), .failure(.some(let cached)):
                return cached
            default:
                return nil
            }
        }

        // All has cached balances
        guard balances.count == cachedBalance.count,
              let date = cachedBalance.first?.date else {
            return nil
        }

        return .init(balance: cachedBalance.reduce(0) { $0 + $1.balance }, date: date)
    }

//        balance = cachedBalance.reduce(0, { $0 + $1.balance })
//        allHasCached = balances.count == cachedBalance.count
//        date = cachedBalance.first?.date

//        for balanceType in balances {
//            switch balanceType {
//            case .loading(.some(let cached)), .failure(.some(let cached)):
//                balance = (balance ?? 0) + cached.balance
//                allHasCached = true
//                date = cached.date
//            default:
//                balance = nil
//                allHasCached = false
//                date = nil

    // Stop the cycle when only one don't have cached balance
//                return (balance: balance, all: allHasCached, date: date)
//            }
//        }
//
//        return (balance: balance, all: allHasCached, date: date)
//    }

//    func updateTotalBalance(
//        withCurrencyCode currencyCode: String,
//        walletModels: [WalletModel],
//        hasEntriesWithoutDerivation: Bool
//    ) {
//        if hasEntriesWithoutDerivation {
//            totalBalanceSubject.send(.loaded(.init(balance: nil, currencyCode: currencyCode, allTokensBalancesIncluded: false)))
//            return
//        }
//
//        let totalBalance = mapToTotalBalance(
//            currencyCode: currencyCode,
//            walletModels: walletModels,
//            hasEntriesWithoutDerivation: hasEntriesWithoutDerivation
//        )
//        totalBalanceSubject.send(.loaded(totalBalance))
//    }

//    func mapToTotalBalance(
//        currencyCode: String,
//        walletModels: [WalletModel],
//        hasEntriesWithoutDerivation: Bool
//    ) -> TotalBalance {
//        var hasError = false
//        var balance: Decimal?
//        var hasCryptoError = false
//        var allTokensBalancesIncluded = true
//
//        for token in walletModels {
//            if case .binance = token.blockchainNetwork.blockchain {
//                // case with single bnb token
//                if balance == nil {
//                    balance = 0
//                }
//
//                continue
//            }
//
//            if case .failed = token.state {
//                hasCryptoError = true
//            }
//
//            if !token.isSuccessfullyLoaded {
//                balance = nil
//                break
//            }
//
//            let currentValue = balance ?? 0
//            let allBalance = token.totalBalance
//            balance = currentValue + (allBalance.fiat ?? 0)
//            if allBalance.fiat == nil, !token.isCustom {
//                allTokensBalancesIncluded = false
//            }
//
//            if token.rateFormatted.isEmpty {
//                // Just show warning for custom tokens
//                if token.isCustom {
//                    hasError = true
//                } else {
//                    balance = nil
//                    break
//                }
//            }
//        }
//
//        // It is also empty when derivation is missing
//        if let balance, !hasEntriesWithoutDerivation {
//            Analytics.logTopUpIfNeeded(balance: balance, for: userWalletId)
//        }
//
//        Analytics.log(
//            event: .balanceLoaded,
//            params: [
//                .balance: mapToBalanceParameterValue(
//                    hasCryptoError: hasCryptoError,
//                    hasError: hasError,
//                    balance: balance
//                ).rawValue,
//                .tokensCount: String(walletModels.count),
//            ],
//            limit: .userWalletSession(userWalletId: userWalletId)
//        )
//
//        let mainCoinModels = walletModels.filter { $0.isMainToken }
//        let trackedModels = mainCoinModels.filter {
//            switch $0.blockchainNetwork.blockchain {
//            case .polkadot, .kusama, .azero:
//                return true
//            default:
//                return false
//            }
//        }
//
//        for trackedModel in trackedModels {
//            let positiveBalance = trackedModel.balanceState == .positive
//
//            Analytics.log(
//                event:
//                .tokenBalanceLoaded,
//                params: [
//                    .token: trackedModel.blockchainNetwork.blockchain.currencySymbol,
//                    .state: positiveBalance ? Analytics.ParameterValue.full.rawValue : Analytics.ParameterValue.empty.rawValue,
//                ],
//                limit: .userWalletSession(userWalletId: userWalletId, extraEventId: trackedModel.blockchainNetwork.blockchain.currencySymbol)
//            )
//        }
//
//        return TotalBalance(
//            balance: balance,
//            currencyCode: currencyCode,
    ////            hasError: hasError,
//            allTokensBalancesIncluded: allTokensBalancesIncluded
//        )
//    }

    private func mapToBalanceParameterValue(
        hasBlockchainBalanceLoadingError: Bool,
        emptyRatesBecauseCustomToken: Bool,
        balance: Decimal?
    ) -> Analytics.ParameterValue {
        if hasBlockchainBalanceLoadingError {
            return .blockchainError
        }

        if emptyRatesBecauseCustomToken {
            return .customToken
        }

        if let balance {
            return balance > .zero ? .full : .empty
        }

        return .noRate
    }
}

enum TotalBalanceState: Hashable {
    case empty
    case loading(cached: TokenBalanceType.Cached?)
    case failed(cached: TokenBalanceType.Cached?)
    case loaded(balance: Decimal, currencyCode: String)

    var isLoading: Bool {
        switch self {
        case .loading: true
        default: false
        }
    }

    var balance: Decimal? {
        switch self {
        case .loaded(let balance, _): balance
        default: nil
        }
    }
}

private extension TokenBalanceType {
    func isEmpty(for reason: EmptyReason) -> Bool {
        switch self {
        case .empty(let emptyReason): emptyReason == reason
        default: false
        }
    }
}
