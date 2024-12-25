//
//  UserTokensReorderingLogger.swift
//  Tangem
//
//  Created by Andrey Fedorov on 02.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct UserTokensReorderingLogger {
    let walletModels: [WalletModel]

    func logReorder(
        existingList: StoredUserTokenList,
        editedList: StoredUserTokenList,
        source: UserTokensReorderingSource
    ) {
        let walletModelsKeyedByIds = walletModels.keyedFirst(by: \.walletModelId.id)

        var output: [String] = []
        output.append("Performing reordering (initiated by \(source))")

        output.append("Old grouping option: \(existingList.grouping)")
        output.append("Old sorting option: \(existingList.sorting)")
        output.append("Old token list:")
        for item in existingList.entries {
            let description = description(for: item, walletModelsKeyedByIds: walletModelsKeyedByIds)
            output.append(description)
        }

        output.append("New grouping option: \(editedList.grouping)")
        output.append("New sorting option: \(editedList.sorting)")
        output.append("New token list:")
        for item in editedList.entries {
            let description = description(for: item, walletModelsKeyedByIds: walletModelsKeyedByIds)
            output.append(description)
        }

        AppLog.shared.debug(output.joined(separator: "\n"))
    }

    private func description(
        for item: StoredUserTokenList.Entry,
        walletModelsKeyedByIds: [WalletModel.ID: WalletModel]
    ) -> String {
        let objectDescription = "Token: \(item.name)"
        let walletModel = walletModelsKeyedByIds[item.walletModelId]
        let balances: (balanceValue: Decimal?, fiatValue: Decimal?)? = walletModel.map { walletModel in
            let balanceProvider = AvailableBalanceProvider(walletModel: walletModel)
            let fiatBalanceProvider = FiatBalanceProvider(walletModel: walletModel, cryptoBalanceProvider: balanceProvider)

            return (balanceValue: balanceProvider.balanceType.value, fiatValue: fiatBalanceProvider.balanceType.value)
        }

        return ObjectDescriptionFormatter.format(
            objectDescription: objectDescription,
            userInfo: [
                "state": description(for: walletModel?.state),
                "fiatValue": description(for: balances?.fiatValue),
                "balanceValue": description(for: balances?.balanceValue),
                "canUseQuotes": description(for: walletModel?.canUseQuotes),
                "isCustom": description(for: walletModel?.isCustom),
            ]
        )
    }

    private func description(for state: WalletModel.State?) -> String {
        guard let state else {
            return .unknown
        }

        switch state {
        case .created:
            return "created"
        case .loaded(let balance):
            return "loaded balance: \(balance)"
        case .loading:
            return "loading"
        case .noAccount:
            return "noAccount"
        case .failed(let error):
            return "failed (\(error.localizedDescription))"
        case .noDerivation:
            return "noDerivation"
        }
    }

    private func description(for optionalValue: any OptionalProtocol) -> String {
        guard let optionalValue = optionalValue.wrapped else {
            return .unknown
        }

        return String(describing: optionalValue)
    }
}
