#if canImport(UIKit)
import SwiftUI
import Testing

/// A single snapshot case collected by `@SnapshotSuite`.
///
/// The macro gathers `@Snapshot` / `@ComponentSnapshot` functions into
/// `__snapshotCases`; a hand-written parameterized test runs them:
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
/// The runner test must be written by hand: `@Test` cannot be reliably
/// expanded inside macro-generated declarations (the compiler loses the
/// lexical context and swift-testing emits file-scope test records that
/// do not compile inside a type).
public struct SnapshotCase: Sendable, CustomTestStringConvertible {

    /// How the snapshot is captured and named.
    public enum Kind: Sendable {
        /// Full-view snapshot across the device × theme × locale matrix.
        case view(inNavigation: Bool, disableAnimations: Bool)
        /// Component snapshot across the theme axis only.
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

    /// Runs the snapshot assertion for this case.
    ///
    /// Call from the suite's own file so that `#filePath` resolves the
    /// snapshot directory next to the test source.
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
