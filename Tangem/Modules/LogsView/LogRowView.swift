//
//  LogRowView.swift
//  TangemApp
//
//  Created by Sergey Balashov on 22.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import OSLog
import SwiftUI

struct LogRowView: View {
    let log: OSLogFileWriter.LogMessage

    var body: some View {
        VStack(alignment: .leading) {
            Text(log.message)
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

            HStack {
                Text(log.level)

                Text(AppConstants.dotSign)

                Text(log.date)

                Text(AppConstants.dotSign)

                Text(log.category)
            }
            .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
        }
    }
}
