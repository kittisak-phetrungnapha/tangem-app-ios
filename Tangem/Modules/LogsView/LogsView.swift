//
//  LogsView.swift
//  TangemApp
//
//  Created by Sergey Balashov on 22.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct LogsView: View {
    @ObservedObject var viewModel: LogsViewModel

    var body: some View {
            GroupedScrollView(alignment: .leading, spacing: 12) {
                content
            }
        .navigationTitle(Text("Logs"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { viewModel.setup() }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.logs {
        case .loading:
            ProgressView()
                .infinityFrame()
        case .success(let logs):
            ForEach(logs, id: \.self) { LogRowView(log: $0) }
        case .failure(let failure):
            Text(failure.localizedDescription)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                .infinityFrame()
        }
    }
}
