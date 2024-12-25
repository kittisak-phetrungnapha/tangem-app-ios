//
//  TokenItemInfoProvider.swift
//  Tangem
//
//  Created by Andrew Son on 28/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

protocol TokenItemInfoProvider: AnyObject {
    var id: Int { get }
    var tokenItem: TokenItem { get }
    var hasPendingTransactions: Bool { get }
    var isZeroBalanceValue: Bool { get }
    var quote: TokenQuote? { get }

    var tokenItemState: TokenItemViewState { get }
    var tokenItemStatePublisher: AnyPublisher<TokenItemViewState, Never> { get }
    var balanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }
    var fiatBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }
    var actionsUpdatePublisher: AnyPublisher<Void, Never> { get }
    var isStakedPublisher: AnyPublisher<Bool, Never> { get }
}
