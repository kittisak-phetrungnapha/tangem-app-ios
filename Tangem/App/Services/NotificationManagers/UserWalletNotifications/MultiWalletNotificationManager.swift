//
//  MultiWalletNotificationManager.swift
//  Tangem
//
//  Created by Andrew Son on 06/09/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class MultiWalletNotificationManager {
    private let analyticsService = NotificationsAnalyticsService()
//    private let walletModelsManager: WalletModelsManager
    private let totalBalanceProvider: TotalBalanceProviding

    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])
    private var updateSubscription: AnyCancellable?

    init(totalBalanceProvider: TotalBalanceProviding, contextDataProvider: AnalyticsContextDataProvider?) {
        self.totalBalanceProvider = totalBalanceProvider

        analyticsService.setup(with: self, contextDataProvider: contextDataProvider)
        bind()
    }

    private func bind() {
        updateSubscription = totalBalanceProvider
            .totalBalancePublisher
            .withWeakCaptureOf(self)
            .sink { manager, state in
                manager.setup(state: state)
            }

        // TODO: Use total balance publisher with failure case checking
//        updateSubscription = walletModelsManager.walletModelsPublisher
//            .removeDuplicates()
//            .flatMap { walletModels in
//                let coinsOnlyModels = walletModels.filter { !$0.tokenItem.isToken }
//                return Publishers.MergeMany(coinsOnlyModels.map { $0.walletDidChangePublisher })
//                    .map { _ in coinsOnlyModels }
//                    .filter { walletModels in
//                        walletModels.allConforms { !$0.state.isLoading }
//                    }
//            }
//            .sink { [weak self] walletModels in
//                let unreachableNetworks = walletModels.filter {
//                    if case .binance = $0.blockchainNetwork.blockchain {
//                        return false
//                    }
//
//                    return $0.state.isBlockchainUnreachable
//                }
//
//                guard !unreachableNetworks.isEmpty else {
//                    self?.removeSomeNetworksUnreachable()
//                    return
//                }
//
//                self?.setupSomeNetworksUnreachable(unreachableNetworks)
//            }
    }

    private func setup(state: TotalBalanceState) {
        switch state {
        case .failed(cached: .some(let cached), _):
            // TODO: Show cached
            removeSomeNetworksUnreachable()
        case .failed(cached: .none, let unreachableNetworks):
            setupSomeNetworksUnreachable(unreachableNetworks)
        case .empty:
            removeSomeNetworksUnreachable()
        case .loading(cached: let cached):
            break
        case .loaded(balance: let balance, currencyCode: let currencyCode):
            removeSomeNetworksUnreachable()
        }
    }

    private func removeSomeNetworksUnreachable() {
        notificationInputsSubject.value.removeAll {
            guard let event = $0.settings.event as? TokenNotificationEvent else {
                return false
            }
            switch event {
            case .someNetworksUnreachable: return true
            default: return false
            }
        }
    }

    private func setupSomeNetworksUnreachable(_ unreachableNetworks: [TokenItem]) {
        let factory = NotificationsFactory()
        notificationInputsSubject.send(
            [
                factory.buildNotificationInput(
                    for: TokenNotificationEvent.someNetworksUnreachable(
                        currencySymbols: unreachableNetworks.map(\.currencySymbol)
                    )
                ),
            ]
        )
    }
}

extension MultiWalletNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {}

    func dismissNotification(with id: NotificationViewId) {
        notificationInputsSubject.value.removeAll(where: { $0.id == id })
    }
}
