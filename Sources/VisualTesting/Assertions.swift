#if canImport(UIKit)
import SnapshotTesting
import SwiftUI
import Testing
import UIKit

// MARK: - VisualTesting

/// The assertions the macros call, plus the catalog and gallery generators.
public enum VisualTesting {

    /// How every snapshot gets its light or dark appearance.
    ///
    /// This is process-wide state. A test target with a custom theme system assigns to it once
    /// during setup; every suite in that process then captures through it.
    @MainActor
    public static var themeApplicable: any ThemeApplicable = DefaultThemeApplicable()

    /// Captures a view once per combination in the configured matrix, recording one issue per mismatch.
    ///
    /// Reached from the suite's hand-written runner by way of `SnapshotCase.run()`.
    /// Writes to `__Snapshots__/{viewName}/{device}/{stateName}.{theme}_{locale}.png`.
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

        for device in configuration.devices {
            let dir = snapshotDirectory(file: file, viewName: viewName, device: device)

            for theme in configuration.themes {
                for locale in configuration.locales {
                    for dynamicType in configuration.dynamicTypes {
                        let vc = makeHostingController(
                            view: wrapped,
                            device: device,
                            theme: theme,
                            locale: locale,
                            dynamicType: dynamicType
                        )
                        let snapshotName = snapshotName(theme: theme, locale: locale, dynamicType: dynamicType)

                        let failure = verifySnapshot(
                            of: vc,
                            as: .image(
                                on: device.config(dynamicType: dynamicType),
                                precision: configuration.precision,
                                perceptualPrecision: configuration.perceptualPrecision
                            ),
                            named: snapshotName,
                            snapshotDirectory: dir,
                            file: file,
                            testName: stateName,
                            line: line
                        )
                        if let message = failure {
                            Issue.record(
                                Comment(rawValue: "\(viewName)/\(device.rawValue)/\(stateName).\(snapshotName): \(message)")
                            )
                        }
                    }
                }
            }

            updateManifest(
                viewName: viewName,
                type: .view,
                stateName: stateName,
                device: device,
                themes: configuration.themes,
                locales: configuration.locales,
                dynamicTypes: configuration.dynamicTypes,
                inNavigation: inNavigation,
                disableAnimations: disableAnimations,
                file: file
            )
        }
    }

    /// Captures a component once per theme, with no device frame and no locale variation.
    ///
    /// Without an explicit `size` the view's intrinsic size is used, capped at 393×852.
    /// Writes to `__Snapshots__/{componentName}/{stateName}.{theme}.png`.
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
                file: file,
                testName: stateName,
                line: line
            )
            if let message = failure {
                Issue.record(
                    Comment(rawValue: "\(componentName)/\(stateName).\(snapshotName): \(message)")
                )
            }
        }

        updateManifest(
            viewName: componentName,
            type: .component,
            stateName: stateName,
            device: nil,
            themes: configuration.themes,
            locales: [],
            inNavigation: false,
            disableAnimations: false,
            file: file
        )
    }

    // MARK: - Private Helpers

    /// The reference image's name.
    ///
    /// **Nothing is appended at the default text size.** Appending would leave every reference image
    /// recorded under 2.0 unreachable, forcing a re-record even in suites that never use this axis.
    private static func snapshotName(
        theme: SnapshotTheme,
        locale: String,
        dynamicType: SnapshotDynamicType
    ) -> String {
        let base = "\(theme.rawValue)_\(locale)"
        return dynamicType == .standard ? base : "\(base)_\(dynamicType.rawValue)"
    }

    @MainActor
    private static func makeHostingController<V: View>(
        view: V,
        device: SnapshotDevice,
        theme: SnapshotTheme,
        locale: String,
        dynamicType: SnapshotDynamicType
    ) -> UIViewController {
        let themed = themeApplicable.applyTheme(view, theme: theme)
        let localized = themed
            .environment(\.locale, Locale(identifier: locale))
            .environment(\.dynamicTypeSize, dynamicType.dynamicTypeSize)

        let hostingController = UIHostingController(rootView: localized)
        hostingController.view.frame = CGRect(
            origin: .zero,
            size: device.config.size ?? CGSize(width: 393, height: 852)
        )
        hostingController.view.layoutIfNeeded()
        return hostingController
    }

    /// Resolves `{testFileDir}/__Snapshots__/{viewName}/{device}` — beside the file that called in.
    private static func snapshotDirectory(file: StaticString, viewName: String, device: SnapshotDevice) -> String {
        let fileURL = URL(fileURLWithPath: "\(file)")
        return fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__")
            .appendingPathComponent(viewName)
            .appendingPathComponent(device.rawValue)
            .path
    }

    /// Resolves `{testFileDir}/__Snapshots__/{viewName}` — the component layout, with no device level.
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
