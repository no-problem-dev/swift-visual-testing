#if canImport(UIKit)
import SwiftUI
import Testing

/// One capture the suite will perform: a name, a shape, and a closure that builds the view.
///
/// The macro collects these; the hand-written runner is what actually executes them.
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
/// The runner has to be hand-written. Expanding `@Test` inside a macro-generated declaration makes
/// the compiler lose its lexical context, and swift-testing then emits file-scope test records that
/// cannot compile inside the type.
public struct SnapshotCase: Sendable, CustomTestStringConvertible {

    /// Which axes the case is captured across, and therefore how its files are named.
    public enum Kind: Sendable {
        /// A full-screen view, captured across the device × theme × locale matrix.
        case view(inNavigation: Bool, disableAnimations: Bool)
        /// A component, captured on the theme axis alone; a nil dimension falls back to intrinsic size.
        case component(width: CGFloat?, height: CGFloat?, disableAnimations: Bool)
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

    /// Runs this case's assertion.
    ///
    /// Call it from the suite's own file. `file` defaults to the caller's `#filePath`, and that is what
    /// puts `__Snapshots__` next to the test source rather than wherever the helper happens to live.
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
        case .component(let width, let height, let disableAnimations):
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
                disableAnimations: disableAnimations,
                configuration: configuration,
                file: file,
                line: line
            )
        }
    }
}
#endif
