# Getting Started

Write your first snapshot suite, then record its reference images.

## Overview

`VisualTesting` is built on UIKit, so its snapshots run on an iOS Simulator through `xcodebuild`
rather than `swift test`. Add the `VisualTesting` product to a test target and you are ready to
write a suite; installation is covered in the README.

## Capturing a view across the default matrix

Mark a struct with `@SnapshotSuite`, and give it one function per state you want to see.

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

    // The runner is hand-written; @SnapshotSuite emits a compile error when it is missing.
    @Test func snapshots() {
        for snapshotCase in Self.__snapshotCases {
            snapshotCase.run()
        }
    }
}
```

Reference images land in `Tests/MyFeatureTests/__Snapshots__/ProfileView/`, one subdirectory per
device. Later runs compare against them.

The runner cannot be generated for you. Expanding `@Test` inside a macro-generated declaration makes
the compiler lose its lexical context, and swift-testing's test records then fail to compile inside
the type. Keep the runner in the suite's own file too: `run()` defaults `file` to the caller's
`#filePath`, and that is what puts `__Snapshots__` next to the test source.

## Capturing a design-system component

Components use the theme axis alone — no device frame, no locale — at a size you specify. Leave the
size out and the view's intrinsic size is used instead.

```swift
@SnapshotSuite("PrimaryButton")
@MainActor
struct PrimaryButtonSnapshots {

    @ComponentSnapshot(width: 200, height: 50)
    func idle() -> some View {
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

Output is `__Snapshots__/PrimaryButton/idle.light.png` and its dark counterpart.

## Changing the matrix

Pass a ``SnapshotConfiguration`` to `run(configuration:)` to narrow or widen a single suite.

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

Two axes are off by default because turning them on costs images in every suite that adopts them:

- **iPad window widths.** ``SnapshotDevice/iPadPro11Half`` and ``SnapshotDevice/iPadPro11Third``
  cover the sizes the HIG asks you to verify now that iPadOS 26 has replaced Split View with freely
  resizable windows. Both land in the *compact* horizontal size class, so what they show is an iPad
  falling into the same layout branch as an iPhone.
- **Accessibility text size.** ``SnapshotDynamicType/accessibility3`` is where large-text breakage
  becomes visible: line heights, vertical centring against icons, where truncation lands. The largest
  size is not the checkpoint, because it breaks no matter what and so cannot signal a regression.
  Reference images at the standard size keep their existing names, so adding this axis never
  invalidates what you already recorded.

## Integrating a custom theme system

By default the theme axis is applied through the `colorScheme` environment. If appearance in your app
is driven by something else, implement ``ThemeApplicable`` so snapshots go through the same path.

```swift
struct AppThemeApplicable: ThemeApplicable {
    @MainActor
    func applyTheme<V: View>(_ view: V, theme: SnapshotTheme) -> AnyView {
        let provider = ThemeProvider()
        provider.themeMode = theme == .light ? .light : .dark
        return AnyView(view.theme(provider))
    }
}
```

Assign it once — it is process-wide state, so every suite in the test run captures through it.

```swift
@MainActor
func setupVisualTesting() {
    VisualTesting.themeApplicable = AppThemeApplicable()
}
```

Call `setupVisualTesting()` from each suite's `init()`.

## Recording reference images

There is nothing to compare against on the first run, and a deliberate design change needs the images
re-recorded. Both are done with swift-snapshot-testing's record mode.

Because the tests run under `xcodebuild`, the variable needs the `TEST_RUNNER_` prefix: that is what
makes `xcodebuild` forward it into the test runner process, where it is read as
`SNAPSHOT_TESTING_RECORD`.

```bash
TEST_RUNNER_SNAPSHOT_TESTING_RECORD=all xcodebuild test \
  -scheme YourScheme \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

A record run reports every image it wrote as a failure. That is deliberate on
swift-snapshot-testing's part: nothing was compared, so nothing passed. Turn record mode off, re-run
to get a real result, and read the image diff before committing.

## Generating the gallery

Every assertion writes a `manifest.json` beside its images. Aggregate those into a catalog, then
render the catalog as a single HTML file.

```swift
let catalog = VisualTesting.generateCatalog(
    rootDirectory: "Tests/MyFeatureTests",
    outputPath: "snapshot-catalog.json"
)
VisualTesting.generateGallery(catalog: catalog, outputPath: "snapshot-gallery.html")
```

Open `snapshot-gallery.html` in a browser; the CSS, the JavaScript, and the catalog itself are all
inlined, so no server is involved. Image paths are relative to the catalog root, so keep the HTML
file there. The gallery filters by section, device, theme, and locale, searches by view name, puts
light and dark side by side, and opens any image in a lightbox.
