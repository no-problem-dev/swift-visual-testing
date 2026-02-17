#if canImport(UIKit)
import SnapshotTesting
import SwiftUI
import Testing
import UIKit

// MARK: - VisualTesting

/// Core assertion functions for visual testing.
public enum VisualTesting {

    /// The theme applicator used for all snapshots.
    /// Set this in your test target to use a custom theme system.
    @MainActor
    public static var themeApplicable: any ThemeApplicable = DefaultThemeApplicable()

    /// Assert view snapshots across device x theme x locale matrix.
    ///
    /// Called by generated `@Test` methods from `@SnapshotSuite`.
    /// Produces files at: `__Snapshots__/{viewName}/{stateName}.{device}_{theme}_{locale}.png`
    @MainActor
    public static func assertViewSnapshot<V: View>(
        of view: V,
        viewName: String,
        stateName: String,
        inNavigation: Bool,
        disableAnimations: Bool,
        configuration: SnapshotConfiguration = .default,
        file: StaticString,
        line: UInt
    ) {
        if disableAnimations { UIView.setAnimationsEnabled(false) }
        defer { if disableAnimations { UIView.setAnimationsEnabled(true) } }

        let wrapped: AnyView = if inNavigation {
            AnyView(NavigationStack { view })
        } else {
            AnyView(view)
        }

        let dir = snapshotDirectory(file: file, viewName: viewName)

        for device in configuration.devices {
            for theme in configuration.themes {
                for locale in configuration.locales {
                    let vc = makeHostingController(
                        view: wrapped,
                        device: device,
                        theme: theme,
                        locale: locale
                    )
                    let snapshotName = "\(device.rawValue)_\(theme.rawValue)_\(locale)"

                    let failure = verifySnapshot(
                        of: vc,
                        as: .image(
                            on: device.config,
                            precision: configuration.precision,
                            perceptualPrecision: configuration.perceptualPrecision
                        ),
                        named: snapshotName,
                        snapshotDirectory: dir,
                        testName: stateName,
                        file: file,
                        line: line
                    )
                    if let message = failure {
                        Issue.record(
                            Comment(rawValue: message),
                            sourceLocation: SourceLocation(
                                fileID: "\(file)",
                                filePath: "\(file)",
                                line: Int(line),
                                column: 0
                            )
                        )
                    }
                }
            }
        }
    }

    /// Assert component snapshots across theme axis only.
    ///
    /// Components don't use device frames. Produces files at:
    /// `__Snapshots__/{componentName}/{stateName}.{theme}.png`
    @MainActor
    public static func assertComponentSnapshot<V: View>(
        of view: V,
        componentName: String,
        stateName: String,
        size: CGSize?,
        configuration: SnapshotConfiguration = .default,
        file: StaticString,
        line: UInt
    ) {
        let dir = snapshotDirectory(file: file, viewName: componentName)

        for theme in configuration.themes {
            let themed = themeApplicable.applyTheme(view, theme: theme)

            let vc = UIHostingController(rootView: themed)
            if let size {
                vc.view.frame = CGRect(origin: .zero, size: size)
            } else {
                let fittingSize = vc.view.intrinsicContentSize
                vc.view.frame = CGRect(
                    origin: .zero,
                    size: CGSize(
                        width: min(fittingSize.width, 393),
                        height: min(fittingSize.height, 852)
                    )
                )
            }
            vc.view.layoutIfNeeded()

            let snapshotName = "\(theme.rawValue)"

            let failure = verifySnapshot(
                of: vc,
                as: .image(
                    precision: configuration.precision,
                    perceptualPrecision: configuration.perceptualPrecision
                ),
                named: snapshotName,
                snapshotDirectory: dir,
                testName: stateName,
                file: file,
                line: line
            )
            if let message = failure {
                Issue.record(
                    Comment(rawValue: message),
                    sourceLocation: SourceLocation(
                        fileID: "\(file)",
                        filePath: "\(file)",
                        line: Int(line),
                        column: 0
                    )
                )
            }
        }
    }

    // MARK: - Private Helpers

    @MainActor
    private static func makeHostingController<V: View>(
        view: V,
        device: SnapshotDevice,
        theme: SnapshotTheme,
        locale: String
    ) -> UIViewController {
        let themed = themeApplicable.applyTheme(view, theme: theme)
        let localized = themed.environment(\.locale, Locale(identifier: locale))

        let hostingController = UIHostingController(rootView: localized)
        hostingController.view.frame = CGRect(
            origin: .zero,
            size: device.config.size ?? CGSize(width: 393, height: 852)
        )
        hostingController.view.layoutIfNeeded()
        return hostingController
    }

    /// Compute snapshot directory: `{testFileDir}/__Snapshots__/{viewName}`
    private static func snapshotDirectory(file: StaticString, viewName: String) -> String {
        let fileURL = URL(fileURLWithPath: "\(file)")
        return fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__")
            .appendingPathComponent(viewName)
            .path
    }
}
#endif
