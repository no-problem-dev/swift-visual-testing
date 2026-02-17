import Foundation

// MARK: - Per-View Manifest

/// Per-view snapshot manifest written to `__Snapshots__/{viewName}/manifest.json`.
public struct SnapshotManifest: Codable, Sendable {
    public var name: String
    public var type: SnapshotType
    public var generatedAt: String
    public var states: [String: StateManifest]
    public var basePath: String?
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

/// Snapshot type discriminator.
public enum SnapshotType: String, Codable, Sendable {
    case view
    case component
}

/// Per-state snapshot information within a manifest.
public struct StateManifest: Codable, Sendable {
    public var inNavigation: Bool
    public var disableAnimations: Bool
    public var snapshots: [SnapshotEntry]

    public init(inNavigation: Bool, disableAnimations: Bool, snapshots: [SnapshotEntry]) {
        self.inNavigation = inNavigation
        self.disableAnimations = disableAnimations
        self.snapshots = snapshots
    }
}

/// Individual snapshot image entry.
public struct SnapshotEntry: Codable, Sendable {
    public var device: String?
    public var theme: String
    public var locale: String?
    public var file: String

    public init(device: String?, theme: String, locale: String?, file: String) {
        self.device = device
        self.theme = theme
        self.locale = locale
        self.file = file
    }
}

// MARK: - Root Catalog

/// Root snapshot catalog aggregating all per-view manifests.
public struct SnapshotCatalog: Codable, Sendable {
    public var version: String
    public var generatedAt: String
    public var configuration: CatalogConfiguration
    public var summary: CatalogSummary
    public var views: [SnapshotManifest]
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

/// Configuration metadata for the catalog.
public struct CatalogConfiguration: Codable, Sendable {
    public var devices: [String]
    public var themes: [String]
    public var locales: [String]

    public init(devices: [String], themes: [String], locales: [String]) {
        self.devices = devices
        self.themes = themes
        self.locales = locales
    }
}

/// Summary statistics for the catalog.
public struct CatalogSummary: Codable, Sendable {
    public var totalViews: Int
    public var totalComponents: Int
    public var totalImages: Int
    public var byDevice: [String: Int]
    public var byTheme: [String: Int]

    public init(totalViews: Int, totalComponents: Int, totalImages: Int, byDevice: [String: Int], byTheme: [String: Int]) {
        self.totalViews = totalViews
        self.totalComponents = totalComponents
        self.totalImages = totalImages
        self.byDevice = byDevice
        self.byTheme = byTheme
    }
}
