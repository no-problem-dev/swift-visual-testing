#if canImport(UIKit)
import SwiftUI
import UIKit

// MARK: - ThemeApplicable

/// Protocol for applying themes to snapshot views.
///
/// Default implementation uses `environment(\.colorScheme, ...)`.
/// Override in your app to integrate with a custom theme system (e.g. ThemeProvider).
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

/// Default theme implementation using colorScheme environment.
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
