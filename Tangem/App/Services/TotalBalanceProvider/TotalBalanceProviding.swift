//
//  TotalBalanceProviding.swift
//  Tangem
//
//  Created by Sergey Balashov on 16.09.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import Foundation

protocol TotalBalanceProviding {
    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> { get }
}

// MARK: - TotalBalanceState

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
