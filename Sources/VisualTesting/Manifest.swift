import Foundation

// MARK: - Per-View Manifest

/// `__Snapshots__/{viewName}/manifest.json` に書き込まれる per-view スナップショットマニフェスト。
///
/// `VisualTesting` を通じて実行された View またはコンポーネントごとに、PNG ファイルと並んで
/// 1 つのマニフェストが生成される。`generateCatalog(rootDirectory:outputPath:)` はこれらを
/// 集約してルートの `SnapshotCatalog` を構築する。
public struct SnapshotManifest: Codable, Sendable {
    /// `__Snapshots__` 配下のディレクトリ名と一致する View またはコンポーネント名。
    public var name: String
    /// このマニフェストが全画面 View かコンポーネントかを示す。
    public var type: SnapshotType
    /// 最終書き込み時刻の ISO 8601 タイムスタンプ。
    public var generatedAt: String
    /// ステート名をキーに（例: `"loaded"`、`"empty"`）、各エントリが PNG ファイル一覧を持つ。
    public var states: [String: StateManifest]
    /// カタログルートからこのマニフェストのディレクトリへの相対パス。`generateCatalog` が設定する。
    public var basePath: String?
    /// ディレクトリ階層から導出したグループカテゴリ。`generateCatalog` が設定する。
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

/// 全画面 View のスナップショットスイートとコンポーネント（デザインシステム要素）スイートを区別する。
public enum SnapshotType: String, Codable, Sendable {
    /// デバイス × テーマ × ロケールのマトリクスでキャプチャした全画面 View スナップショット。
    case view
    /// テーマ軸のみでキャプチャしたコンポーネントスナップショット（デバイスフレーム・ロケールなし）。
    case component
}

/// View またはコンポーネントスイート内の 1 つの名前付きステートに対するスナップショットメタデータ。
public struct StateManifest: Codable, Sendable {
    /// キャプチャ時に `NavigationStack` でラップしたかどうか。
    public var inNavigation: Bool
    /// キャプチャ時に UIKit アニメーションを無効化したかどうか。
    public var disableAnimations: Bool
    /// このステートでキャプチャした全 PNG 画像エントリ。
    public var snapshots: [SnapshotEntry]

    public init(inNavigation: Bool, disableAnimations: Bool, snapshots: [SnapshotEntry]) {
        self.inNavigation = inNavigation
        self.disableAnimations = disableAnimations
        self.snapshots = snapshots
    }
}

/// `StateManifest` 内の 1 枚の PNG 画像エントリ。
public struct SnapshotEntry: Codable, Sendable {
    /// デバイス識別子（例: `"iPhone16"`）。コンポーネントスナップショットでは `nil`。
    public var device: String?
    /// テーマの raw value（例: `"light"` または `"dark"`）。
    public var theme: String
    /// ロケール識別子（例: `"en"`、`"ja"`）。コンポーネントスナップショットでは `nil`。
    public var locale: String?
    /// マニフェストのディレクトリから PNG 画像への相対ファイルパス。
    public var file: String

    public init(device: String?, theme: String, locale: String?, file: String) {
        self.device = device
        self.theme = theme
        self.locale = locale
        self.file = file
    }
}

// MARK: - Root Catalog

/// ディレクトリツリー内の全 per-view `SnapshotManifest` を集約したルートカタログ。
///
/// `VisualTesting.generateCatalog(rootDirectory:outputPath:)` が生成し、
/// `VisualTesting.generateGallery(catalog:outputPath:)` がインタラクティブな HTML レポートを構築する際に使用する。
public struct SnapshotCatalog: Codable, Sendable {
    /// カタログスキーマバージョン（現在は `"1.0"`）。
    public var version: String
    /// カタログ生成時刻の ISO 8601 タイムスタンプ。
    public var generatedAt: String
    /// 全マニフェストを横断して検出したデバイス・テーマ・ロケールのセット。
    public var configuration: CatalogConfiguration
    /// View・コンポーネント・画像の集計数。
    public var summary: CatalogSummary
    /// 名前順にソートされた全 View マニフェスト。
    public var views: [SnapshotManifest]
    /// 名前順にソートされた全コンポーネントマニフェスト。
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

/// カタログ内の全マニフェストを横断して検出したデバイス・テーマ・ロケールのスーパーセット。
public struct CatalogConfiguration: Codable, Sendable {
    /// カタログに含まれる全デバイス識別子（例: `["iPhone16", "iPhoneSE"]`）。
    public var devices: [String]
    /// カタログに含まれる全テーマ raw value（例: `["dark", "light"]`）。
    public var themes: [String]
    /// カタログに含まれる全ロケール識別子（例: `["en", "ja"]`）。
    public var locales: [String]

    public init(devices: [String], themes: [String], locales: [String]) {
        self.devices = devices
        self.themes = themes
        self.locales = locales
    }
}

/// `SnapshotCatalog` の集計統計。
public struct CatalogSummary: Codable, Sendable {
    /// 個別の View スイート数。
    public var totalViews: Int
    /// 個別のコンポーネントスイート数。
    public var totalComponents: Int
    /// 全スイートの PNG 画像合計枚数。
    public var totalImages: Int
    /// デバイス識別子をキーとした画像枚数。
    public var byDevice: [String: Int]
    /// テーマ raw value をキーとした画像枚数。
    public var byTheme: [String: Int]

    public init(totalViews: Int, totalComponents: Int, totalImages: Int, byDevice: [String: Int], byTheme: [String: Int]) {
        self.totalViews = totalViews
        self.totalComponents = totalComponents
        self.totalImages = totalImages
        self.byDevice = byDevice
        self.byTheme = byTheme
    }
}
