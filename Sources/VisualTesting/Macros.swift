import CoreGraphics

/// Defines a snapshot test suite for a view or component.
///
/// Scans child functions for `@Snapshot` / `@ComponentSnapshot` and collects
/// them into a `__snapshotCases` static property. The suite must declare one
/// hand-written parameterized runner test (the macro emits a compile-time
/// error when it is missing):
///
/// ```swift
/// @SnapshotSuite("SettingsView")
/// @MainActor
/// struct SettingsSnapshots {
///     @Snapshot
///     func loaded() -> some View {
///         SettingsView()
///     }
///
///     @Test func snapshots() {
///         for snapshotCase in Self.__snapshotCases { snapshotCase.run() }
///     }
/// }
/// ```
///
/// The runner cannot be macro-generated: expanding `@Test` inside
/// macro-generated declarations loses lexical context and produces test
/// content records that do not compile inside a type.
@attached(member, names: named(__snapshotCases))
public macro SnapshotSuite(_ viewName: String) =
    #externalMacro(module: "VisualTestingMacros", type: "SnapshotSuiteMacro")

/// Marks a function as a view snapshot target.
///
/// The function must return `some View`. `@SnapshotSuite` will generate a `@Test` method
/// that calls `VisualTesting.assertViewSnapshot` with device x theme x locale matrix.
@attached(peer)
public macro Snapshot() =
    #externalMacro(module: "VisualTestingMacros", type: "SnapshotMacro")

/// Marks a function as a component snapshot target with optional size.
///
/// Components are tested with theme-only axis (no device frame, no locale).
///
/// ```swift
/// @ComponentSnapshot(width: 340, height: 120)
/// func level1() -> some View {
///     Card(elevation: .level1) { Text("Card Level 1") }
/// }
/// ```
@attached(peer)
public macro ComponentSnapshot(width: CGFloat? = nil, height: CGFloat? = nil) =
    #externalMacro(module: "VisualTestingMacros", type: "ComponentSnapshotMacro")

/// Indicates the view should be wrapped in `NavigationStack`.
@attached(peer)
public macro InNavigation() =
    #externalMacro(module: "VisualTestingMacros", type: "InNavigationMacro")

/// Indicates animations should be disabled during snapshot capture.
@attached(peer)
public macro WithoutAnimation() =
    #externalMacro(module: "VisualTestingMacros", type: "WithoutAnimationMacro")
