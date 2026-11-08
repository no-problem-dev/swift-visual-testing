# Changelog

All notable changes to this project are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [3.0.3] - 2026-11-08

### Changed

- swift-docc-plugin への依存を外した（DocC は Xcode で開く）

## [3.0.2] - 2026-10-01

### Added

- **`SnapshotOutput.capture(directory:)`, a catalog that is looked at rather than asserted on.**
  Set as `SnapshotConfiguration.output`, every image is written under that directory on every run
  and nothing is compared. A screen catalog whose images are not committed — rebuilt each run and
  browsed through the gallery — had no way to run green: swift-snapshot-testing reports every write
  it makes as a failure, so the first run of such a catalog failed on every image, and so did every
  run after the directory was cleared. The layout under the directory is the one `__Snapshots__`
  has, `manifest.json` included, so `generateCatalog(rootDirectory:outputPath:)` reads it as is.
  An image that cannot be rendered or written is still recorded as an issue. The default stays
  `.references`.
- **`SnapshotDevice.iPhoneProMax`** (440×956, the 16 Pro Max and 17 Pro Max). It is the widest
  compact width an iPhone has, where a layout tuned at 393pt starts leaving gaps. It is not added to
  `standardDevices`, so no existing suite gains images.
- **The gallery reads two optional sidecars.** `thumbs/{path}.jpg` is shown in the grid in place of
  each PNG (the lightbox keeps the PNG), so a page of a thousand full-resolution PNGs (200 MB)
  no longer has to decode them all to scroll. `issues.js` (`window.SNAPSHOT_ISSUES`, image path → problems)
  outlines the flagged cards, prints their problems, and adds an "Issues only" filter. Both are
  written by whatever checks the images after the capture; without them the page is as before.

### Fixed

- **A capture drew Liquid Glass wrong or not at all.** A test bundle without a host app renders with
  `CALayer.render(in:)`, which skips Core Animation filters and backdrops. A toolbar symbol came out
  white on a light screen (its `vibrantColorMatrix` is what darkens it) and the glass behind it was
  missing. A capture now goes through its own renderer: the controller sits in a window and the run
  loop turns before drawing (switches and segmented controls are platform views and appear only
  then), a fitting height is measured in the window, each layer under a `vibrantColorMatrix` is
  drawn on top in the label color, and each glass shape gets a flat fill and a hairline. Reference
  comparison (`.references`) still goes through swift-snapshot-testing unchanged. A capture is now
  drawn at the device's own `displayScale`, so `iPhoneSE` comes out 750×1334 rather than at the host
  simulator's 3×.

- **A `@ComponentSnapshot` with a width and no height ignored the width.** The size was used only
  when both were given, so `@ComponentSnapshot(width: 393)` was captured at its intrinsic size and
  cut off at 852pt. A width alone now lays the component out at that width and lets it take the
  height it needs, with no cap — which is what capturing the whole of a scrolling screen's content
  needs. A component given both dimensions, or neither, is captured as before.

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
