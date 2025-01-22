//
//  LogsViewModel.swift
//  TangemApp
//
//  Created by Sergey Balashov on 22.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLogger

class LogsViewModel: ObservableObject {
    @Published var logs: LoadingResult<[OSLogEntry], Error> = .loading

    private var refreshCancellable: AnyCancellable?

    init() {
        setup()
    }

    func setup() {
        logs = .loading
        refreshCancellable = Just(())
            .receive(on: DispatchQueue.global())
            .map { .init { try OSLogFileParser.entries() } }
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .receiveValue { viewModel, entries in
                viewModel.logs = .result(entries)
            }
    }
}
