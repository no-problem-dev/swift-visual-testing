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

        let root = snapshotRoot(file: file, output: configuration.output)

        for device in configuration.devices {
            let dir = root.appendingPathComponent(viewName).appendingPathComponent(device.rawValue).path

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
                        let config = device.config(theme: theme, dynamicType: dynamicType)

                        let failure = snapshot(
                            vc,
                            capture: { CaptureRenderer.image(of: vc, config: config, fittingWidth: nil) },
                            as: .image(
                                on: config,
                                precision: configuration.precision,
                                perceptualPrecision: configuration.perceptualPrecision
                            ),
                            named: snapshotName,
                            directory: dir,
                            stateName: stateName,
                            output: configuration.output,
                            file: file,
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
                root: root
            )
        }
    }

    /// Captures a component once per theme, with no device frame and no locale variation.
    ///
    /// With `size` the component is laid out at exactly that size. With `fittingWidth` and no `size`
    /// it is laid out at that width and takes the height it needs, however tall — the whole of a
    /// scrolling screen's content, for instance. With neither, the view's intrinsic size is used,
    /// capped at 393×852.
    /// Writes to `__Snapshots__/{componentName}/{stateName}.{theme}.png`.
    @MainActor
    public static func assertComponentSnapshot<V: View>(
        of view: V,
        componentName: String,
        stateName: String,
        size: CGSize?,
        fittingWidth: CGFloat? = nil,
        disableAnimations: Bool,
        configuration: SnapshotConfiguration = .default,
        file: StaticString,
        line: UInt
    ) {
        if disableAnimations { UIView.setAnimationsEnabled(false) }
        defer { if disableAnimations { UIView.setAnimationsEnabled(true) } }

        let root = snapshotRoot(file: file, output: configuration.output)
        let dir = root.appendingPathComponent(componentName).path

        for theme in configuration.themes {
            let themed = themeApplicable.applyTheme(view, theme: theme)

            let vc = UIHostingController(rootView: themed)
            if let size {
                vc.view.frame = CGRect(origin: .zero, size: size)
            } else if let fittingWidth {
                let fitting = vc.sizeThatFits(in: CGSize(width: fittingWidth, height: .greatestFiniteMagnitude))
                vc.view.frame = CGRect(origin: .zero, size: CGSize(width: fittingWidth, height: ceil(fitting.height)))
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

            let captureConfig = ViewImageConfig(
                safeArea: .zero,
                size: fittingWidth != nil && size == nil ? nil : vc.view.frame.size,
                traits: UITraitCollection(userInterfaceStyle: theme.userInterfaceStyle)
            )
            let failure = snapshot(
                vc,
                capture: { CaptureRenderer.image(of: vc, config: captureConfig, fittingWidth: size == nil ? fittingWidth : nil) },
                as: .image(
                    precision: configuration.precision,
                    perceptualPrecision: configuration.perceptualPrecision,
                    traits: UITraitCollection(userInterfaceStyle: theme.userInterfaceStyle)
                ),
                named: snapshotName,
                directory: dir,
                stateName: stateName,
                output: configuration.output,
                file: file,
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
            disableAnimations: disableAnimations,
            root: root
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
        hostingController.view.frame = CGRect(origin: .zero, size: device.size)
        hostingController.view.layoutIfNeeded()
        return hostingController
    }

    /// The directory every view and component directory sits in.
    ///
    /// For reference images that is `{testFileDir}/__Snapshots__`, beside the file that called in;
    /// for a capture it is the directory the configuration names.
    static func snapshotRoot(file: StaticString, output: SnapshotOutput) -> URL {
        switch output {
        case .references:
            URL(fileURLWithPath: "\(file)")
                .deletingLastPathComponent()
                .appendingPathComponent("__Snapshots__")
        case .capture(let directory):
            URL(fileURLWithPath: directory, isDirectory: true)
        }
    }

    /// Compares against the reference image, or — for a capture — renders through ``CaptureRenderer``
    /// and writes without comparing.
    ///
    /// Returns the failure message to record, or `nil`. A capture fails only when the image could not
    /// be rendered or written; swift-snapshot-testing would report every write as a failure, which is
    /// right for a reference and wrong for a catalog that is rewritten on purpose each run.
    @MainActor
    private static func snapshot(
        _ viewController: UIViewController,
        capture: () -> UIImage,
        as strategy: Snapshotting<UIViewController, UIImage>,
        named name: String,
        directory: String,
        stateName: String,
        output: SnapshotOutput,
        file: StaticString,
        line: UInt
    ) -> String? {
        guard case .capture = output else {
            return verifySnapshot(
                of: viewController,
                as: strategy,
                named: name,
                snapshotDirectory: directory,
                file: file,
                testName: stateName,
                line: line
            )
        }

        let image = capture()

        let url = URL(fileURLWithPath: directory, isDirectory: true)
            .appendingPathComponent("\(stateName).\(name).png")
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try strategy.diffing.toData(image).write(to: url)
        } catch {
            return String(describing: VisualTestingError.writeFailed(path: url.path, underlying: error))
        }
        return nil
    }
}
#endif
