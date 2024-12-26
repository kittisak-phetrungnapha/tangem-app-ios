//
//  BalanceWithButtonsViewModelBalanceProvider.swift
//  TangemApp
//
//  Created by Sergey Balashov on 26.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

protocol BalanceWithButtonsViewModelBalanceProvider {
    var totalCryptoBalancePublisher: AnyPublisher<BalanceWithButtonsViewModel.BalanceResult, Never> { get }
    var totalFiatBalancePublisher: AnyPublisher<BalanceWithButtonsViewModel.BalanceResult, Never> { get }

    var availableCryptoBalancePublisher: AnyPublisher<BalanceWithButtonsViewModel.BalanceResult, Never> { get }
    var availableFiatBalancePublisher: AnyPublisher<BalanceWithButtonsViewModel.BalanceResult, Never> { get }
}
