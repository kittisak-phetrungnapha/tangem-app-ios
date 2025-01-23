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
        VStack(spacing: 12) {
            PickerView(contents: viewModel.categories, selection: $viewModel.selectedCategoryIndex)
                .padding(.horizontal, 14)

            GroupedScrollView(alignment: .leading, spacing: .zero) {
                content
            }
        }
        .navigationTitle(Text("Logs"))
        .background(Colors.Background.tertiary.ignoresSafeArea())
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.logs {
        case .loading:
            ProgressView()
                .infinityFrame()
        case .success(let logs):
            ForEach(logs, id: \.hashValue) {
                LogRowView(log: $0)

                Divider()
            }
        case .failure(let failure):
            Text(failure.localizedDescription)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                .infinityFrame()
        }
    }
}
