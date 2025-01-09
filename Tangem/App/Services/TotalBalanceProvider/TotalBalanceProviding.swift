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
    case loading(cached: Decimal?)
    case failed(cached: Decimal?, failedItems: [TokenItem])
    case loaded(balance: Decimal)

    var isLoading: Bool {
        switch self {
        case .loading: true
        default: false
        }
    }

    var isLoaded: Bool {
        switch self {
        case .loaded: true
        default: false
        }
    }

//    var balance: Decimal? {
//        switch self {
//        case .loaded(let balance): balance
//        default: nil
//        }
//    }
}

// MARK: - CustomStringConvertible

extension TotalBalanceState: CustomStringConvertible {
    var description: String {
        switch self {
        case .empty: "Empty"
        case .loading(let cached): "Loading with cached \(String(describing: cached))"
        case .failed(let cached, let failedItems): "Failed with cached \(String(describing: cached)) items: \(failedItems.map(\.name))"
        case .loaded(let balance): "Loaded amount \(String(describing: balance))"
        }
    }
}
