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
    private let balanceProvider: TokenBalanceProvider?

    private var stateUpdateSubscription: AnyCancellable?

    var subtitlePublisher: AnyPublisher<MainHeaderSubtitleInfo, Never> {
        subject.eraseToAnyPublisher()
    }

    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        isLoadingSubject.eraseToAnyPublisher()
    }

    var containsSensitiveInfo: Bool { true }

    init(isUserWalletLocked: Bool, balanceProvider: TokenBalanceProvider?) {
        self.isUserWalletLocked = isUserWalletLocked
        self.balanceProvider = balanceProvider

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
            .formattedBalanceTypePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] type in
                self?.setupBalance(type: type)
            })
    }

    private func setupBalance(type: FormattedTokenBalanceType) {
        switch type {
        case .failure(.empty):
            formatErrorMessage()
        case .loading(.cache(let cached)):
            break // TODO: Cached is loading (?)
        case .failure(.cache(let cached)):
            break // TODO: Cached (?)
        case .loaded(let balance):
            isLoadingSubject.send(false)
            formatBalanceMessage(balance: balance)
        case .loading(.empty):
            break
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
