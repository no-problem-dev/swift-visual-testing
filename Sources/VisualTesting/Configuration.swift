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

    /// The point size of the screen the view is rendered into.
    public var size: CGSize { geometry.size }

    /// The insets the status bar and home indicator take out of that screen.
    public var safeArea: UIEdgeInsets { geometry.safeArea }

    /// The pixel density this device stands for, put on the capture as a trait.
    ///
    /// It does not decide the size of the PNG. Measured on an iPhone 17 simulator, an `iPadPro11`
    /// capture comes out 2502×3582 — 834×1194 at **3×**, the host simulator's screen scale, not the
    /// 2× declared here. Reference images are therefore only comparable across machines running the
    /// same simulator.
    public var displayScale: CGFloat { geometry.displayScale }

    /// The geometry, appearance, and text size the view is rendered under.
    ///
    /// **The theme has to be here, not only in the SwiftUI environment.** `\.colorScheme` reaches
    /// what SwiftUI draws itself, and SwiftUI re-resolves the UIKit values it is handed — a
    /// `Color(uiColor:)` built from a dynamic provider, a `UIView` inside a `UIViewRepresentable` —
    /// from that same environment. What it does not reach is everything SwiftUI does not draw:
    /// above all **the ground the hosting controller paints**, which is the whole image for a screen
    /// with no background of its own. That is resolved against this `UITraitCollection`. Leave it
    /// light and a dark capture comes back as a white sheet with white text on it.
    ///
    /// The text size is here for the same reason: SwiftUI follows `\.dynamicTypeSize` on its own,
    /// but **the parts UIKit measures — navigation bars, minimum list row heights — stay at the
    /// default size** unless the trait says otherwise, and the image stops matching a device.
    public func config(theme: SnapshotTheme, dynamicType: SnapshotDynamicType = .standard) -> ViewImageConfig {
        let geometry = self.geometry
        return ViewImageConfig(
            safeArea: geometry.safeArea,
            size: geometry.size,
            traits: UITraitCollection { traits in
                traits.userInterfaceStyle = theme.userInterfaceStyle
                traits.displayScale = geometry.displayScale
                traits.preferredContentSizeCategory = dynamicType.contentSizeCategory
            }
        )
    }

    // MARK: - Geometry

    private struct Geometry {
        let size: CGSize
        let safeArea: UIEdgeInsets
        let displayScale: CGFloat
    }

    /// The screen this device stands for.
    ///
    /// The two iPad entries are the same screen at a narrower window width. iPadOS 26 dropped Split
    /// View and Slide Over in favour of **freely resizable windows**, and the HIG asks for
    /// verification at 1/2, 1/3, and 1/4 of the screen. The widths are taken from the landscape
    /// screen (1194pt) — a third of the portrait width is 278pt, below the minimum window width
    /// iPadOS allows, so it would capture a surface no user can produce.
    ///
    /// **Both narrow widths land in the compact horizontal size class** (an iPad turns regular at
    /// roughly 768pt and up). What they show is therefore the iPad falling into the same layout
    /// branch as an iPhone: width limits along the lines of `readableContentGuide`, and two-column
    /// layouts that assume regular, do not apply there.
    private var geometry: Geometry {
        switch self {
        case .iPhone16:
            Geometry(
                size: CGSize(width: 393, height: 852),
                safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
                displayScale: 3
            )
        case .iPhoneSE:
            Geometry(
                size: CGSize(width: 375, height: 667),
                safeArea: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0),
                displayScale: 2
            )
        case .iPadPro11:
            Geometry(
                size: CGSize(width: 834, height: 1194),
                safeArea: UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0),
                displayScale: 2
            )
        case .iPadPro11Half:
            Geometry(
                size: CGSize(width: 597, height: 834),
                safeArea: UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0),
                displayScale: 2
            )
        case .iPadPro11Third:
            Geometry(
                size: CGSize(width: 398, height: 834),
                safeArea: UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0),
                displayScale: 2
            )
        }
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

/// A light or dark appearance to capture.
///
/// It reaches a capture along two paths, and both are needed. `ThemeApplicable` puts it into the
/// SwiftUI environment, which is what SwiftUI's own drawing follows; `userInterfaceStyle` puts it
/// into the `UITraitCollection` the image is rendered under, which is what everything outside that
/// environment — the ground under the view most of all — follows.
public enum SnapshotTheme: String, CaseIterable, Sendable {
    case light
    case dark

    /// The UIKit appearance matching this theme, put on the traits every capture is rendered under.
    public var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - SnapshotConfiguration

/// The matrix a suite captures: every device × theme × locale × text size combination is one image.
///
/// A component capture reads the theme axis and the two precisions and ignores the rest — it has no
/// device frame and no locale — so the same configuration can drive a suite holding both shapes.
public struct SnapshotConfiguration: Sendable {
    /// Devices each view snapshot is repeated on. Every entry added multiplies the image count.
    public var devices: [SnapshotDevice]
    /// Appearances to capture. The one axis both capture shapes read.
    public var themes: [SnapshotTheme]
    /// Locale identifiers to render under, such as `"en"` or `"ja"`.
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
}
#endif
