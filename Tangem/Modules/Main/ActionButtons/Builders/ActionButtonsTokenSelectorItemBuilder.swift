//
//  ActionButtonsTokenSelectorItemBuilder.swift
//  TangemApp
//
//  Created by GuitarKitty on 01.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct ActionButtonsTokenSelectorItemBuilder: TokenSelectorItemBuilder {
    private let balanceFormatter = BalanceFormatter()

    func map(from walletModel: WalletModel, isDisabled: Bool) -> ActionButtonsTokenSelectorItem {
        let tokenIconInfo = TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
        let balanceProvider = AvailableBalanceProvider(walletModel: walletModel)
        let fiatBalanceProvider = FiatBalanceProvider(walletModel: walletModel, cryptoBalanceProvider: balanceProvider)

        // TODO:
        // Use logic from `DefaultTokenItemInfoProvider` or DefaultTokenItemInfoProvider
        // to support balance state changes loading / loaded / cached
        return ActionButtonsTokenSelectorItem(
            id: walletModel.id,
            tokenIconInfo: tokenIconInfo,
            name: walletModel.tokenItem.name,
            symbol: walletModel.tokenItem.currencySymbol,
            balance: balanceFormatter.formatFiatBalance(balanceProvider.balanceType.value),
            fiatBalance: balanceFormatter.formatFiatBalance(fiatBalanceProvider.balanceType.value),
            isDisabled: isDisabled,
            isLoading: walletModel.state.isLoading,
            walletModel: walletModel
        )
    }
}
