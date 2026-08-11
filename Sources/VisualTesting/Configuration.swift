#if canImport(UIKit)
import SwiftUI
import UIKit
import SnapshotTesting

// MARK: - SnapshotDevice

/// A screen geometry to render into: point size, safe area, and pixel density.
public enum SnapshotDevice: String, CaseIterable, Sendable {
    case iPhone16 = "iPhone16"
    case iPhoneSE = "iPhoneSE"
    case iPadPro11 = "iPadPro11"
    /// A window about half the landscape width of an iPad Pro 11 (half of 1194pt).
    case iPadPro11Half = "iPadPro11Half"
    /// The same window at about a third of that width (a third of 1194pt).
    case iPadPro11Third = "iPadPro11Third"

    /// The screen size, safe area, and pixel density the view is rendered under.
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
        case .iPadPro11Half:
            return iPadWindow(width: 597)
        case .iPadPro11Third:
            return iPadWindow(width: 398)
        }
    }

    /// The same geometry with a text-size trait layered on top.
    ///
    /// SwiftUI follows the `\.dynamicTypeSize` environment on its own, but unless the same size
    /// is also put on the `ViewImageConfig` traits, **the parts UIKit measures — navigation bars,
    /// minimum list row heights — stay at the default size** and the image stops matching a device.
    public func config(dynamicType: SnapshotDynamicType) -> ViewImageConfig {
        var config = self.config
        config.traits = UITraitCollection(traitsFrom: [
            config.traits,
            UITraitCollection(preferredContentSizeCategory: dynamicType.contentSizeCategory),
        ])
        return config
    }

    /// An iPad geometry with only the window width changed.
    ///
    /// iPadOS 26 dropped Split View and Slide Over in favour of **freely resizable windows**, and the
    /// HIG asks for verification at 1/2, 1/3, and 1/4 of the screen. The widths are taken from the
    /// landscape screen (1194pt) — a third of the portrait width is 278pt, below the minimum window
    /// width iPadOS allows, so it would capture a surface no user can produce.
    ///
    /// **Both widths land in the compact horizontal size class** (an iPad turns regular at roughly
    /// 768pt and up). What these show is therefore the iPad falling into the same layout branch as an
    /// iPhone: width limits along the lines of `readableContentGuide`, and two-column layouts that
    /// assume regular, do not apply here.
    private func iPadWindow(width: CGFloat) -> ViewImageConfig {
        ViewImageConfig(
            safeArea: UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0),
            size: CGSize(width: width, height: 834),
            traits: UITraitCollection(traitsFrom: [
                UITraitCollection(userInterfaceStyle: .light),
                UITraitCollection(displayScale: 2),
            ])
        )
    }
}

// MARK: - SnapshotDynamicType

/// A text size to capture at.
///
/// Once typography follows Dynamic Type, **whether large text breaks the layout** becomes something
/// an image can show. Line heights, vertical centring against icons, and where truncation lands are
/// what break here.
public enum SnapshotDynamicType: String, CaseIterable, Sendable {
    /// The default size (`.large`). A suite that captures only this size gets no suffix in file names.
    case standard
    /// The middle of the accessibility sizes (`.accessibility3`).
    ///
    /// The checkpoint is here rather than at the largest size (`.accessibility5`) because
    /// **the largest size breaks no matter what**, which makes it useless for spotting a regression.
    case accessibility3

    /// The size SwiftUI lays out with, fed through the environment.
    public var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .standard: return .large
        case .accessibility3: return .accessibility3
        }
    }

    /// The size UIKit measures its own chrome with; set alongside `dynamicTypeSize` or the two disagree.
    public var contentSizeCategory: UIContentSizeCategory {
        switch self {
        case .standard: return .large
        case .accessibility3: return .accessibilityExtraLarge
        }
    }
}

// MARK: - SnapshotTheme

/// A light or dark appearance to capture. How it reaches the view is decided by `ThemeApplicable`.
public enum SnapshotTheme: String, CaseIterable, Sendable {
    case light
    case dark

    /// The UIKit appearance matching this theme, for callers that build their own `UITraitCollection`.
    public var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - SnapshotConfiguration

/// The matrix a suite captures: every device × theme × locale × text size combination is one image.
public struct SnapshotConfiguration: Sendable {
    /// Devices each view snapshot is repeated on. Every entry added multiplies the image count.
    public var devices: [SnapshotDevice]
    /// Appearances to capture. Component snapshots use this axis and nothing else.
    public var themes: [SnapshotTheme]
    /// Locale identifiers to render under, such as `"en"` or `"ja"`. Empty for components.
    public var locales: [String]
    /// Text sizes to capture. Defaults to `[.standard]`, so the axis costs nothing until asked for.
    public var dynamicTypes: [SnapshotDynamicType]
    /// Share of pixels that must match, 0 to 1. At the default 0.99 a one-point line can still pass.
    public var precision: Float
    /// How close each pixel's colour has to be, 0 to 1. Below 1 it absorbs anti-aliasing drift.
    public var perceptualPrecision: Float

    public init(
        devices: [SnapshotDevice] = SnapshotConfiguration.standardDevices,
        themes: [SnapshotTheme] = SnapshotTheme.allCases,
        locales: [String] = ["en", "ja"],
        dynamicTypes: [SnapshotDynamicType] = [.standard],
        precision: Float = 0.99,
        perceptualPrecision: Float = 0.98
    ) {
        self.devices = devices
        self.themes = themes
        self.locales = locales
        self.dynamicTypes = dynamicTypes
        self.precision = precision
        self.perceptualPrecision = perceptualPrecision
    }

    /// The devices captured unless a suite says otherwise.
    ///
    /// **Do not make `SnapshotDevice.allCases` the default.** Every device added would silently raise
    /// the number of images every existing suite captures, and the surfaces with no reference image
    /// would surface as failures. The split widths (`iPadPro11Half` / `iPadPro11Third`) are added
    /// explicitly by the suites that decided to capture them.
    public static let standardDevices: [SnapshotDevice] = [.iPhone16, .iPhoneSE, .iPadPro11]

    /// iPhone 16, iPhone SE, and iPad Pro 11, light and dark, en and ja, at the default text size.
    public static let `default` = SnapshotConfiguration()

    /// Theme axis only — no device frame, no locale variation.
    ///
    /// For calling `VisualTesting.assertComponentSnapshot` directly. Cases collected from
    /// `@ComponentSnapshot` do not pick this up; they run under whatever the runner passes.
    public static let component = SnapshotConfiguration(
        devices: [],
        themes: SnapshotTheme.allCases,
        locales: []
    )
}
#endif
