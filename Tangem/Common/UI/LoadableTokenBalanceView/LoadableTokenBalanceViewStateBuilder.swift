//
//  LoadableTokenBalanceViewStateBuilder.swift
//  TangemApp
//
//  Created by Sergey Balashov on 10.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct LoadableTokenBalanceViewStateBuilder {
    func build(type: FormattedTokenBalanceType, withIcon: Bool = false) -> LoadableTokenBalanceView.State {
        switch type {
        case .loading(let cachedType):
                .loading(cached: .string(cachedType.value))
        case .failure(let cachedType):
                .failed(cached: .string(cachedType.value), withIcon: withIcon)
        case .loaded(let string):
                .loaded(text: .string(string))
        }
    }
}
