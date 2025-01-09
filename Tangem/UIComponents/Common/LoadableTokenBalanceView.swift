//
//  LoadableTokenBalanceView.swift
//  TangemApp
//
//  Created by Sergey Balashov on 27.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct LoadableTokenBalanceView: View {
    let state: State
    let font: Font
    let textColor: Color
    let loaderSize: CGSize
    let loaderCornerRadius: CGFloat

    init(state: State, font: Font, textColor: Color, loaderSize: CGSize, loaderCornerRadius: CGFloat = 3) {
        self.state = state
        self.font = font
        self.textColor = textColor
        self.loaderSize = loaderSize
        self.loaderCornerRadius = loaderCornerRadius
    }

    var body: some View {
        switch state {
        case .loading(.some(let cached)):
            SensitiveText(cached)
                .style(font, color: textColor)
                .modifier(Shimmer())
        case .loading(.none):
            Rectangle()
                .fill(Colors.Background.tertiary)
                .cornerRadiusContinuous(loaderCornerRadius)
                .frame(size: loaderSize)
                .modifier(Shimmer())
        case .failed(let text, true):
            HStack(spacing: 6) {
                Assets.failedCloud.image
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.inactive)
                    .frame(width: 12, height: 12)

                SensitiveText(text)
                    .style(font, color: textColor)
            }
        case .failed(let text, false):
            SensitiveText(text)
                .style(font, color: textColor)
        case .loaded(let text):
            SensitiveText(text)
                .style(font, color: textColor)
        }
    }
}

extension LoadableTokenBalanceView {
    typealias Text = SensitiveText.TextType

    enum State {
        case loading(cached: Text? = nil)
        case failed(cached: Text, withIcon: Bool = false)
        case loaded(text: Text)
    }
}

func attributed() -> AttributedString {
    var attributed = BalanceFormatter()
        .formatAttributedTotalBalance(
            fiatBalance: "1 312 422,23 $",
            formattingOptions: .defaultOptions
        )

    attributed.foregroundColor = nil
    return attributed
}

public struct Shimmer: ViewModifier {
    @State var isInitialState: Bool = true

    public func body(content: Content) -> some View {
        content
            .mask {
                LinearGradient(
                    gradient: .init(colors: [.black, .black.opacity(0.4), .black]),
                    startPoint: isInitialState ? .init(x: -0.5, y: -0.5) : .init(x: 1, y: 1),
                    endPoint: isInitialState ? .init(x: 0, y: 0) : .init(x: 1.5, y: 1.5)
                )
            }
            .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isInitialState)
            .onAppear {
                isInitialState = false
            }
    }
}

#Preview {
    VStack(alignment: .trailing, spacing: 16) {
        VStack(alignment: .trailing, spacing: 2) {
            LoadableTokenBalanceView(
                state: .loading(cached: .attributed(attributed())),
                font: Fonts.Regular.subheadline,
                textColor: Colors.Text.primary1,
                loaderSize: .init(width: 40, height: 12)
            )

            LoadableTokenBalanceView(
                state: .loading(cached: .string("1,23 BTC")),
                font: Fonts.Regular.caption1,
                textColor: Colors.Text.tertiary,
                loaderSize: .init(width: 40, height: 12)
            )
        }

        VStack(alignment: .trailing, spacing: 2) {
            LoadableTokenBalanceView(
                state: .loading(cached: .string("1 312 422,23 $")),
                font: Fonts.Regular.subheadline,
                textColor: Colors.Text.primary1,
                loaderSize: .init(width: 40, height: 12)
            )

            LoadableTokenBalanceView(
                state: .loading(cached: .string("1,23 BTC")),
                font: Fonts.Regular.caption1,
                textColor: Colors.Text.tertiary,
                loaderSize: .init(width: 40, height: 12)
            )
        }

        Divider()

        VStack(alignment: .trailing, spacing: 2) {
            LoadableTokenBalanceView(
                state: .loaded(text: .string("1 312 422,23 $")),
                font: Fonts.Regular.subheadline,
                textColor: Colors.Text.primary1,
                loaderSize: .init(width: 40, height: 12)
            )

            LoadableTokenBalanceView(
                state: .loaded(text: .string("1,23 BTC")),
                font: Fonts.Regular.caption1,
                textColor: Colors.Text.tertiary,
                loaderSize: .init(width: 40, height: 12)
            )
        }

        Divider()

        VStack(alignment: .trailing, spacing: 2) {
            LoadableTokenBalanceView(
                state: .failed(cached: .string("1 312 422,23 $"), withIcon: true),
                font: Fonts.Regular.subheadline,
                textColor: Colors.Text.primary1,
                loaderSize: .init(width: 40, height: 12)
            )

            LoadableTokenBalanceView(
                state: .failed(cached: .string("1,23 BTC")),
                font: Fonts.Regular.caption1,
                textColor: Colors.Text.tertiary,
                loaderSize: .init(width: 40, height: 12)
            )
        }
    }
    .padding()
}
