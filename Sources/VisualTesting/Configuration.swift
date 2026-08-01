#if canImport(UIKit)
import SwiftUI
import UIKit
import SnapshotTesting

// MARK: - SnapshotDevice

/// スナップショットテスト用のデバイス設定。
public enum SnapshotDevice: String, CaseIterable, Sendable {
    case iPhone16 = "iPhone16"
    case iPhoneSE = "iPhoneSE"
    case iPadPro11 = "iPadPro11"
    /// iPad Pro 11 の画面を横に並べたときの、幅がおよそ半分になるウィンドウ（1194 の 1/2）。
    case iPadPro11Half = "iPadPro11Half"
    /// 同じく幅がおよそ 1/3 になるウィンドウ（1194 の 1/3）。
    case iPadPro11Third = "iPadPro11Third"

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
        case .iPadPro11Half:
            return iPadWindow(width: 597)
        case .iPadPro11Third:
            return iPadWindow(width: 398)
        }
    }

    /// `config` に文字サイズの trait を重ねた設定。
    ///
    /// SwiftUI 側は `\.dynamicTypeSize` 環境で追随するが、`ViewImageConfig` の trait にも
    /// 同じ大きさを載せないと、**UIKit が寸法を計算する部分（ナビゲーションバー・
    /// リスト行の最小高）だけが既定の大きさのまま**になり、実機と違う絵が撮れる。
    public func config(dynamicType: SnapshotDynamicType) -> ViewImageConfig {
        var config = self.config
        config.traits = UITraitCollection(traitsFrom: [
            config.traits,
            UITraitCollection(preferredContentSizeCategory: dynamicType.contentSizeCategory),
        ])
        return config
    }

    /// iPad のウィンドウ幅だけを変えた設定。
    ///
    /// iPadOS 26 で Split View / Slide Over が廃止され、**自由にリサイズできるウィンドウ**に
    /// なった。HIG は画面の 1/2・1/3・1/4 の各幅で検証せよと書いている。
    /// 幅は横向き（1194pt）を基準に取る —— 縦向きの 1/3 は 278pt で、iPadOS が許す
    /// ウィンドウの最小幅を下回るため、実際には作れない面を撮ることになる。
    ///
    /// **どちらの幅も horizontal size class は compact になる**（iPad で regular に
    /// なるのはおよそ 768pt 以上）。つまりここで見えるのは、iPad なのに iPhone と同じ
    /// レイアウト分岐に落ちたときの姿で、`readableContentGuide` 相当の幅制限や
    /// regular 前提の 2 カラムはここでは効かない。
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

/// スナップショットテスト用の文字サイズ設定。
///
/// タイポグラフィが Dynamic Type に追随するようになると、**大きい文字で崩れるかどうか**が
/// 実際に撮れるようになる。行の高さ・アイコンとの垂直中心・省略の入り方はここで壊れる。
public enum SnapshotDynamicType: String, CaseIterable, Sendable {
    /// 既定の文字サイズ（`.large`）。この軸だけのときはファイル名に現れない。
    case standard
    /// アクセシビリティサイズの中ほど（`.accessibility3`）。
    ///
    /// 最大（`.accessibility5`）ではなくここを既定の検査点にするのは、
    /// **最大は何をしても崩れる**ので回帰の判別に使えないから。
    case accessibility3

    /// SwiftUI 環境に流す文字サイズ。
    public var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .standard: return .large
        case .accessibility3: return .accessibility3
        }
    }

    /// UIKit 側の寸法計算に効かせる content size category。
    public var contentSizeCategory: UIContentSizeCategory {
        switch self {
        case .standard: return .large
        case .accessibility3: return .accessibilityExtraLarge
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
    /// テスト対象の文字サイズ一覧。既定は `[.standard]`（軸を増やさない）。
    public var dynamicTypes: [SnapshotDynamicType]
    /// ピクセル単位の一致精度。0〜1 の範囲で 1.0 が完全一致。
    public var precision: Float
    /// 知覚的な色差を許容する精度。アンチエイリアスのズレなど微細な差異を吸収する。
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

    /// 既定で撮る端末。
    ///
    /// **`SnapshotDevice.allCases` を既定にしない。** 端末を 1 つ足すたびに、
    /// 既存の全スイートが撮る枚数が黙って増え、参照画像の無い面が失敗として現れる。
    /// 分割幅（`iPadPro11Half` / `iPadPro11Third`）は、撮ると決めたスイートだけが明示的に足す。
    public static let standardDevices: [SnapshotDevice] = [.iPhone16, .iPhoneSE, .iPadPro11]

    /// デフォルト設定: iPhone16・iPhoneSE・iPadPro11、ライト・ダーク、en・ja、既定の文字サイズ。
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
