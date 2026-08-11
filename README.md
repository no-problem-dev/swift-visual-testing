English | [日本語](./README.ja.md)

# VisualTesting

Snapshot testing for SwiftUI: name the states you care about, and every device × theme × locale × text size combination is captured for you.

![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)
![iOS 17+](https://img.shields.io/badge/iOS-17+-blue.svg)
![macOS 14+](https://img.shields.io/badge/macOS-14+-purple.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## Overview

- **Declarative macros.** `@SnapshotSuite`, `@Snapshot`, `@ComponentSnapshot` — a function returns a View, and that is the whole test.
- **Matrix capture.** Three devices, light and dark, `en` and `ja` by default. iPadOS 26 window widths and accessibility text sizes are opt-in axes, so adding them never invalidates images you already recorded.
- **Views and components are separate.** Full-screen views use the matrix; design-system components use the theme axis alone.
- **Any theme system.** `ThemeApplicable` connects the theme axis to whatever actually drives appearance in your app, so snapshots exercise the same path the app does.
- **Browsable output.** Every run writes a `manifest.json` beside the images; those aggregate into a catalog and a self-contained HTML gallery with filters, search, and light/dark comparison.

## Usage

```swift
import SwiftUI
import Testing
import VisualTesting

@SnapshotSuite("SettingsView")
@MainActor
struct SettingsViewSnapshots {
    @Snapshot
    func loaded() -> some View {
        SettingsView()
    }

    @Test func snapshots() {
        for snapshotCase in Self.__snapshotCases { snapshotCase.run() }
    }
}
```

That single function records twelve reference images at
`__Snapshots__/SettingsView/{device}/loaded.{theme}_{locale}.png`.

The runner test is hand-written on purpose: a macro cannot expand `@Test` without corrupting
swift-testing's test records, so `@SnapshotSuite` only collects the cases. Omitting the runner is a
compile error that names the exact line to add.

## Documentation

[Getting Started and the full API reference](https://no-problem-dev.github.io/swift-visual-testing/documentation/visualtesting/)
cover component snapshots, custom theme systems, changing the matrix, recording reference images, and
generating the HTML gallery.

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-visual-testing.git", from: "3.0.0")
]
```

```swift
.testTarget(
    name: "YourTests",
    dependencies: [
        .product(name: "VisualTesting", package: "swift-visual-testing")
    ]
)
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
