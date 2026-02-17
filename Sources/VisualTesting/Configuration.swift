#if canImport(UIKit)
import UIKit
import SnapshotTesting

// MARK: - SnapshotDevice

/// Device configuration for snapshot testing.
public enum SnapshotDevice: String, CaseIterable, Sendable {
    case iPhone16 = "iPhone16"
    case iPhoneSE = "iPhoneSE"
    case iPadPro11 = "iPadPro11"

    public var config: ViewImageConfig {
        switch self {
        case .iPhone16:
            return ViewImageConfig(
                safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
                size: CGSize(width: 393, height: 852),
                traits: UITraitCollection(traitsFrom: [
                    UITraitCollection(userInterfaceStyle: .light),
                    UITraitCollection(displayScale: 3),
                ])
            )
        case .iPhoneSE:
            return ViewImageConfig(
                safeArea: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0),
                size: CGSize(width: 375, height: 667),
                traits: UITraitCollection(traitsFrom: [
                    UITraitCollection(userInterfaceStyle: .light),
                    UITraitCollection(displayScale: 2),
                ])
            )
        case .iPadPro11:
            return ViewImageConfig(
                safeArea: UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0),
                size: CGSize(width: 834, height: 1194),
                traits: UITraitCollection(traitsFrom: [
                    UITraitCollection(userInterfaceStyle: .light),
                    UITraitCollection(displayScale: 2),
                ])
            )
        }
    }
}

// MARK: - SnapshotTheme

/// Theme configuration for snapshot testing.
public enum SnapshotTheme: String, CaseIterable, Sendable {
    case light
    case dark

    public var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - SnapshotConfiguration

/// Configuration for snapshot test matrix.
public struct SnapshotConfiguration: Sendable {
    public var devices: [SnapshotDevice]
    public var themes: [SnapshotTheme]
    public var locales: [String]
    public var precision: Float
    public var perceptualPrecision: Float

    public init(
        devices: [SnapshotDevice] = SnapshotDevice.allCases,
        themes: [SnapshotTheme] = SnapshotTheme.allCases,
        locales: [String] = ["en", "ja"],
        precision: Float = 0.99,
        perceptualPrecision: Float = 0.98
    ) {
        self.devices = devices
        self.themes = themes
        self.locales = locales
        self.precision = precision
        self.perceptualPrecision = perceptualPrecision
    }

    /// Default configuration: iPhone16 + iPhoneSE, light + dark, en + ja
    public static let `default` = SnapshotConfiguration()

    /// Component configuration: theme-only axis
    public static let component = SnapshotConfiguration(
        devices: [],
        themes: SnapshotTheme.allCases,
        locales: []
    )
}
#endif
