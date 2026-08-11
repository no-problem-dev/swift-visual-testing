#if canImport(UIKit)
import SwiftUI
import UIKit

// MARK: - ThemeApplicable

/// The seam between a theme axis and whatever drives appearance in the app under test.
///
/// The default goes through `environment(\.colorScheme, ...)`. An app whose colours come from its own
/// theme object instead implements this, so snapshots exercise the same path the app does.
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

/// Applies the theme through the `colorScheme` environment — enough for views that read it directly.
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
