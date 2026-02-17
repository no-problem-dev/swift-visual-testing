# VisualTesting

[English](README_EN.md) | 日本語

SwiftUI向けのスナップショットテストライブラリ。デバイス × テーマ × ロケールのマトリクスで自動的にスナップショットを生成し、View名ベースの階層ディレクトリにリファレンス画像を配置します。

![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)
![iOS 17+](https://img.shields.io/badge/iOS-17+-blue.svg)
![macOS 14+](https://img.shields.io/badge/macOS-14+-purple.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 特徴

- **マトリクステスト**: デバイス × テーマ × ロケールの全組み合わせを1関数呼び出しで検証
- **階層的ディレクトリ構造**: `__Snapshots__/{ViewName}/{stateName}.{device}_{theme}_{locale}.png` で自動整理
- **テーマシステム統合**: `ThemeApplicable` プロトコルで任意のテーマシステムと接続
- **View / Component 分離**: View は全軸マトリクス、コンポーネントはテーマ軸のみでテスト
- **Swift Testing 対応**: `@Suite` / `@Test` との統合、`Issue.record` でのエラー報告
- **宣言的マクロ** (実験的): `@SnapshotSuite` / `@Snapshot` / `@ComponentSnapshot` でボイラープレート削減

## クイックスタート

```swift
import SwiftUI
import Testing
import VisualTesting

@Suite("SettingsView Snapshots")
@MainActor
struct SettingsViewSnapshots {
    init() { setupVisualTesting() }

    @Test("loaded")
    func loaded() {
        VisualTesting.assertViewSnapshot(
            of: SettingsView(),
            viewName: "SettingsView", stateName: "loaded",
            inNavigation: false, disableAnimations: true,
            file: #filePath, line: #line)
    }

    @Test("editing")
    func editing() {
        VisualTesting.assertViewSnapshot(
            of: SettingsView(isEditing: true),
            viewName: "SettingsView", stateName: "editing",
            inNavigation: true, disableAnimations: true,
            file: #filePath, line: #line)
    }
}
```

この2つの `@Test` で、以下のリファレンス画像が自動生成されます：

```
__Snapshots__/
  SettingsView/
    loaded.iPhone16_light_en.png
    loaded.iPhone16_light_ja.png
    loaded.iPhone16_dark_en.png
    loaded.iPhone16_dark_ja.png
    loaded.iPhoneSE_light_en.png
    loaded.iPhoneSE_light_ja.png
    loaded.iPhoneSE_dark_en.png
    loaded.iPhoneSE_dark_ja.png
    editing.iPhone16_light_en.png
    ...
```

## インストール

### Swift Package Manager

`Package.swift` に以下を追加：

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-visual-testing.git", from: "1.0.0")
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

画面全体の View を、デバイス × テーマ × ロケールの全組み合わせでキャプチャします。

```swift
VisualTesting.assertViewSnapshot(
    of: MyView(),
    viewName: "MyView",        // ディレクトリ名
    stateName: "loaded",       // ファイル名のプレフィックス
    inNavigation: false,       // NavigationStack でラップするか
    disableAnimations: true,   // アニメーション無効化
    file: #filePath, line: #line)
```

**出力**: `__Snapshots__/MyView/loaded.{device}_{theme}_{locale}.png`

デフォルトで 2デバイス × 2テーマ × 2ロケール = **8枚** のスナップショットが生成されます。

### コンポーネントスナップショット

UIコンポーネント（ボタン、カードなど）を固定サイズでキャプチャします。テーマ軸のみ。

```swift
VisualTesting.assertComponentSnapshot(
    of: Card(elevation: .level1) { Text("Card") }
        .frame(width: 300, height: 80).padding(),
    componentName: "Card",     // ディレクトリ名
    stateName: "level1",       // ファイル名のプレフィックス
    size: CGSize(width: 340, height: 120),
    file: #filePath, line: #line)
```

**出力**: `__Snapshots__/Card/level1.light.png`, `__Snapshots__/Card/level1.dark.png`

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

デフォルト設定を変更する場合は `SnapshotConfiguration` を渡します。

```swift
// iPhone16 のみ、ダークモードのみ、英語のみ
let config = SnapshotConfiguration(
    devices: [.iPhone16],
    themes: [.dark],
    locales: ["en"],
    precision: 0.99,
    perceptualPrecision: 0.98
)

VisualTesting.assertViewSnapshot(
    of: MyView(),
    viewName: "MyView", stateName: "dark",
    inNavigation: false, disableAnimations: true,
    configuration: config,
    file: #filePath, line: #line)
```

### リファレンス画像の記録

初回実行時、またはリファレンス画像を再記録する場合は環境変数を設定します：

```bash
# 全スナップショットを記録モードで実行
SNAPSHOT_TESTING_RECORD=all swift test
```

## マクロ

`@SnapshotSuite` が子関数の `@Snapshot` / `@ComponentSnapshot` を探索し、`@Test` メソッドを自動生成します。
内部的にはネスト `@Suite` struct パターンを使用し、Swift Testing の `@Test` マクロとの互換性を確保しています。

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
    @InNavigation
    func detail() -> some View {
        MyDetailView()
    }

    @ComponentSnapshot(width: 200, height: 60)
    func chip() -> some View {
        Chip("Label").padding()
    }
}
```

### マクロ一覧

| マクロ | 種類 | 役割 |
|--------|------|------|
| `@SnapshotSuite` | MemberMacro | 子関数を探索し `@Test` メソッドを生成 |
| `@Snapshot` | PeerMacro | View スナップショット対象のマーカー |
| `@ComponentSnapshot` | PeerMacro | コンポーネント対象のマーカー（サイズ指定可） |
| `@InNavigation` | PeerMacro | `NavigationStack` ラップを指定 |
| `@WithoutAnimation` | PeerMacro | アニメーション無効化を指定 |

## API リファレンス

### VisualTesting

| メソッド | 説明 |
|---------|------|
| `assertViewSnapshot(of:viewName:stateName:inNavigation:disableAnimations:configuration:file:line:)` | View をデバイス × テーマ × ロケールでキャプチャ |
| `assertComponentSnapshot(of:componentName:stateName:size:configuration:file:line:)` | コンポーネントをテーマ軸のみでキャプチャ |
| `themeApplicable` | テーマ適用ロジック（カスタマイズ可能） |

### SnapshotConfiguration

| プロパティ | 型 | デフォルト値 | 説明 |
|----------|------|------------|------|
| `devices` | `[SnapshotDevice]` | `[.iPhone16, .iPhoneSE]` | テスト対象デバイス |
| `themes` | `[SnapshotTheme]` | `[.light, .dark]` | テスト対象テーマ |
| `locales` | `[String]` | `["en", "ja"]` | テスト対象ロケール |
| `precision` | `Float` | `0.99` | ピクセル精度 |
| `perceptualPrecision` | `Float` | `0.98` | 知覚的精度 |

### SnapshotDevice

| ケース | 画面サイズ | スケール |
|--------|----------|---------|
| `.iPhone16` | 393 × 852 | @3x |
| `.iPhoneSE` | 375 × 667 | @2x |

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
  SettingsView/                        ← viewName
    loaded.iPhone16_light_en.png       ← stateName.device_theme_locale
    loaded.iPhone16_light_ja.png
    loaded.iPhone16_dark_en.png
    loaded.iPhone16_dark_ja.png
    loaded.iPhoneSE_light_en.png
    loaded.iPhoneSE_light_ja.png
    loaded.iPhoneSE_dark_en.png
    loaded.iPhoneSE_dark_ja.png
    editing.iPhone16_light_en.png      ← 別の stateName
    ...
```

### コンポーネントスナップショット

```
__Snapshots__/
  Card/                                ← componentName
    level1.light.png                   ← stateName.theme
    level1.dark.png
    level2.light.png
    level2.dark.png
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
