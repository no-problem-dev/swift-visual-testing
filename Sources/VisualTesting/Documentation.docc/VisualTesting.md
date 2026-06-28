# ``VisualTesting``

Macro-driven snapshot testing for SwiftUI views and design-system components.

## Overview

`VisualTesting` automates the full snapshot matrix — device × theme × locale — from a single
struct annotation. You describe *what* to capture; the macros and assertion engine handle *how*.

```swift
@SnapshotSuite("SettingsView")
@MainActor
struct SettingsViewSnapshots {

    @Snapshot
    func loaded() -> some View {
        SettingsView(model: .preview)
    }

    @Snapshot
    @InNavigation
    func inNavigation() -> some View {
        SettingsView(model: .preview)
    }

    @Test func snapshots() {
        for snapshotCase in Self.__snapshotCases {
            snapshotCase.run()
        }
    }
}
```

Running the test suite captures PNGs under `__Snapshots__/SettingsView/` for every combination
of device (iPhone 16, iPhone SE, iPad Pro 11), theme (light, dark), and locale (en, ja).

### Key types

| Symbol | Role |
|---|---|
| `SnapshotSuite(_:)` | Marks a struct as a snapshot test suite and collects cases |
| `Snapshot()` | Marks a factory function as a full-view snapshot target |
| `ComponentSnapshot(width:height:)` | Marks a factory as a component (theme-only) snapshot target |
| `InNavigation()` | Wraps the view in a `NavigationStack` during capture |
| `WithoutAnimation()` | Disables UIKit animations during capture |
| `SnapshotCase` | Runtime representation of one snapshot case; drives `run()` |
| `SnapshotConfiguration` | Configures the device × theme × locale matrix |
| `ThemeApplicable` | Protocol for injecting a custom theme system |

## Topics

### Essentials

- <doc:GettingStarted>

### Macros

- ``SnapshotSuite(_:)``
- ``Snapshot()``
- ``ComponentSnapshot(width:height:)``
- ``InNavigation()``
- ``WithoutAnimation()``

### Runtime

- ``SnapshotCase``
- ``SnapshotCase/Kind``
- ``SnapshotCase/run(configuration:file:line:)``

### Configuration

- ``SnapshotConfiguration``
- ``SnapshotDevice``
- ``SnapshotTheme``

### Theme Integration

- ``ThemeApplicable``
- ``DefaultThemeApplicable``
- ``VisualTesting/themeApplicable``

### Catalog and Gallery

- ``VisualTesting/generateCatalog(rootDirectory:outputPath:)``
- ``VisualTesting/generateGallery(catalog:outputPath:)``
- ``SnapshotCatalog``
- ``SnapshotManifest``
- ``SnapshotType``
- ``StateManifest``
- ``SnapshotEntry``
- ``CatalogConfiguration``
- ``CatalogSummary``
