#if canImport(UIKit)
import SwiftUI
import Testing

/// `@SnapshotSuite` が収集する 1 つのスナップショットケース。
///
/// マクロは `@Snapshot` / `@ComponentSnapshot` 関数を `__snapshotCases` へ収集する。
/// 手書きのパラメタライズドテストがそれらを実行する。
///
/// ```swift
/// @SnapshotSuite("SettingsView")
/// @MainActor
/// struct SettingsSnapshots {
///     @Snapshot
///     func loaded() -> some View { SettingsView() }
///
///     @Test func snapshots() {
///         for snapshotCase in Self.__snapshotCases { snapshotCase.run() }
///     }
/// }
/// ```
///
/// ランナーテストは手書きが必須。マクロ生成の宣言内で `@Test` を展開するとコンパイラが
/// lexical context を失い、swift-testing がファイルスコープのテストレコードを生成して
/// 型の内部でコンパイルできなくなるためである。
public struct SnapshotCase: Sendable, CustomTestStringConvertible {

    /// スナップショットのキャプチャ方式と命名方式。
    public enum Kind: Sendable {
        /// デバイス × テーマ × ロケールのマトリクスでキャプチャする全画面 View スナップショット。
        case view(inNavigation: Bool, disableAnimations: Bool)
        /// テーマ軸のみでキャプチャするコンポーネントスナップショット。
        case component(width: CGFloat?, height: CGFloat?)
    }

    public let viewName: String
    public let stateName: String
    public let kind: Kind
    private let makeView: @MainActor @Sendable () -> AnyView

    public init(
        viewName: String,
        stateName: String,
        kind: Kind,
        makeView: @escaping @MainActor @Sendable () -> AnyView
    ) {
        self.viewName = viewName
        self.stateName = stateName
        self.kind = kind
        self.makeView = makeView
    }

    public var testDescription: String { stateName }

    /// このケースのスナップショットアサーションを実行する。
    ///
    /// `#filePath` がテストソースの隣のスナップショットディレクトリに解決されるよう、
    /// スイート自身のファイルから呼び出す。
    @MainActor
    public func run(
        configuration: SnapshotConfiguration = .default,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch kind {
        case .view(let inNavigation, let disableAnimations):
            VisualTesting.assertViewSnapshot(
                of: makeView(),
                viewName: viewName,
                stateName: stateName,
                inNavigation: inNavigation,
                disableAnimations: disableAnimations,
                configuration: configuration,
                file: file,
                line: line
            )
        case .component(let width, let height):
            let size: CGSize? = if let width, let height {
                CGSize(width: width, height: height)
            } else {
                nil
            }
            VisualTesting.assertComponentSnapshot(
                of: makeView(),
                componentName: viewName,
                stateName: stateName,
                size: size,
                configuration: configuration,
                file: file,
                line: line
            )
        }
    }
}
#endif
