import Foundation

// MARK: - Per-View Manifest

/// Per-view snapshot manifest written to `__Snapshots__/{viewName}/manifest.json`.
///
/// Each view or component that runs through `VisualTesting` writes one manifest
/// alongside its PNG files. `generateCatalog(rootDirectory:outputPath:)` aggregates
/// these into a root `SnapshotCatalog`.
public struct SnapshotManifest: Codable, Sendable {
    /// The view or component name (matches the directory name under `__Snapshots__`).
    public var name: String
    /// Whether this manifest describes a full-view or a component.
    public var type: SnapshotType
    /// ISO 8601 timestamp of the last write.
    public var generatedAt: String
    /// Keyed by state name (e.g. `"loaded"`, `"empty"`), each entry lists its PNG files.
    public var states: [String: StateManifest]
    /// Relative path from the catalog root to this manifest's directory; set by `generateCatalog`.
    public var basePath: String?
    /// Optional grouping category derived from the directory hierarchy; set by `generateCatalog`.
    public var category: String?

    public init(
        name: String,
        type: SnapshotType,
        generatedAt: String,
        states: [String: StateManifest],
        basePath: String? = nil,
        category: String? = nil
    ) {
        self.name = name
        self.type = type
        self.generatedAt = generatedAt
        self.states = states
        self.basePath = basePath
        self.category = category
    }
}

/// Distinguishes a full-view snapshot suite from a component (design-system element) suite.
public enum SnapshotType: String, Codable, Sendable {
    /// A full-view snapshot captured across the device × theme × locale matrix.
    case view
    /// A component snapshot captured across the theme axis only (no device frame or locale).
    case component
}

/// Snapshot metadata for a single named state within a view or component suite.
public struct StateManifest: Codable, Sendable {
    /// Whether the view was wrapped in a `NavigationStack` during capture.
    public var inNavigation: Bool
    /// Whether UIKit animations were disabled during capture.
    public var disableAnimations: Bool
    /// All PNG image entries captured for this state.
    public var snapshots: [SnapshotEntry]

    public init(inNavigation: Bool, disableAnimations: Bool, snapshots: [SnapshotEntry]) {
        self.inNavigation = inNavigation
        self.disableAnimations = disableAnimations
        self.snapshots = snapshots
    }
}

/// A single PNG image entry within a `StateManifest`.
public struct SnapshotEntry: Codable, Sendable {
    /// Device identifier (e.g. `"iPhone16"`); `nil` for component snapshots.
    public var device: String?
    /// Theme raw value (e.g. `"light"` or `"dark"`).
    public var theme: String
    /// Locale identifier (e.g. `"en"`, `"ja"`); `nil` for component snapshots.
    public var locale: String?
    /// Relative file path from the manifest's directory to the PNG image.
    public var file: String

    public init(device: String?, theme: String, locale: String?, file: String) {
        self.device = device
        self.theme = theme
        self.locale = locale
        self.file = file
    }
}

// MARK: - Root Catalog

/// Root catalog that aggregates all per-view `SnapshotManifest` files in a directory tree.
///
/// Produced by `VisualTesting.generateCatalog(rootDirectory:outputPath:)` and consumed by
/// `VisualTesting.generateGallery(catalog:outputPath:)` to build an interactive HTML report.
public struct SnapshotCatalog: Codable, Sendable {
    /// Catalog schema version (currently `"1.0"`).
    public var version: String
    /// ISO 8601 timestamp of when the catalog was generated.
    public var generatedAt: String
    /// The set of devices, themes, and locales discovered across all manifests.
    public var configuration: CatalogConfiguration
    /// Aggregate counts of views, components, and images.
    public var summary: CatalogSummary
    /// All view manifests, sorted by name.
    public var views: [SnapshotManifest]
    /// All component manifests, sorted by name.
    public var components: [SnapshotManifest]

    public init(
        version: String = "1.0",
        generatedAt: String,
        configuration: CatalogConfiguration,
        summary: CatalogSummary,
        views: [SnapshotManifest],
        components: [SnapshotManifest]
    ) {
        self.version = version
        self.generatedAt = generatedAt
        self.configuration = configuration
        self.summary = summary
        self.views = views
        self.components = components
    }
}

/// The superset of devices, themes, and locales found across all manifests in a catalog.
public struct CatalogConfiguration: Codable, Sendable {
    /// All device identifiers present in the catalog (e.g. `["iPhone16", "iPhoneSE"]`).
    public var devices: [String]
    /// All theme raw values present in the catalog (e.g. `["dark", "light"]`).
    public var themes: [String]
    /// All locale identifiers present in the catalog (e.g. `["en", "ja"]`).
    public var locales: [String]

    public init(devices: [String], themes: [String], locales: [String]) {
        self.devices = devices
        self.themes = themes
        self.locales = locales
    }
}

/// Aggregate statistics for a `SnapshotCatalog`.
public struct CatalogSummary: Codable, Sendable {
    /// Number of distinct view suites.
    public var totalViews: Int
    /// Number of distinct component suites.
    public var totalComponents: Int
    /// Total PNG image count across all suites.
    public var totalImages: Int
    /// Image count keyed by device identifier.
    public var byDevice: [String: Int]
    /// Image count keyed by theme raw value.
    public var byTheme: [String: Int]

    public init(totalViews: Int, totalComponents: Int, totalImages: Int, byDevice: [String: Int], byTheme: [String: Int]) {
        self.totalViews = totalViews
        self.totalComponents = totalComponents
        self.totalImages = totalImages
        self.byDevice = byDevice
        self.byTheme = byTheme
    }
}
