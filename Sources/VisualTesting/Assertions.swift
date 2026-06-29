#if canImport(UIKit)
import SnapshotTesting
import SwiftUI
import Testing
import UIKit

// MARK: - VisualTesting

/// スナップショットテストのコアアサーション関数群。
public enum VisualTesting {

    /// 全スナップショットに適用するテーマアプリケーター。
    ///
    /// カスタムテーマシステムを使う場合はテストターゲット内でここへ設定する。
    @MainActor
    public static var themeApplicable: any ThemeApplicable = DefaultThemeApplicable()

    /// デバイス × テーマ × ロケールのマトリクス全体で View スナップショットをアサートする。
    ///
    /// `@SnapshotSuite` から生成された `@Test` メソッドが呼び出す。
    /// 出力先: `__Snapshots__/{viewName}/{device}/{stateName}.{theme}_{locale}.png`
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
                    let vc = makeHostingController(
                        view: wrapped,
                        device: device,
                        theme: theme,
                        locale: locale
                    )
                    let snapshotName = "\(theme.rawValue)_\(locale)"

                    let failure = verifySnapshot(
                        of: vc,
                        as: .image(
                            on: device.config,
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

            updateManifest(
                viewName: viewName,
                type: .view,
                stateName: stateName,
                device: device,
                themes: configuration.themes,
                locales: configuration.locales,
                inNavigation: inNavigation,
                disableAnimations: disableAnimations,
                file: file
            )
        }
    }

    /// テーマ軸のみでコンポーネントスナップショットをアサートする。
    ///
    /// デバイスフレームは使用しない。
    /// 出力先: `__Snapshots__/{componentName}/{stateName}.{theme}.png`
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

    /// デバイスサブディレクトリ付きのスナップショットディレクトリを返す: `{testFileDir}/__Snapshots__/{viewName}/{device}`
    private static func snapshotDirectory(file: StaticString, viewName: String, device: SnapshotDevice) -> String {
        let fileURL = URL(fileURLWithPath: "\(file)")
        return fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__")
            .appendingPathComponent(viewName)
            .appendingPathComponent(device.rawValue)
            .path
    }

    /// デバイスなしのスナップショットディレクトリを返す: `{testFileDir}/__Snapshots__/{viewName}`
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
