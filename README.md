English | [日本語](./README.ja.md)

# VisualTesting

SwiftUI snapshot testing library. Eliminates boilerplate with declarative macros and automatically generates snapshots across a device × theme × locale matrix.

![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)
![iOS 17+](https://img.shields.io/badge/iOS-17+-blue.svg)
![macOS 14+](https://img.shields.io/badge/macOS-14+-purple.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## Features

- **Declarative macros**: `@SnapshotSuite` / `@Snapshot` / `@ComponentSnapshot` — just return a View
- **Matrix testing**: Automatically generates every device × theme × locale combination
- **Device subdirectories**: Auto-organized at `__Snapshots__/{ViewName}/{device}/{stateName}.{theme}_{locale}.png`
- **iPad support**: iPhone 16, iPhone SE, and iPad Pro 11 supported by default (3 devices)
- **Metadata catalog**: Auto-generates per-view `manifest.json` and root `snapshot-catalog.json`
- **Theme system integration**: Connect any theme system via the `ThemeApplicable` protocol
- **View / Component separation**: Views use the full matrix; components use theme axis only
- **Swift Testing support**: Integrates with `@Suite` / `@Test`; reports failures via `Issue.record`

## Quick Start

```swift
import SwiftUI
import Testing
import VisualTesting

@SnapshotSuite("SettingsView")
@MainActor
struct SettingsViewSnapshots {
    init() { setupVisualTesting() }

    @Snapshot
    func loaded() -> some View {
        SettingsView()
    }

    @Snapshot
    @InNavigation
    @WithoutAnimation
    func editing() -> some View {
        SettingsView(isEditing: true)
    }

    @Test func snapshots() {
        for snapshotCase in Self.__snapshotCases { snapshotCase.run() }
    }
}
```

> **Note**: Each suite requires one hand-written runner test (`@Test func snapshots()`).
> The macro only collects `__snapshotCases` — generating `@Test` from a macro causes the
> compiler to lose lexical context and corrupts swift-testing's test records.
> A compile error with the exact line to add is emitted when the runner is missing.

These two functions automatically produce the following reference images:

```
__Snapshots__/
  SettingsView/
    iPhone16/
      loaded.light_en.png
      loaded.light_ja.png
      loaded.dark_en.png
      loaded.dark_ja.png
      editing.light_en.png
      ...
    iPhoneSE/
      loaded.light_en.png
      ...
    iPadPro11/
      loaded.light_en.png
      ...
    manifest.json                    ← per-view metadata (auto-generated)
```

## Installation

### Swift Package Manager

Add to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-visual-testing.git", from: "1.0.1")
]
```

Add to your test target:

```swift
.testTarget(
    name: "YourTests",
    dependencies: [
        .product(name: "VisualTesting", package: "swift-visual-testing")
    ]
)
```

## Usage

### View Snapshots

Use `@SnapshotSuite` and `@Snapshot` to capture full-screen Views. Each function just returns a View — the macro resolves viewName and stateName automatically.

```swift
@SnapshotSuite("MyView")
@MainActor
struct MyViewSnapshots {
    init() { setupVisualTesting() }

    @Snapshot
    func loaded() -> some View {
        MyView(state: .loaded)
    }

    @Snapshot
    func empty() -> some View {
        MyView(state: .empty)
    }

    @Test func snapshots() {
        for snapshotCase in Self.__snapshotCases { snapshotCase.run() }
    }
}
```

**Output**: `__Snapshots__/MyView/{device}/loaded.{theme}_{locale}.png`

The default configuration produces 3 devices × 2 themes × 2 locales = **12 snapshots**.

### Component Snapshots

Use `@ComponentSnapshot` to capture UI components (buttons, cards, etc.) at a fixed size. Theme axis only.

```swift
@SnapshotSuite("Card")
@MainActor
struct CardSnapshots {
    init() { setupVisualTesting() }

    @ComponentSnapshot(width: 340, height: 120)
    func level1() -> some View {
        Card(elevation: .level1) { Text("Card") }
            .frame(width: 300, height: 80).padding()
    }

    @ComponentSnapshot(width: 340, height: 120)
    func level2() -> some View {
        Card(elevation: .level2) { Text("Card") }
            .frame(width: 300, height: 80).padding()
    }

    @Test func snapshots() {
        for snapshotCase in Self.__snapshotCases { snapshotCase.run() }
    }
}
```

**Output**: `__Snapshots__/Card/level1.light.png`, `__Snapshots__/Card/level1.dark.png`

### Attribute Macros

Attach attribute macros to test functions to customize behavior.

```swift
@Snapshot
@InNavigation        // Wrap in NavigationStack
@WithoutAnimation    // Disable animations
func detail() -> some View {
    DetailView()
}
```

### Macro Reference

| Macro | Kind | Role |
|--------|------|------|
| `@SnapshotSuite("ViewName")` | MemberMacro | Collects `@Snapshot` / `@ComponentSnapshot` child functions into `__snapshotCases` (hand-written runner required) |
| `@Snapshot` | PeerMacro | Marks a function as a view snapshot target |
| `@ComponentSnapshot(width:height:)` | PeerMacro | Marks a function as a component target (with size) |
| `@InNavigation` | PeerMacro | Specifies `NavigationStack` wrapping |
| `@WithoutAnimation` | PeerMacro | Specifies animation disabling |

### Theme System Integration

By default, `environment(\.colorScheme, ...)` is used. To integrate a custom theme system (e.g. `ThemeProvider`), implement the `ThemeApplicable` protocol.

```swift
import DesignSystem
import SwiftUI
import VisualTesting

struct AppThemeApplicable: ThemeApplicable {
    @MainActor
    func applyTheme<V: View>(_ view: V, theme: SnapshotTheme) -> AnyView {
        let provider = ThemeProvider()
        provider.themeMode = theme == .light ? .light : .dark
        return AnyView(view.theme(provider))
    }
}

@MainActor
func setupVisualTesting() {
    VisualTesting.themeApplicable = AppThemeApplicable()
}
```

Call `setupVisualTesting()` in your test suite's `init()`.

### Customizing Configuration

Use `SnapshotConfiguration` to change the default matrix. Pass it as the `configuration` parameter when calling the direct API.

```swift
let config = SnapshotConfiguration(
    devices: [.iPhone16],
    themes: [.dark],
    locales: ["en"],
    precision: 0.99,
    perceptualPrecision: 0.98
)
```

### Recording Reference Images

On first run, or to re-record reference images, set an environment variable:

```bash
# Run in record mode for all snapshots
SNAPSHOT_TESTING_RECORD=all swift test
```

## Direct API

For more granular control without macros, use the direct API.

### View Snapshot

```swift
@Suite("MyView Snapshots")
@MainActor
struct MyViewSnapshots {
    init() { setupVisualTesting() }

    @Test("loaded")
    func loaded() {
        VisualTesting.assertViewSnapshot(
            of: MyView(),
            viewName: "MyView",
            stateName: "loaded",
            inNavigation: false,
            disableAnimations: true,
            file: #filePath, line: #line)
    }
}
```

### Component Snapshot

```swift
VisualTesting.assertComponentSnapshot(
    of: Card(elevation: .level1) { Text("Card") }
        .frame(width: 300, height: 80).padding(),
    componentName: "Card",
    stateName: "level1",
    size: CGSize(width: 340, height: 120),
    file: #filePath, line: #line)
```

## API Reference

### Macros

| Macro | Description |
|--------|------|
| `@SnapshotSuite("ViewName")` | Applied to a struct. Collects `@Snapshot` / `@ComponentSnapshot` child functions into `__snapshotCases`; a hand-written `@Test func snapshots()` runner is required |
| `@Snapshot` | View snapshot. All device × theme × locale combinations |
| `@ComponentSnapshot(width:height:)` | Component snapshot. Theme axis only |
| `@InNavigation` | Wrap in `NavigationStack` |
| `@WithoutAnimation` | Disable animations |

### VisualTesting (Direct API)

| Method | Description |
|---------|------|
| `assertViewSnapshot(of:viewName:stateName:inNavigation:disableAnimations:configuration:file:line:)` | Capture a View across device × theme × locale |
| `assertComponentSnapshot(of:componentName:stateName:size:configuration:file:line:)` | Capture a component across theme axis only |
| `generateCatalog(rootDirectory:outputPath:)` | Aggregate all manifest.json files into `snapshot-catalog.json` (returns `SnapshotCatalog`) |
| `generateGallery(catalog:outputPath:)` | Generate a self-contained HTML gallery from a catalog |
| `themeApplicable` | Theme application logic (customizable) |

### SnapshotConfiguration

| Property | Type | Default | Description |
|----------|------|---------|------|
| `devices` | `[SnapshotDevice]` | `[.iPhone16, .iPhoneSE, .iPadPro11]` | Target devices |
| `themes` | `[SnapshotTheme]` | `[.light, .dark]` | Target themes |
| `locales` | `[String]` | `["en", "ja"]` | Target locales |
| `precision` | `Float` | `0.99` | Pixel precision |
| `perceptualPrecision` | `Float` | `0.98` | Perceptual precision |

### SnapshotDevice

| Case | Screen Size | Scale |
|--------|----------|---------|
| `.iPhone16` | 393 × 852 | @3x |
| `.iPhoneSE` | 375 × 667 | @2x |
| `.iPadPro11` | 834 × 1194 | @2x |

### SnapshotTheme

| Case | Description |
|--------|------|
| `.light` | Light mode |
| `.dark` | Dark mode |

### ThemeApplicable

```swift
public protocol ThemeApplicable: Sendable {
    @MainActor
    func applyTheme<V: View>(_ view: V, theme: SnapshotTheme) -> AnyView
}
```

The default implementation `DefaultThemeApplicable` uses `environment(\.colorScheme, ...)`.

## Directory Structure

### View Snapshots

```
__Snapshots__/
  SettingsView/                        ← viewName (@SnapshotSuite argument)
    iPhone16/                          ← device subdirectory
      loaded.light_en.png              ← stateName.theme_locale
      loaded.light_ja.png
      loaded.dark_en.png
      loaded.dark_ja.png
      editing.light_en.png
      ...
    iPhoneSE/
      loaded.light_en.png
      ...
    iPadPro11/
      loaded.light_en.png
      ...
    manifest.json                      ← per-view metadata (auto-generated)
```

### Component Snapshots

```
__Snapshots__/
  Card/                                ← componentName (@SnapshotSuite argument)
    level1.light.png                   ← stateName.theme
    level1.dark.png
    level2.light.png
    level2.dark.png
    manifest.json                      ← per-view metadata (auto-generated)
```

## Metadata Catalog

A per-view `manifest.json` is auto-generated during each test run. Aggregate all manifests to produce a root catalog.

### Generating the Catalog

```swift
@Test("Generate snapshot catalog")
func generateCatalog() {
    let snapshotsRoot = // path to the __Snapshots__ directory
    let outputPath = // output path for snapshot-catalog.json
    VisualTesting.generateCatalog(rootDirectory: snapshotsRoot, outputPath: outputPath)
}
```

### Generating the HTML Gallery

Generate a browser-viewable HTML gallery from the catalog.

```swift
@Test("Generate snapshot catalog and gallery")
func generateCatalog() {
    let snapshotsRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    let catalogPath = snapshotsRoot.appendingPathComponent("snapshot-catalog.json").path
    let galleryPath = snapshotsRoot.appendingPathComponent("gallery.html").path

    let catalog = VisualTesting.generateCatalog(rootDirectory: snapshotsRoot.path, outputPath: catalogPath)
    VisualTesting.generateGallery(catalog: catalog, outputPath: galleryPath)
}
```

Open `gallery.html` in a browser after running tests (`open gallery.html`):

- Section / device / theme / locale filters
- Text search (real-time filter by View name)
- Compare mode (light vs dark side by side)
- Lightbox (click to enlarge + ← → keyboard navigation)
- Gallery dark mode toggle
- Lazy image loading

### manifest.json Example

```json
{
  "name": "SettingsView",
  "type": "view",
  "generatedAt": "2026-02-17T14:50:00Z",
  "states": {
    "loaded": {
      "inNavigation": false,
      "disableAnimations": false,
      "snapshots": [
        { "device": "iPhone16", "theme": "light", "locale": "en",
          "file": "iPhone16/loaded.light_en.png" }
      ]
    }
  }
}
```

## Dependencies

| Package | Purpose |
|-----------|------|
| [swift-syntax](https://github.com/swiftlang/swift-syntax) | Macro implementation |
| [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) | Snapshot engine |

## Documentation

Detailed API documentation is available on [GitHub Pages](https://no-problem-dev.github.io/swift-visual-testing/documentation/visualtesting/).

## License

MIT License — see [LICENSE](LICENSE) for details.
