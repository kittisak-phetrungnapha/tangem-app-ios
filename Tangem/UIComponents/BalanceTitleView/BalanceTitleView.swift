//
//  BalanceTitleView.swift
//  Tangem
//
//  Created by Sergey Balashov on 29.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct BalanceTitleView: View {
    let state: LoadableTokenBalanceView.State

    var body: some View {
        LoadableTokenBalanceView(
            state: state,
            font: Fonts.Regular.body,
            textColor: Colors.Text.primary1,
            loaderSize: .init(width: 102, height: 24),
            loaderCornerRadius: 6
        )
        .multilineTextAlignment(.leading)
        .truncationMode(.middle)
    }
}
