#if canImport(UIKit)
import UIKit
import SnapshotTesting

// MARK: - SnapshotDevice

/// スナップショットテスト用のデバイス設定。
public enum SnapshotDevice: String, CaseIterable, Sendable {
    case iPhone16 = "iPhone16"
    case iPhoneSE = "iPhoneSE"
    case iPadPro11 = "iPadPro11"

    /// デバイス固有の画面サイズ・セーフエリア・ピクセル密度を定義した `ViewImageConfig`。
    /// スナップショット撮影時にこの設定でビューをレンダリングする。
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

/// スナップショットテスト用のテーマ設定。
public enum SnapshotTheme: String, CaseIterable, Sendable {
    case light
    case dark

    /// テーマに対応する `UIUserInterfaceStyle`。スナップショット撮影時に `UITraitCollection` へ適用する。
    public var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - SnapshotConfiguration

/// スナップショットテストマトリクスの設定。
public struct SnapshotConfiguration: Sendable {
    /// テスト対象デバイスの一覧。
    public var devices: [SnapshotDevice]
    /// テスト対象テーマ（ライト / ダーク）の一覧。
    public var themes: [SnapshotTheme]
    /// テスト対象ロケールの一覧（例: `"en"`, `"ja"`）。
    public var locales: [String]
    /// ピクセル単位の一致精度。0〜1 の範囲で 1.0 が完全一致。
    public var precision: Float
    /// 知覚的な色差を許容する精度。アンチエイリアスのズレなど微細な差異を吸収する。
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

    /// デフォルト設定: iPhone16・iPhoneSE・iPadPro11、ライト・ダーク、en・ja。
    public static let `default` = SnapshotConfiguration()

    /// コンポーネントスナップショットスイート用設定。テーマ軸のみ（デバイスフレーム・ロケール変動なし）。
    ///
    /// `VisualTesting.assertComponentSnapshot` を直接呼び出す場合に使用する。
    /// `@ComponentSnapshot` 付き関数では自動的にこの設定が適用される。
    public static let component = SnapshotConfiguration(
        devices: [],
        themes: SnapshotTheme.allCases,
        locales: []
    )
}
#endif
