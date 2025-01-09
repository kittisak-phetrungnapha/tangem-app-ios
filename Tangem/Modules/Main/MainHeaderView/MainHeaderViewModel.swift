//
//  MainHeaderViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 10/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class MainHeaderViewModel: ObservableObject {
    let isUserWalletLocked: Bool

    @Published private(set) var cardImage: ImageType?
    @Published private(set) var userWalletName: String = ""
    @Published private(set) var subtitleInfo: MainHeaderSubtitleInfo = .empty
    @Published private(set) var balance: LoadableTokenBalanceView.State = .loading()
    @Published var isLoadingSubtitle: Bool = true

    var subtitleContainsSensitiveInfo: Bool {
        subtitleProvider.containsSensitiveInfo
    }

    private weak var supplementInfoProvider: MainHeaderSupplementInfoProvider?
    private let subtitleProvider: MainHeaderSubtitleProvider
    private let balanceProvider: MainHeaderBalanceProvider

    private var bag: Set<AnyCancellable> = []

    init(
        isUserWalletLocked: Bool,
        supplementInfoProvider: MainHeaderSupplementInfoProvider,
        subtitleProvider: MainHeaderSubtitleProvider,
        balanceProvider: MainHeaderBalanceProvider
    ) {
        self.isUserWalletLocked = isUserWalletLocked

        self.supplementInfoProvider = supplementInfoProvider
        self.subtitleProvider = subtitleProvider
        self.balanceProvider = balanceProvider

        bind()
    }

    private func bind() {
        supplementInfoProvider?.userWalletNamePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.userWalletName, on: self, ownership: .weak)
            .store(in: &bag)

        supplementInfoProvider?.cardHeaderImagePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.cardImage, on: self, ownership: .weak)
            .store(in: &bag)

        subtitleProvider.isLoadingPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoadingSubtitle, on: self, ownership: .weak)
            .store(in: &bag)

        subtitleProvider.subtitlePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.subtitleInfo, on: self, ownership: .weak)
            .store(in: &bag)

        balanceProvider.balanceProvider
            .receive(on: DispatchQueue.main)
            // Hide skeleton and apply state with delay, mimic current behaviour
            .debounce(for: 0.2, scheduler: DispatchQueue.main)
            .sink { [weak self] totalBalance in
                AppLog.shared.debug("Wallet name: \(String(describing: self?.userWalletName)) set total balance to \(totalBalance)")
                self?.balance = totalBalance

//                switch newValue {
//                case .loading:
//                    isLoadingFiatBalance = true
//                case .success(.some(let totalBalance)):
//                    AppLog.shared.debug("Wallet name: \(userWalletName) set total balance to \(String(totalBalance.characters))")
//                    isLoadingFiatBalance = false
//                    balance = totalBalance
//
//                case .success(.none):
//                    AppLog.shared.debug("Wallet name: \(userWalletName) set total balance to empty string")
//                    isLoadingFiatBalance = false
//                    balance = .init(BalanceFormatter.defaultEmptyBalanceString)
//                }
            }
            .store(in: &bag)
    }
}
