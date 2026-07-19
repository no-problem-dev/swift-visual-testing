[English](./README.md) | 日本語

# VisualTesting

SwiftUI向けのスナップショットテストライブラリ。宣言的マクロでボイラープレートを排除し、デバイス × テーマ × ロケールのマトリクスで自動的にスナップショットを生成する。

![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)
![iOS 17+](https://img.shields.io/badge/iOS-17+-blue.svg)
![macOS 14+](https://img.shields.io/badge/macOS-14+-purple.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 特徴

- **宣言的マクロ**: `@SnapshotSuite` / `@Snapshot` / `@ComponentSnapshot` で View を返すだけ
- **マトリクステスト**: デバイス × テーマ × ロケールの全組み合わせを自動生成
- **デバイスサブディレクトリ**: `__Snapshots__/{ViewName}/{device}/{stateName}.{theme}_{locale}.png` で自動整理
- **iPad 対応**: iPhone16 + iPhoneSE + iPadPro11 の3デバイスをデフォルトサポート
- **メタデータカタログ**: per-view `manifest.json` とルート `snapshot-catalog.json` を自動生成
- **テーマシステム統合**: `ThemeApplicable` プロトコルで任意のテーマシステムと接続
- **View / Component 分離**: View は全軸マトリクス、コンポーネントはテーマ軸のみでテスト
- **Swift Testing 対応**: 収集された `SnapshotCase` を 1 つの手書き `@Test` から実行する。失敗は `Issue.record` で報告される

## クイックスタート

```swift
import SwiftUI
import Testing
import VisualTesting

@SnapshotSuite("SettingsView")
@MainActor
struct SettingsViewSnapshots {
    init() { setupVisualTesting() }

    @Snapshot
    func loaded() -> some View {
        SettingsView()
    }

    @Snapshot
    @InNavigation
    @WithoutAnimation
    func editing() -> some View {
        SettingsView(isEditing: true)
    }

    @Test func snapshots() {
        for snapshotCase in Self.__snapshotCases { snapshotCase.run() }
    }
}
```

> **Note**: 各スイートには手書きのランナーテスト（`@Test func snapshots()`）が 1 つ必要。
> マクロは `__snapshotCases` の収集のみを行う — `@Test` をマクロ生成すると
> コンパイラが lexical context を失い、swift-testing のテストレコードが壊れるためである
> （ランナーが無い場合はコンパイルエラーで正確な追加行を提示する）。

この2つの関数から、以下のリファレンス画像が自動生成される：

```
__Snapshots__/
  SettingsView/
    iPhone16/
      loaded.light_en.png
      loaded.light_ja.png
      loaded.dark_en.png
      loaded.dark_ja.png
      editing.light_en.png
      ...
    iPhoneSE/
      loaded.light_en.png
      ...
    iPadPro11/
      loaded.light_en.png
      ...
    manifest.json                    ← per-view メタデータ (自動生成)
```

## インストール

### Swift Package Manager

`Package.swift` に以下を追加：

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-visual-testing.git", from: "2.0.0")
]
```

テストターゲットに追加：

```swift
.testTarget(
    name: "YourTests",
    dependencies: [
        .product(name: "VisualTesting", package: "swift-visual-testing")
    ]
)
```

## 使い方

### View スナップショット

`@SnapshotSuite` と `@Snapshot` で画面全体の View をキャプチャする。関数は View を返すだけ。viewName / stateName はマクロが自動的に解決する。

```swift
@SnapshotSuite("MyView")
@MainActor
struct MyViewSnapshots {
    init() { setupVisualTesting() }

    @Snapshot
    func loaded() -> some View {
        MyView(state: .loaded)
    }

    @Snapshot
    func empty() -> some View {
        MyView(state: .empty)
    }

    @Test func snapshots() {
        for snapshotCase in Self.__snapshotCases { snapshotCase.run() }
    }
}
```

**出力**: `__Snapshots__/MyView/{device}/loaded.{theme}_{locale}.png`

デフォルトで 3デバイス × 2テーマ × 2ロケール = **12枚** のスナップショットが生成される。

### コンポーネントスナップショット

`@ComponentSnapshot` でUIコンポーネント（ボタン、カードなど）を固定サイズでキャプチャする。テーマ軸のみ。

```swift
@SnapshotSuite("Card")
@MainActor
struct CardSnapshots {
    init() { setupVisualTesting() }

    @ComponentSnapshot(width: 340, height: 120)
    func level1() -> some View {
        Card(elevation: .level1) { Text("Card") }
            .frame(width: 300, height: 80).padding()
    }

    @ComponentSnapshot(width: 340, height: 120)
    func level2() -> some View {
        Card(elevation: .level2) { Text("Card") }
            .frame(width: 300, height: 80).padding()
    }

    @Test func snapshots() {
        for snapshotCase in Self.__snapshotCases { snapshotCase.run() }
    }
}
```

**出力**: `__Snapshots__/Card/level1.light.png`, `__Snapshots__/Card/level1.dark.png`

### 属性マクロ

テスト関数に属性マクロを付与して振る舞いをカスタマイズする。

```swift
@Snapshot
@InNavigation        // NavigationStack でラップ
@WithoutAnimation    // アニメーション無効化
func detail() -> some View {
    DetailView()
}
```

### マクロ一覧

| マクロ | 種類 | 役割 |
|--------|------|------|
| `@SnapshotSuite("ViewName")` | MemberMacro | `@Snapshot` / `@ComponentSnapshot` 付き子関数を `__snapshotCases` に収集する（手書きのランナーが必要） |
| `@Snapshot` | PeerMacro | View スナップショット対象のマーカー |
| `@ComponentSnapshot(width:height:)` | PeerMacro | コンポーネント対象のマーカー（サイズ指定） |
| `@InNavigation` | PeerMacro | `NavigationStack` ラップを指定 |
| `@WithoutAnimation` | PeerMacro | アニメーション無効化を指定 |

### テーマシステムの統合

デフォルトでは `environment(\.colorScheme, ...)` を使用する。カスタムテーマシステム（例: `ThemeProvider`）を使用する場合は、`ThemeApplicable` プロトコルを実装する。

```swift
import DesignSystem
import SwiftUI
import VisualTesting

struct AppThemeApplicable: ThemeApplicable {
    @MainActor
    func applyTheme<V: View>(_ view: V, theme: SnapshotTheme) -> AnyView {
        let provider = ThemeProvider()
        provider.themeMode = theme == .light ? .light : .dark
        return AnyView(view.theme(provider))
    }
}

@MainActor
func setupVisualTesting() {
    VisualTesting.themeApplicable = AppThemeApplicable()
}
```

テストの `init()` で `setupVisualTesting()` を呼び出す。

### 設定のカスタマイズ

デフォルトのマトリクス構成を変更する場合は `SnapshotConfiguration` を使用する。直接 API を呼び出す場合に `configuration` パラメータとして渡す。

```swift
let config = SnapshotConfiguration(
    devices: [.iPhone16],
    themes: [.dark],
    locales: ["en"],
    precision: 0.99,
    perceptualPrecision: 0.98
)
```

### リファレンス画像の記録

初回実行時、またはリファレンス画像を再記録する場合は記録モードの環境変数を設定する。

`VisualTesting` は UIKit の上に作られているため、テストは `swift test` ではなく `xcodebuild` で iOS シミュレータ上で実行する。環境変数には `TEST_RUNNER_` プレフィックスを付ける。`xcodebuild` がこのプレフィックス付きの変数をテストランナープロセスへ渡し、そこで swift-snapshot-testing が `SNAPSHOT_TESTING_RECORD` として読み取る。

```bash
# 全スナップショットを記録モードで実行
TEST_RUNNER_SNAPSHOT_TESTING_RECORD=all xcodebuild test \
  -scheme YourScheme \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## 直接 API

マクロを使わず、より細かい制御が必要な場合は直接 API を使用できる。

### View スナップショット

```swift
@Suite("MyView Snapshots")
@MainActor
struct MyViewSnapshots {
    init() { setupVisualTesting() }

    @Test("loaded")
    func loaded() {
        VisualTesting.assertViewSnapshot(
            of: MyView(),
            viewName: "MyView",
            stateName: "loaded",
            inNavigation: false,
            disableAnimations: true,
            file: #filePath, line: #line)
    }
}
```

### コンポーネントスナップショット

```swift
VisualTesting.assertComponentSnapshot(
    of: Card(elevation: .level1) { Text("Card") }
        .frame(width: 300, height: 80).padding(),
    componentName: "Card",
    stateName: "level1",
    size: CGSize(width: 340, height: 120),
    file: #filePath, line: #line)
```

## API リファレンス

### マクロ

| マクロ | 説明 |
|--------|------|
| `@SnapshotSuite("ViewName")` | struct に付与。`@Snapshot` / `@ComponentSnapshot` 付き子関数を `__snapshotCases` に収集する。手書きのランナー（`@Test func snapshots()`）が必要 |
| `@Snapshot` | View スナップショット。デバイス × テーマ × ロケールの全組み合わせ |
| `@ComponentSnapshot(width:height:)` | コンポーネントスナップショット。テーマ軸のみ |
| `@InNavigation` | `NavigationStack` でラップ |
| `@WithoutAnimation` | アニメーション無効化 |

### SnapshotCase

収集された 1 つのスナップショットケース。`@SnapshotSuite` が `@Snapshot` / `@ComponentSnapshot` 付き関数を `static var __snapshotCases: [SnapshotCase]` プロパティに集め、手書きのランナーがそれを実行する。

```swift
public struct SnapshotCase: Sendable, CustomTestStringConvertible {
    public enum Kind: Sendable {
        case view(inNavigation: Bool, disableAnimations: Bool)
        case component(width: CGFloat?, height: CGFloat?)
    }

    public let viewName: String
    public let stateName: String
    public let kind: Kind

    @MainActor
    public func run(
        configuration: SnapshotConfiguration = .default,
        file: StaticString = #filePath,
        line: UInt = #line
    )
}
```

`run()` は `kind` に応じて `assertViewSnapshot` または `assertComponentSnapshot` を呼び分ける。`file` は呼び出し位置の `#filePath` がデフォルトになる。そのためスイート自身のファイルから `run()` を呼ぶことで、そのテストソースの隣の `__Snapshots__` ディレクトリに画像が解決される。スイート単位でマトリクスを変える場合は `configuration:` を渡す。

### VisualTesting（直接 API）

| メソッド | 説明 |
|---------|------|
| `assertViewSnapshot(of:viewName:stateName:inNavigation:disableAnimations:configuration:file:line:)` | View をデバイス × テーマ × ロケールでキャプチャ |
| `assertComponentSnapshot(of:componentName:stateName:size:configuration:file:line:)` | コンポーネントをテーマ軸のみでキャプチャ |
| `generateCatalog(rootDirectory:outputPath:)` | 全 manifest.json を集約して `snapshot-catalog.json` を生成（戻り値: `SnapshotCatalog`） |
| `generateGallery(catalog:outputPath:)` | カタログから自己完結型 HTML ギャラリーを生成 |
| `themeApplicable` | テーマ適用ロジック（カスタマイズ可能） |

### SnapshotConfiguration

| プロパティ | 型 | デフォルト値 | 説明 |
|----------|------|------------|------|
| `devices` | `[SnapshotDevice]` | `[.iPhone16, .iPhoneSE, .iPadPro11]` | テスト対象デバイス |
| `themes` | `[SnapshotTheme]` | `[.light, .dark]` | テスト対象テーマ |
| `locales` | `[String]` | `["en", "ja"]` | テスト対象ロケール |
| `precision` | `Float` | `0.99` | ピクセル精度 |
| `perceptualPrecision` | `Float` | `0.98` | 知覚的精度 |

### SnapshotDevice

| ケース | 画面サイズ | スケール |
|--------|----------|---------|
| `.iPhone16` | 393 × 852 | @3x |
| `.iPhoneSE` | 375 × 667 | @2x |
| `.iPadPro11` | 834 × 1194 | @2x |

### SnapshotTheme

| ケース | 説明 |
|--------|------|
| `.light` | ライトモード |
| `.dark` | ダークモード |

### ThemeApplicable

```swift
public protocol ThemeApplicable: Sendable {
    @MainActor
    func applyTheme<V: View>(_ view: V, theme: SnapshotTheme) -> AnyView
}
```

デフォルト実装 `DefaultThemeApplicable` は `environment(\.colorScheme, ...)` を使用する。

## ディレクトリ構造

### View スナップショット

```
__Snapshots__/
  SettingsView/                        ← viewName (@SnapshotSuite の引数)
    iPhone16/                          ← デバイスサブディレクトリ
      loaded.light_en.png              ← stateName.theme_locale
      loaded.light_ja.png
      loaded.dark_en.png
      loaded.dark_ja.png
      editing.light_en.png
      ...
    iPhoneSE/
      loaded.light_en.png
      ...
    iPadPro11/
      loaded.light_en.png
      ...
    manifest.json                      ← per-view メタデータ (自動生成)
```

### コンポーネントスナップショット

```
__Snapshots__/
  Card/                                ← componentName (@SnapshotSuite の引数)
    level1.light.png                   ← stateName.theme
    level1.dark.png
    level2.light.png
    level2.dark.png
    manifest.json                      ← per-view メタデータ (自動生成)
```

## メタデータカタログ

テスト実行時に per-view `manifest.json` が自動生成される。全 manifest を集約してルートカタログを生成できる。

### カタログ生成

```swift
@Test("Generate snapshot catalog")
func generateCatalog() {
    let snapshotsRoot = // __Snapshots__ ディレクトリのパス
    let outputPath = // snapshot-catalog.json の出力先
    VisualTesting.generateCatalog(rootDirectory: snapshotsRoot, outputPath: outputPath)
}
```

### HTML ギャラリー生成

カタログからブラウザで閲覧可能な HTML ギャラリーを自動生成できる。

```swift
@Test("Generate snapshot catalog and gallery")
func generateCatalog() {
    let snapshotsRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    let catalogPath = snapshotsRoot.appendingPathComponent("snapshot-catalog.json").path
    let galleryPath = snapshotsRoot.appendingPathComponent("gallery.html").path

    let catalog = VisualTesting.generateCatalog(rootDirectory: snapshotsRoot.path, outputPath: catalogPath)
    VisualTesting.generateGallery(catalog: catalog, outputPath: galleryPath)
}
```

テスト実行後 `open gallery.html` でブラウザ確認：

- セクション / デバイス / テーマ / ロケール フィルター
- テキスト検索（View 名でリアルタイムフィルター）
- Compare モード（light vs dark 横並び）
- Lightbox（クリック拡大 + ← → キーボードナビゲーション）
- ギャラリーのダークモード切り替え
- 画像の lazy loading

### manifest.json 例

```json
{
  "name": "SettingsView",
  "type": "view",
  "generatedAt": "2026-02-17T14:50:00Z",
  "states": {
    "loaded": {
      "inNavigation": false,
      "disableAnimations": false,
      "snapshots": [
        { "device": "iPhone16", "theme": "light", "locale": "en",
          "file": "iPhone16/loaded.light_en.png" }
      ]
    }
  }
}
```

## 依存関係

| パッケージ | 用途 |
|-----------|------|
| [swift-syntax](https://github.com/swiftlang/swift-syntax) | マクロ実装 |
| [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) | スナップショットエンジン |

## ドキュメント

詳細な API ドキュメントは [GitHub Pages](https://no-problem-dev.github.io/swift-visual-testing/documentation/visualtesting/) で確認できる。

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) を参照。
