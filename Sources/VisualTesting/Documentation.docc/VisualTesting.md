# ``VisualTesting``

Macro-driven snapshot testing for SwiftUI views and design-system components.

## Overview

A snapshot suite describes *what* to capture. One annotation on a struct, one function per state, and
the matrix — device × theme × locale × text size — is expanded for you; the macro and the assertion
engine decide *how* each image is produced and where it lands.

The matrix multiplies, so its default is deliberately small: three devices, light and dark, `en` and
`ja`, at the standard text size. Twelve images per state. The extra axes — the iPadOS 26 window widths
and the accessibility text sizes — are opt-in, which is what keeps adding one from silently changing
the image count of every suite that already exists.

Two capture shapes exist because two things are being tested. A full-screen view is worth seeing on
every device and in every language. A button is not: components are captured on the theme axis alone,
with no device frame, at a size you give them.

Start at <doc:GettingStarted>.

## Topics

### Getting started

- <doc:GettingStarted>

### Defining a suite

- ``SnapshotSuite(_:)``
- ``Snapshot()``
- ``ComponentSnapshot(width:height:)``
- ``InNavigation()``
- ``WithoutAnimation()``

### Running the cases

- ``SnapshotCase``
- ``SnapshotCase/Kind``
- ``SnapshotCase/run(configuration:file:line:)``

### Choosing the matrix

- ``SnapshotConfiguration``
- ``SnapshotDevice``
- ``SnapshotTheme``
- ``SnapshotDynamicType``

### Applying a theme

- ``ThemeApplicable``
- ``DefaultThemeApplicable``
- ``VisualTesting/themeApplicable``

### Asserting directly

- ``VisualTesting/assertViewSnapshot(of:viewName:stateName:inNavigation:disableAnimations:configuration:file:line:)``
- ``VisualTesting/assertComponentSnapshot(of:componentName:stateName:size:configuration:file:line:)``

### Catalog and gallery

- ``VisualTesting/generateCatalog(rootDirectory:outputPath:)``
- ``VisualTesting/generateGallery(catalog:outputPath:)``
- ``SnapshotCatalog``
- ``SnapshotManifest``
- ``SnapshotType``
- ``StateManifest``
- ``SnapshotEntry``
- ``CatalogConfiguration``
- ``CatalogSummary``
