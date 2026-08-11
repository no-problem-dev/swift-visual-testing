# Changelog

All notable changes to this project are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [3.0.1] - 2026-08-11

### Changed

- The documented way to re-record was `SNAPSHOT_TESTING_RECORD=all`, which is the slowest mode and
  produces the least reviewable result. `all` rewrites every image whether or not it matched and
  reports all of them as failures — nothing was compared, so nothing passed — which forces a second
  full run to learn whether the outcome is right. On swift-markdown-view's 136 images that is 272
  renders instead of 136, and a 136-file diff in which the real changes cannot be told from the
  churn. The guide now leads with `failed`, which renders once, writes only what differs, and passes
  on completion, and it names `missing` for adding cases to a suite you do not want to disturb.
  `all` is kept for the case it is actually good at: flushing drift that the precision tolerances
  have been absorbing — `perceptualPrecision: 0.98` does not fail on a 2–3 unit shift, and 46
  swift-design-system references had gone stale that way with only 2 ever failing.

## [3.0.0] - 2026-08-11

### Fixed

- **Dark captures were rendered under a light `UITraitCollection`.** Every `ViewImageConfig` hard-coded
  `userInterfaceStyle: .light`, so a dark snapshot had a dark `\.colorScheme` and a light trait
  collection underneath. SwiftUI's own drawing followed the environment, but the ground UIKit paints
  under a hosting controller followed the traits — a screen with no background of its own came back
  as a **white sheet with white text on it**, content present and invisible. `SnapshotTheme`'s
  existing `userInterfaceStyle` is now put on the traits of every view capture and passed to every
  component capture. SwiftUI re-resolves the UIKit values handed to it — `Color(uiColor:)` from a
  dynamic provider, a `UIView` inside a `UIViewRepresentable` — from `\.colorScheme`, so those were
  never wrong; what was wrong is everything SwiftUI does not draw itself. **Dark reference images
  recorded before this must be re-recorded**; light images are unchanged.
- **`inNavigation` and `disableAnimations` in `manifest.json` were frozen at first capture.** They now
  describe how the state is captured on the current run.

### Changed

- **`SnapshotManifest` no longer has `generatedAt`.** These files are committed beside the reference
  images, and a wall-clock timestamp rewritten on every run left the working tree dirty after every
  test run — which teaches everyone to discard snapshot output without reading it, the exact reflex
  that hides a real snapshot change. Every remaining field is a function of what was captured, so a
  dirty `manifest.json` now means the set of images changed. `SnapshotCatalog.generatedAt` stays: the
  catalog is regenerated on demand and is not committed.
- **`generateCatalog(rootDirectory:outputPath:)` and `generateGallery(catalog:outputPath:)` throw.**
  Every read and write in both was `try?`. An unreadable manifest was skipped, and a gallery that
  never reached disk returned as if it had — and a gallery missing a view looks exactly like a view
  nobody captured. Failures now surface as ``VisualTestingError``. A manifest that cannot be read or
  written during an assertion is recorded as an issue, the same way a mismatched image is.
- **`SnapshotDevice.config` is now `config(theme:dynamicType:)`.** The theme has to reach the traits,
  and one function building the traits from one geometry table replaces the parallel `config` /
  `config(dynamicType:)` pair. The geometry is available on its own as `size`, `safeArea`, and
  `displayScale`; `size` is non-optional, which removes the silent 393×852 fallback that stood in for
  a device with no size.
- **`@WithoutAnimation` is honoured on `@ComponentSnapshot`.** It was accepted and ignored. This adds
  `disableAnimations` to `SnapshotCase.Kind.component` and to `assertComponentSnapshot`.
- **`@InNavigation` on a `@ComponentSnapshot` is a compile error**, as is either marker on a function
  marked with neither capture attribute. A component is captured without a device frame, so there is
  no navigation bar for the image to hold; the attribute could never have done anything.
- **`@SnapshotSuite`'s runner detection reads tokens instead of source text.** Source text carries its
  comments, so a `@Test` mentioning `__snapshotCases` only in a commented-out line satisfied the
  check and took away the diagnostic from the one suite that needed it.

### Removed

- **`SnapshotConfiguration.component`.** A component capture reads the theme axis and the two
  precisions whatever it is handed, so this constant behaved identically to `.default` and its
  documentation described a behaviour it did not have.

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
