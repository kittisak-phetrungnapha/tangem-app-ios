//
//  BalanceWithButtonsViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 31/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class BalanceWithButtonsViewModel: ObservableObject, Identifiable {
    typealias BalanceResult = LoadingResult<String, Never>

    @Published var isLoadingBalance = true
    @Published var isLoadingFiatBalance = true

    @Published var cryptoBalance: LoadableTokenBalanceView.State = .loading()
    @Published var fiatBalance: LoadableTokenBalanceView.State = .loading()

    @Published var buttons: [FixedSizeButtonWithIconInfo] = []

    @Published var balanceTypeValues: [BalanceType]?
    @Published var selectedBalanceType: BalanceType = .all

    private let buttonsPublisher: AnyPublisher<[FixedSizeButtonWithIconInfo], Never>
    private let balanceProvider: BalanceWithButtonsViewModelBalanceProvider

    private let formatter = BalanceFormatter()
    private var bag = Set<AnyCancellable>()

    init(
        buttonsPublisher: AnyPublisher<[FixedSizeButtonWithIconInfo], Never>,
        balanceProvider: BalanceWithButtonsViewModelBalanceProvider
    ) {
        self.buttonsPublisher = buttonsPublisher
        self.balanceProvider = balanceProvider

        bind()
    }

    private func bind() {
        Publishers
            .CombineLatest3(
                balanceProvider.totalCryptoBalancePublisher,
                balanceProvider.availableCryptoBalancePublisher,
                $selectedBalanceType
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] all, available, type in
                self?.setupCryptoBalances(all: all, available: available, type: type)
            }
            .store(in: &bag)

        Publishers
            .CombineLatest3(
                balanceProvider.totalFiatBalancePublisher,
                balanceProvider.availableFiatBalancePublisher,
                $selectedBalanceType
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] all, available, type in
                self?.setupFiatBalances(all: all, available: available, type: type)
            }
            .store(in: &bag)

        buttonsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] buttons in
                self?.buttons = buttons
            }
            .store(in: &bag)
    }

    private func setupCryptoBalances(
        all: BalanceWithButtonsViewModel.BalanceResult,
        available: BalanceWithButtonsViewModel.BalanceResult,
        type: BalanceType
    ) {
        switch (all, available) {
        case (.loading, _), (_, .loading):
            // If one of them is loading then not choose
            // Do nothing to avoid jumping animations
            break

        case (.success(let all), .success(let available)):
            // If there's no difference if values is equal
            balanceTypeValues = all == available ? nil : BalanceType.allCases
            isLoadingBalance = false
            cryptoBalance = type == .all ? all : available
        }
    }

    private func setupFiatBalances(
        all: BalanceWithButtonsViewModel.BalanceResult,
        available: BalanceWithButtonsViewModel.BalanceResult,
        type: BalanceType
    ) {
        switch (all, available) {
        case (.loading, _), (_, .loading):
            // Do nothing to avoid jumping animations
            break

        case (.success(let all), .success(let available)):
            isLoadingFiatBalance = false
            let formatted = formatter.formatAttributedTotalBalance(
                fiatBalance: type == .all ? all : available
            )
            fiatBalance = .loaded(text: .attributed(formatted))
        }
    }
}

extension BalanceWithButtonsViewModel {
    enum BalanceType: String, CaseIterable, Hashable, Identifiable {
        case all
        case available

        var title: String {
            rawValue.capitalized
        }

        var id: String {
            rawValue
        }
    }
}
