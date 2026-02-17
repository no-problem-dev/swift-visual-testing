#if canImport(UIKit)
import Foundation

extension VisualTesting {

    // MARK: - Per-View Manifest Update

    /// Update the per-view `manifest.json` after each assertion.
    /// Performs read-modify-write on `__Snapshots__/{viewName}/manifest.json`.
    static func updateManifest(
        viewName: String,
        type: SnapshotType,
        stateName: String,
        device: SnapshotDevice?,
        themes: [SnapshotTheme],
        locales: [String],
        inNavigation: Bool,
        disableAnimations: Bool,
        file: StaticString
    ) {
        let fileURL = URL(fileURLWithPath: "\(file)")
        let viewDir = fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__")
            .appendingPathComponent(viewName)
        let manifestURL = viewDir.appendingPathComponent("manifest.json")

        // Read existing manifest or create new
        var manifest: SnapshotManifest
        if let data = try? Data(contentsOf: manifestURL),
           let existing = try? JSONDecoder().decode(SnapshotManifest.self, from: data) {
            manifest = existing
        } else {
            manifest = SnapshotManifest(
                name: viewName,
                type: type,
                generatedAt: iso8601Now(),
                states: [:]
            )
        }

        // Build snapshot entries for this state + device
        var entries: [SnapshotEntry] = []

        if let device {
            // View snapshot: device subdirectory
            for theme in themes {
                for locale in locales {
                    let fileName = "\(device.rawValue)/\(stateName).\(theme.rawValue)_\(locale).png"
                    entries.append(SnapshotEntry(
                        device: device.rawValue,
                        theme: theme.rawValue,
                        locale: locale,
                        file: fileName
                    ))
                }
            }
        } else {
            // Component snapshot: no device subdirectory
            for theme in themes {
                let fileName = "\(stateName).\(theme.rawValue).png"
                entries.append(SnapshotEntry(
                    device: nil,
                    theme: theme.rawValue,
                    locale: nil,
                    file: fileName
                ))
            }
        }

        // Merge into existing state or create new
        if var existing = manifest.states[stateName] {
            // Append new entries, avoiding duplicates by file path
            let existingFiles = Set(existing.snapshots.map(\.file))
            for entry in entries where !existingFiles.contains(entry.file) {
                existing.snapshots.append(entry)
            }
            manifest.states[stateName] = existing
        } else {
            manifest.states[stateName] = StateManifest(
                inNavigation: inNavigation,
                disableAnimations: disableAnimations,
                snapshots: entries
            )
        }

        manifest.generatedAt = iso8601Now()

        // Write manifest
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(manifest) {
            try? FileManager.default.createDirectory(at: viewDir, withIntermediateDirectories: true)
            try? data.write(to: manifestURL)
        }
    }

    // MARK: - Root Catalog Generation

    /// Generate a root `snapshot-catalog.json` by aggregating all `manifest.json` files.
    ///
    /// - Parameter rootDirectory: The directory containing `__Snapshots__` subdirectories to scan.
    /// - Parameter outputPath: Path to write the catalog JSON file.
    /// - Returns: The generated `SnapshotCatalog`.
    @discardableResult
    public static func generateCatalog(rootDirectory: String, outputPath: String) -> SnapshotCatalog {
        let rootURL = URL(fileURLWithPath: rootDirectory)
        let fm = FileManager.default

        var views: [SnapshotManifest] = []
        var components: [SnapshotManifest] = []
        var allDevices: Set<String> = []
        var allThemes: Set<String> = []
        var allLocales: Set<String> = []
        var deviceCounts: [String: Int] = [:]
        var themeCounts: [String: Int] = [:]
        var totalImages = 0

        // Recursively find all manifest.json files
        let manifestFiles = findManifestFiles(in: rootURL, fileManager: fm)

        for manifestURL in manifestFiles {
            guard let data = try? Data(contentsOf: manifestURL),
                  var manifest = try? JSONDecoder().decode(SnapshotManifest.self, from: data) else {
                continue
            }

            // Compute basePath: relative path from rootDirectory to the manifest's directory
            let manifestDir = manifestURL.deletingLastPathComponent()
            manifest.basePath = relativePath(from: rootURL, to: manifestDir)

            // Compute category: directory name just before __Snapshots__
            // e.g. "Views/Dashboard/__Snapshots__/DashboardView" → "Dashboard"
            manifest.category = extractCategory(from: manifestDir, root: rootURL)

            switch manifest.type {
            case .view:
                views.append(manifest)
            case .component:
                components.append(manifest)
            }

            for (_, state) in manifest.states {
                for entry in state.snapshots {
                    totalImages += 1
                    if let device = entry.device {
                        allDevices.insert(device)
                        deviceCounts[device, default: 0] += 1
                    }
                    allThemes.insert(entry.theme)
                    themeCounts[entry.theme, default: 0] += 1
                    if let locale = entry.locale {
                        allLocales.insert(locale)
                    }
                }
            }
        }

        let catalog = SnapshotCatalog(
            generatedAt: iso8601Now(),
            configuration: CatalogConfiguration(
                devices: allDevices.sorted(),
                themes: allThemes.sorted(),
                locales: allLocales.sorted()
            ),
            summary: CatalogSummary(
                totalViews: views.count,
                totalComponents: components.count,
                totalImages: totalImages,
                byDevice: deviceCounts,
                byTheme: themeCounts
            ),
            views: views.sorted { $0.name < $1.name },
            components: components.sorted { $0.name < $1.name }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(catalog) {
            let outputURL = URL(fileURLWithPath: outputPath)
            try? fm.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? data.write(to: outputURL)
        }

        return catalog
    }

    // MARK: - Private Helpers

    private static func findManifestFiles(in directory: URL, fileManager: FileManager) -> [URL] {
        var results: [URL] = []
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return results
        }

        for case let fileURL as URL in enumerator {
            if fileURL.lastPathComponent == "manifest.json" {
                results.append(fileURL)
            }
        }
        return results
    }

    private static func iso8601Now() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: Date())
    }

    /// Compute the relative path from `base` to `target`.
    private static func relativePath(from base: URL, to target: URL) -> String {
        let basePath = base.standardizedFileURL.path
        let targetPath = target.standardizedFileURL.path
        guard targetPath.hasPrefix(basePath) else { return targetPath }
        var relative = String(targetPath.dropFirst(basePath.count))
        if relative.hasPrefix("/") {
            relative = String(relative.dropFirst())
        }
        return relative
    }

    /// Extract the category from a manifest directory path.
    ///
    /// Looks for `__Snapshots__` in the path and returns the directory name immediately before it.
    /// - `Views/Dashboard/__Snapshots__/DashboardView` → `"Dashboard"`
    /// - `DesignSystem/__Snapshots__/Card` → `nil` (top-level section, not a sub-category)
    private static func extractCategory(from manifestDir: URL, root: URL) -> String? {
        let rel = relativePath(from: root, to: manifestDir)
        let components = rel.split(separator: "/").map(String.init)
        guard let snapshotsIndex = components.firstIndex(of: "__Snapshots__"),
              snapshotsIndex >= 2 else {
            return nil
        }
        return components[snapshotsIndex - 1]
    }
}
#endif
