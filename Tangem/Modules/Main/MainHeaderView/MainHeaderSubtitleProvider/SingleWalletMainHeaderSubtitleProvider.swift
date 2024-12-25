//
//  SingleWalletMainHeaderSubtitleProvider.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SingleWalletMainHeaderSubtitleDataSource: AnyObject {
    var walletDidChangePublisher: AnyPublisher<WalletModel.State, Never> { get }
    var balance: String { get }
}

class SingleWalletMainHeaderSubtitleProvider: MainHeaderSubtitleProvider {
    private let subject: CurrentValueSubject<MainHeaderSubtitleInfo, Never> = .init(.empty)
    private let isLoadingSubject: CurrentValueSubject<Bool, Never>
    private let isUserWalletLocked: Bool
    private let tokenItem: TokenItem?
    private let balanceProvider: TokenBalanceProvider?

    private var stateUpdateSubscription: AnyCancellable?

    var subtitlePublisher: AnyPublisher<MainHeaderSubtitleInfo, Never> {
        subject.eraseToAnyPublisher()
    }

    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        isLoadingSubject.eraseToAnyPublisher()
    }

    var containsSensitiveInfo: Bool { true }

    init(isUserWalletLocked: Bool, walletModel: WalletModel?) {
        self.isUserWalletLocked = isUserWalletLocked

        tokenItem = walletModel?.tokenItem
        balanceProvider = walletModel.map { $0.combineBalanceProvider }
        isLoadingSubject = .init(!isUserWalletLocked)

        initialSetup()
    }

    private func initialSetup() {
        if isUserWalletLocked {
            displayLockedWalletMessage()
        } else {
            bind()
        }
    }

    private func bind() {
        stateUpdateSubscription = balanceProvider?
            .balanceTypePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] type in
                self?.setupBalance(type: type)
            })
    }

    private func setupBalance(type: TokenBalanceType) {
        isLoadingSubject.send(false)

        switch type {
        case .empty, .failure(.none):
            formatErrorMessage()
        case .loading(let decimal):
            break
        case .failure(.some(let cached)):
            break // TODO: Cached (?)
        case .loaded(let value):
            guard let tokenItem else {
                formatErrorMessage()
                return
            }

            let formatted = BalanceFormatter().formatCryptoBalance(value, currencyCode: tokenItem.currencySymbol)
            formatBalanceMessage(balance: formatted)
        }
    }

    private func formatBalanceMessage(balance: String) {
        subject.send(.init(messages: [balance], formattingOption: .default))
    }

    private func formatErrorMessage() {
        subject.send(.init(messages: [BalanceFormatter.defaultEmptyBalanceString], formattingOption: .default))
    }

    private func displayLockedWalletMessage() {
        subject.send(.init(messages: [Localization.commonLocked], formattingOption: .default))
    }
}
