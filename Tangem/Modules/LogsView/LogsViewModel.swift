//
//  LogsViewModel.swift
//  TangemApp
//
//  Created by Sergey Balashov on 22.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import OSLog
import TangemFoundation

class LogsViewModel: ObservableObject {
    @Published var logs: LoadingResult<[OSLogFileWriter.LogMessage], Error> = .loading

    private var refreshCancellable: AnyCancellable?

    init() {
        setup()
    }

    func setup() {
        refreshCancellable = Just(())
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { $0.0.logs = .loading })
            .receive(on: DispatchQueue.global())
            .map { $0.0.getLogEntries() }
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .receiveValue { viewModel, entries in
                viewModel.logs = .result(entries)
            }
    }

    func getLogEntries() -> Result<[OSLogFileWriter.LogMessage], Error> {
        .init {
            let content = try String(contentsOfFile: OSLog.logFile.absoluteString)
            var rows: [String] = content.components(separatedBy: "\n")
            // Drop Headers
            _ = rows.dropFirst()

            let cvs = rows.map { $0.components(separatedBy: ",") }
            return []
        }
    }
}
