# Changelog

All notable changes to this project are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [2.1.0] - 2026-08-02

### Added

- **iPad split widths on `SnapshotDevice`**: `iPadPro11Half` (597×834) and `iPadPro11Third`
  (398×834). iPadOS 26 dropped Split View and Slide Over for freely resizable windows, so the 1/2
  and 1/3 widths the HIG asks about are now capturable. Widths come from the landscape screen
  (1194pt) — a third of the portrait width (278pt) is below the minimum window width iPadOS allows
  and would capture a surface no user can produce. **Both widths land in the compact horizontal
  size class.**
- **`SnapshotDynamicType`, a text-size axis**: `.standard` (`.large`) and `.accessibility3`,
  selected through `SnapshotConfiguration.dynamicTypes`. Both the SwiftUI `\.dynamicTypeSize`
  environment and the `ViewImageConfig` `preferredContentSizeCategory` trait are set — with only the
  environment, the parts UIKit measures (navigation bars, minimum list row heights) stay at the
  default size.
- `SnapshotEntry.dynamicType` (`String?`), `nil` at the default size.
- `SnapshotConfiguration.standardDevices`, the three devices captured by default.

### Changed

- **`SnapshotConfiguration` now defaults to `standardDevices` instead of `SnapshotDevice.allCases`.**
  Otherwise every device added would silently raise the image count of every existing suite, and the
  surfaces with no reference image would surface as failures. Split widths are added explicitly by
  the suites that want them. **Reference images recorded under 2.0 remain valid** — the default
  matrix is unchanged, and only the accessibility size adds a `_{dynamicType}` suffix to file names.

## [2.0.1] - 2026-07-19

### Changed

- Doc comments and the DocC catalog rewritten; README split into English and Japanese editions.
- DocC published to GitHub Pages, with `/documentation/visualtesting` as the canonical route.
- CI workflows synced to the shared template (tests + release-on-tag); the old auto-release workflow
  was removed.

## [2.0.0] - 2026-06-06

### Changed

- **Breaking: `@Test` generation removed in favour of `SnapshotCase` collection.** Under Xcode 26.4,
  a macro-generated `@Test` loses the lexical context of its declaration and corrupts swift-testing's
  test records, so `@SnapshotSuite` now only collects `__snapshotCases`. Each suite declares its own
  runner:
  `@Test func snapshots() { for snapshotCase in Self.__snapshotCases { snapshotCase.run() } }`.
  Keep it in the suite's own file — `run(file:)` defaults to the caller's `#filePath`, and that is
  what decides where reference images are looked up.
- **Breaking: reference image paths restructured.** Views use
  `{view}/{device}/{state}.{theme}_{locale}.png` and components use `{component}/{state}.{theme}.png`.
  Images recorded under 1.x must be re-recorded.

### Fixed

- Runner detection tightened to require an actual reference to `__snapshotCases`, so a suite holding
  only direct-API tests no longer passes as if its collected cases had run.

## [1.3.1] - 2026-02-17

### Fixed

- Multiline string literals needed an explicit `return` under Swift 6.2.

## [1.3.0] - 2026-02-17

### Added

- HTML gallery generation (`generateGallery`), with `basePath` and `category` on manifests.

## [1.2.0] - 2026-02-17

### Added

- `SnapshotDevice.iPadPro11`.
- Per-device subdirectories, and the metadata catalog (`manifest.json`).

## [1.1.1] - 2026-02-17

### Fixed

- `SourceLocation` crash in macro-generated code.

## [1.1.0] - 2026-02-17

### Fixed

- `@Test` macro compatibility under the nested `@Suite` struct pattern.

## [1.0.1] - 2026-02-17

### Fixed

- Argument order in the `verifySnapshot` call.

## [1.0.0] - 2026-02-17

### Added

- **`@SnapshotSuite`**: marks a struct as a snapshot suite, discovering its `@Snapshot` and
  `@ComponentSnapshot` functions and generating the `@Test` methods that run them.
- **`@Snapshot`**: marks a view snapshot target, captured across every device × theme × locale
  combination into `__Snapshots__/{viewName}/{stateName}.{device}_{theme}_{locale}.png`.
- **`@ComponentSnapshot(width:height:)`**: marks a component target, captured on the theme axis
  alone with an optional explicit size.
- **`@InNavigation`** and **`@WithoutAnimation`**: `NavigationStack` wrapping and animation
  suppression.
- **`VisualTesting.assertViewSnapshot`** and **`VisualTesting.assertComponentSnapshot`**: the
  underlying assertions, resolving the snapshot directory from the calling file and delegating to
  swift-snapshot-testing's `verifySnapshot`.
- **`SnapshotConfiguration`**: `devices`, `themes`, `locales`, `precision`, `perceptualPrecision`.
- **`ThemeApplicable`**: a pluggable theme system, defaulting to the `colorScheme` environment.
- **`SnapshotDevice`** (iPhone 16, iPhone SE) and **`SnapshotTheme`** (light, dark).
