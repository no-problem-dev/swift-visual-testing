# VisualTesting

SwiftUI向けのスナップショットテストライブラリ。宣言的マクロでボイラープレートを排除し、デバイス × テーマ × ロケールのマトリクスで自動的にスナップショットを生成します。

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
- **Swift Testing 対応**: `@Suite` / `@Test` との統合、`Issue.record` でのエラー報告

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
}
```

この2つの関数から、以下のリファレンス画像が自動生成されます：

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
    .package(url: "https://github.com/no-problem-dev/swift-visual-testing.git", from: "1.2.0")
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

`@SnapshotSuite` と `@Snapshot` で画面全体の View をキャプチャします。関数は View を返すだけ。viewName / stateName はマクロが自動的に解決します。

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
}
```

**出力**: `__Snapshots__/MyView/{device}/loaded.{theme}_{locale}.png`

デフォルトで 3デバイス × 2テーマ × 2ロケール = **12枚** のスナップショットが生成されます。

### コンポーネントスナップショット

`@ComponentSnapshot` でUIコンポーネント（ボタン、カードなど）を固定サイズでキャプチャします。テーマ軸のみ。

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
}
```

**出力**: `__Snapshots__/Card/level1.light.png`, `__Snapshots__/Card/level1.dark.png`

### 属性マクロ

テスト関数に属性マクロを付与して振る舞いをカスタマイズします。

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
| `@SnapshotSuite("ViewName")` | MemberMacro | 子関数を探索し `@Test` メソッドを自動生成 |
| `@Snapshot` | PeerMacro | View スナップショット対象のマーカー |
| `@ComponentSnapshot(width:height:)` | PeerMacro | コンポーネント対象のマーカー（サイズ指定） |
| `@InNavigation` | PeerMacro | `NavigationStack` ラップを指定 |
| `@WithoutAnimation` | PeerMacro | アニメーション無効化を指定 |

### テーマシステムの統合

デフォルトでは `environment(\.colorScheme, ...)` を使用します。カスタムテーマシステム（例: `ThemeProvider`）を使用する場合は、`ThemeApplicable` プロトコルを実装します。

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

テストの `init()` で `setupVisualTesting()` を呼び出してください。

### 設定のカスタマイズ

デフォルトのマトリクス構成を変更する場合は `SnapshotConfiguration` を使用します。直接 API を呼び出す場合に `configuration` パラメータとして渡します。

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

初回実行時、またはリファレンス画像を再記録する場合は環境変数を設定します：

```bash
# 全スナップショットを記録モードで実行
SNAPSHOT_TESTING_RECORD=all swift test
```

## 直接 API

マクロを使わず、より細かい制御が必要な場合は直接 API を使用できます。

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
| `@SnapshotSuite("ViewName")` | struct に付与。子関数の `@Snapshot` / `@ComponentSnapshot` からテストを自動生成 |
| `@Snapshot` | View スナップショット。デバイス × テーマ × ロケールの全組み合わせ |
| `@ComponentSnapshot(width:height:)` | コンポーネントスナップショット。テーマ軸のみ |
| `@InNavigation` | `NavigationStack` でラップ |
| `@WithoutAnimation` | アニメーション無効化 |

### VisualTesting (直接 API)

| メソッド | 説明 |
|---------|------|
| `assertViewSnapshot(of:viewName:stateName:inNavigation:disableAnimations:configuration:file:line:)` | View をデバイス × テーマ × ロケールでキャプチャ |
| `assertComponentSnapshot(of:componentName:stateName:size:configuration:file:line:)` | コンポーネントをテーマ軸のみでキャプチャ |
| `generateCatalog(rootDirectory:outputPath:)` | 全 manifest.json を集約して `snapshot-catalog.json` を生成 |
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

デフォルト実装 `DefaultThemeApplicable` は `environment(\.colorScheme, ...)` を使用します。

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

テスト実行時に per-view `manifest.json` が自動生成されます。全 manifest を集約してルートカタログを生成できます。

### カタログ生成

```swift
@Test("Generate snapshot catalog")
func generateCatalog() {
    let snapshotsRoot = // __Snapshots__ ディレクトリのパス
    let outputPath = // snapshot-catalog.json の出力先
    VisualTesting.generateCatalog(rootDirectory: snapshotsRoot, outputPath: outputPath)
}
```

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

詳細なAPIドキュメントは [GitHub Pages](https://no-problem-dev.github.io/swift-visual-testing/documentation/visualtesting/) で確認できます。

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) を参照してください。
