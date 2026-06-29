#if canImport(UIKit)
import SwiftUI
import UIKit

// MARK: - ThemeApplicable

/// スナップショット View にテーマを適用するプロトコル。
///
/// デフォルト実装は `environment(\.colorScheme, ...)` を使用する。
/// カスタムテーマシステム（例: `ThemeProvider`）と統合する場合はアプリ側で実装する。
///
/// ```swift
/// struct AppThemeApplicable: ThemeApplicable {
///     @MainActor
///     func applyTheme<V: View>(_ view: V, theme: SnapshotTheme) -> AnyView {
///         let provider = ThemeProvider()
///         provider.themeMode = theme == .light ? .light : .dark
///         return AnyView(view.theme(provider))
///     }
/// }
/// ```
public protocol ThemeApplicable: Sendable {
    @MainActor
    func applyTheme<V: View>(_ view: V, theme: SnapshotTheme) -> AnyView
}

/// `colorScheme` environment を使ったデフォルトのテーマ実装。
public struct DefaultThemeApplicable: ThemeApplicable {
    public init() {}

    @MainActor
    public func applyTheme<V: View>(_ view: V, theme: SnapshotTheme) -> AnyView {
        let colorScheme: ColorScheme = theme == .light ? .light : .dark
        return AnyView(
            view.environment(\.colorScheme, colorScheme)
        )
    }
}
#endif
