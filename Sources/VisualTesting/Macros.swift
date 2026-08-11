import CoreGraphics

/// Collects the suite's snapshot functions into a `__snapshotCases` static property.
///
/// The struct also has to declare one hand-written runner test; leaving it out is a compile error
/// that names the exact line to add.
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
/// The runner cannot be generated. Expanding `@Test` inside a macro-generated declaration makes the
/// compiler lose its lexical context, and swift-testing's test content records then fail to compile
/// inside the type.
@attached(member, names: named(__snapshotCases))
public macro SnapshotSuite(_ viewName: String) =
    #externalMacro(module: "VisualTestingMacros", type: "SnapshotSuiteMacro")

/// Marks a function as a full-screen view to capture across the whole matrix.
///
/// The function returns `some View` and takes no arguments; `@SnapshotSuite` on the enclosing struct
/// is what turns the mark into a captured case.
@attached(peer)
public macro Snapshot() =
    #externalMacro(module: "VisualTestingMacros", type: "SnapshotMacro")

/// Marks a function as a component to capture on the theme axis alone, at a fixed size.
///
/// No device frame and no locale variation. Omitting the size falls back to the view's intrinsic size.
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

/// Wraps the view in a `NavigationStack` before capture, so the bar is part of the image.
///
/// Only for `@Snapshot`. On a `@ComponentSnapshot` it is a compile error: a component is captured
/// without a device frame, so there is no navigation bar for the image to hold.
@attached(peer)
public macro InNavigation() =
    #externalMacro(module: "VisualTestingMacros", type: "InNavigationMacro")

/// Turns UIKit animations off for the capture, for views that would otherwise be caught mid-transition.
///
/// Applies to both capture shapes. On a function marked with neither it is a compile error.
@attached(peer)
public macro WithoutAnimation() =
    #externalMacro(module: "VisualTestingMacros", type: "WithoutAnimationMacro")
