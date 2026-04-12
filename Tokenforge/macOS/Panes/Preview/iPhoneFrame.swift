//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// A simulated iPhone bezel with dynamic island and status bar. Renders
/// `content` inside the screen rectangle and uses the same screen
/// background color as the current appearance.
///
struct iPhoneFrame<Content: View>: View {

    let appearance: TokenResolver.Appearance
    @ViewBuilder let content: () -> Content

    @Environment(\.resolvedTokens) private var resolvedTokens

    // MARK: - Geometry

    private let width: CGFloat = 340
    private let height: CGFloat = 690
    private let bezelPadding: CGFloat = 12
    private let outerRadius: CGFloat = 54
    private let innerRadius: CGFloat = 42
    private let statusBarHeight: CGFloat = 54

    var body: some View {
        ZStack {
            // Bezel
            RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                .fill(Color.black)
                .frame(width: width, height: height)
                .shadow(color: .black.opacity(0.45), radius: 50, x: 0, y: 50)
                .shadow(color: .black.opacity(0.3), radius: 22, x: 0, y: 22)

            // Screen
            RoundedRectangle(cornerRadius: innerRadius, style: .continuous)
                .fill(screenBackground)
                .frame(
                    width: width - bezelPadding * 2,
                    height: height - bezelPadding * 2
                )
                .overlay(
                    // Screen content clipped to the inner radius
                    content()
                        .padding(.top, statusBarHeight)
                        .environment(\.colorScheme, appearance == .dark ? .dark : .light)
                )
                .overlay(
                    // Status bar
                    statusBar
                        .padding(.top, 16)
                        .padding(.horizontal, 30),
                    alignment: .top
                )
                .overlay(
                    // Dynamic island
                    Capsule()
                        .fill(Color.black)
                        .frame(width: 118, height: 34)
                        .padding(.top, 10),
                    alignment: .top
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: innerRadius, style: .continuous)
                )
                .frame(
                    width: width - bezelPadding * 2,
                    height: height - bezelPadding * 2
                )
        }
        .frame(width: width, height: height)
    }

    // MARK: - Derived

    private var screenBackground: Color {
        if let resolved = resolvedTokens?.color("background.primary") {
            return resolved
        }
        return appearance == .light
            ? Color(white: 0.95)
            : Color(white: 0.05)
    }

    private var statusForeground: Color {
        appearance == .light ? .black : .white
    }

    // MARK: - Status bar

    private var statusBar: some View {
        HStack {
            Text("9:41")
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            HStack(spacing: 5) {
                Image(systemName: "cellularbars")
                    .font(.system(size: 12, weight: .semibold))
                Image(systemName: "wifi")
                    .font(.system(size: 12, weight: .semibold))
                Image(systemName: "battery.100")
                    .font(.system(size: 13, weight: .regular))
            }
        }
        .foregroundStyle(statusForeground)
    }
}
