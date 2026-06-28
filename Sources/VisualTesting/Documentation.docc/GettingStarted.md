# Getting Started with VisualTesting

Add snapshot testing to your Swift package in minutes.

## Installation

Add `swift-visual-testing` to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(
        url: "https://github.com/no-problem-dev/swift-visual-testing.git",
        .upToNextMajor(from: "2.0.0")
    ),
],
```

Then add `VisualTesting` to your test target:

```swift
.testTarget(
    name: "MyFeatureTests",
    dependencies: [
        "MyFeature",
        .product(name: "VisualTesting", package: "swift-visual-testing"),
    ]
),
```

## Basic Usage

### Snapshot a view across the default matrix

Create a test file in your test target and annotate a struct with `@SnapshotSuite`:

```swift
import Testing
import SwiftUI
import VisualTesting

@SnapshotSuite("ProfileView")
@MainActor
struct ProfileViewSnapshots {

    // Each @Snapshot function returns the view to capture.
    @Snapshot
    func loggedIn() -> some View {
        ProfileView(user: .preview)
    }

    @Snapshot
    @InNavigation
    func loggedInWithNav() -> some View {
        ProfileView(user: .preview)
    }

    @Snapshot
    @WithoutAnimation
    func loading() -> some View {
        ProfileView(user: nil)
    }

    // Write one runner by hand — @SnapshotSuite emits a compile error if missing.
    @Test func snapshots() {
        for snapshotCase in Self.__snapshotCases {
            snapshotCase.run()
        }
    }
}
```

On first run the PNG references are written to
`Tests/MyFeatureTests/__Snapshots__/ProfileView/`. Subsequent runs compare against them.

### Snapshot a design-system component

Components use a theme-only axis (no device frame, no locale):

```swift
@SnapshotSuite("PrimaryButton")
@MainActor
struct PrimaryButtonSnapshots {

    @ComponentSnapshot(width: 200, height: 50)
    func default() -> some View {
        PrimaryButton("Tap me")
    }

    @ComponentSnapshot(width: 200, height: 50)
    func disabled() -> some View {
        PrimaryButton("Tap me").disabled(true)
    }

    @Test func snapshots() {
        for snapshotCase in Self.__snapshotCases {
            snapshotCase.run()
        }
    }
}
```

### Customise the capture matrix

Pass a `SnapshotConfiguration` to `run(configuration:)`:

```swift
@Test func snapshots() {
    let config = SnapshotConfiguration(
        devices: [.iPhone16],
        themes: [.light],
        locales: ["en"]
    )
    for snapshotCase in Self.__snapshotCases {
        snapshotCase.run(configuration: config)
    }
}
```

### Integrate a custom theme system

Set `VisualTesting.themeApplicable` once in your test setup:

```swift
// In your test helper or setUp block
VisualTesting.themeApplicable = AppThemeApplicable()
```

Then implement `ThemeApplicable`:

```swift
struct AppThemeApplicable: ThemeApplicable {
    @MainActor
    func applyTheme<V: View>(_ view: V, theme: SnapshotTheme) -> AnyView {
        let provider = ThemeProvider()
        provider.themeMode = theme == .light ? .light : .dark
        return AnyView(view.environmentObject(provider))
    }
}
```

## Generating a Visual Gallery

After a test run, aggregate all manifests into an interactive HTML gallery:

```swift
// In a test or script
let catalog = VisualTesting.generateCatalog(
    rootDirectory: "Tests/MyFeatureTests",
    outputPath: "snapshot-catalog.json"
)
VisualTesting.generateGallery(catalog: catalog, outputPath: "snapshot-gallery.html")
```

Open `snapshot-gallery.html` in any browser — no server required. The gallery supports
filtering by device, theme, and locale, side-by-side light/dark comparison, and a lightbox.
