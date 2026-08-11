import Foundation

// MARK: - Per-View Manifest

/// What a single view or component captured, written beside its PNGs as `manifest.json`.
///
/// One file per view or component. `generateCatalog(rootDirectory:outputPath:)` is what gathers them
/// into a root `SnapshotCatalog`.
public struct SnapshotManifest: Codable, Sendable {
    /// The name, which is also the directory name under `__Snapshots__`.
    public var name: String
    /// Which capture shape produced this file; it decides whether entries carry a device and locale.
    public var type: SnapshotType
    /// ISO 8601 timestamp of the last write. Rewritten on every assertion, not only on change.
    public var generatedAt: String
    /// Keyed by state name, such as `"loaded"` or `"empty"`; each value lists that state's images.
    public var states: [String: StateManifest]
    /// Path from the catalog root to this directory. Nil on disk; `generateCatalog` fills it in.
    public var basePath: String?
    /// Grouping taken from the directory above `__Snapshots__`. Nil on disk; `generateCatalog` fills it in.
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

/// Tells a full-screen view suite apart from a design-system component suite.
public enum SnapshotType: String, Codable, Sendable {
    /// Captured across the device × theme × locale matrix.
    case view
    /// Captured on the theme axis alone — no device frame, no locale.
    case component
}

/// One named state of a suite, and every image captured for it.
public struct StateManifest: Codable, Sendable {
    /// Whether the view was wrapped in a `NavigationStack` when captured.
    public var inNavigation: Bool
    /// Whether UIKit animations were off when captured.
    public var disableAnimations: Bool
    /// Every image captured for this state, one per matrix combination.
    public var snapshots: [SnapshotEntry]

    public init(inNavigation: Bool, disableAnimations: Bool, snapshots: [SnapshotEntry]) {
        self.inNavigation = inNavigation
        self.disableAnimations = disableAnimations
        self.snapshots = snapshots
    }
}

/// One captured image, and the matrix position it came from.
public struct SnapshotEntry: Codable, Sendable {
    /// Device identifier such as `"iPhone16"`; `nil` for components, which have no device frame.
    public var device: String?
    /// Theme raw value, `"light"` or `"dark"` — the one axis every capture has.
    public var theme: String
    /// Locale identifier such as `"en"` or `"ja"`; `nil` for components.
    public var locale: String?
    /// Text size raw value such as `"accessibility3"`; `nil` at the default size, matching the file name.
    public var dynamicType: String?
    /// Path to the image, relative to this manifest's directory.
    public var file: String

    public init(device: String?, theme: String, locale: String?, dynamicType: String? = nil, file: String) {
        self.device = device
        self.theme = theme
        self.locale = locale
        self.dynamicType = dynamicType
        self.file = file
    }
}

// MARK: - Root Catalog

/// Every manifest under a directory tree, gathered into one value.
///
/// Built by `VisualTesting.generateCatalog(rootDirectory:outputPath:)` and consumed by
/// `VisualTesting.generateGallery(catalog:outputPath:)`.
public struct SnapshotCatalog: Codable, Sendable {
    /// Schema version of this file, currently `"1.0"`; readers should check it before trusting fields.
    public var version: String
    /// ISO 8601 timestamp of when the catalog was assembled.
    public var generatedAt: String
    /// The axes actually observed, which is what the gallery builds its filter chips from.
    public var configuration: CatalogConfiguration
    /// Counts for the gallery header, so it need not walk the manifests to show totals.
    public var summary: CatalogSummary
    /// View manifests, sorted by name.
    public var views: [SnapshotManifest]
    /// Component manifests, sorted by name.
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

/// The union of every axis value seen in a catalog — what was captured, not what was configured.
public struct CatalogConfiguration: Codable, Sendable {
    /// Every device identifier present, sorted.
    public var devices: [String]
    /// Every theme raw value present, sorted.
    public var themes: [String]
    /// Every locale identifier present, sorted. Empty when the catalog holds components only.
    public var locales: [String]

    public init(devices: [String], themes: [String], locales: [String]) {
        self.devices = devices
        self.themes = themes
        self.locales = locales
    }
}

/// Totals for a catalog, counted while the manifests were being merged.
public struct CatalogSummary: Codable, Sendable {
    /// Number of view suites, not of images.
    public var totalViews: Int
    /// Number of component suites, not of images.
    public var totalComponents: Int
    /// Images across every suite — the number that grows fastest when an axis is added.
    public var totalImages: Int
    /// Image count per device identifier.
    public var byDevice: [String: Int]
    /// Image count per theme raw value.
    public var byTheme: [String: Int]

    public init(totalViews: Int, totalComponents: Int, totalImages: Int, byDevice: [String: Int], byTheme: [String: Int]) {
        self.totalViews = totalViews
        self.totalComponents = totalComponents
        self.totalImages = totalImages
        self.byDevice = byDevice
        self.byTheme = byTheme
    }
}
