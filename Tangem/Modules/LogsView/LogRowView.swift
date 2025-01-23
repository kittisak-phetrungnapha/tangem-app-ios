//
//  LogRowView.swift
//  TangemApp
//
//  Created by Sergey Balashov on 22.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLogger

struct LogRowView: View {
    let log: OSLogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(log.message)
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

            HStack(spacing: 4) {
                Group {
                    Text(log.category)

                    Text(AppConstants.dotSign)

                    Text(log.level)
                }.style(Fonts.Bold.caption1, color: Colors.Text.tertiary)

                Spacer()

                Group {
                    Text(log.date)

                    Text(log.time)
                }
                .style(Fonts.Regular.caption2, color: Colors.Text.tertiary)
            }
        }
    }
}
