# VisualTesting 入門

数分でスナップショットテストを Swift パッケージに追加する。

## インストール

`Package.swift` の dependencies に `swift-visual-testing` を追加する：

```swift
dependencies: [
    .package(
        url: "https://github.com/no-problem-dev/swift-visual-testing.git",
        from: "1.0.1"
    ),
],
```

次に `VisualTesting` をテストターゲットに追加する：

```swift
.testTarget(
    name: "MyFeatureTests",
    dependencies: [
        "MyFeature",
        .product(name: "VisualTesting", package: "swift-visual-testing"),
    ]
),
```

## 基本的な使い方

### デフォルトマトリクスで View をスナップショット

テストターゲットにテストファイルを作成し、struct に `@SnapshotSuite` を付与する：

```swift
import Testing
import SwiftUI
import VisualTesting

@SnapshotSuite("ProfileView")
@MainActor
struct ProfileViewSnapshots {

    // 各 @Snapshot 関数はキャプチャする View を返す
    @Snapshot
    func loggedIn() -> some View {
        ProfileView(user: .preview)
    }

    @Snapshot
    @InNavigation
    func loggedInWithNav() -> some View {
        ProfileView(user: .preview)
    }

    @Snapshot
    @WithoutAnimation
    func loading() -> some View {
        ProfileView(user: nil)
    }

    // ランナーは手書きが必須 — @SnapshotSuite は欠落時にコンパイルエラーを出力する
    @Test func snapshots() {
        for snapshotCase in Self.__snapshotCases {
            snapshotCase.run()
        }
    }
}
```

初回実行時、PNG リファレンス画像が `Tests/MyFeatureTests/__Snapshots__/ProfileView/` に書き込まれる。
2 回目以降の実行ではそのリファレンス画像と比較する。

### デザインシステムコンポーネントをスナップショット

コンポーネントはテーマ軸のみを使用する（デバイスフレーム・ロケールなし）：

```swift
@SnapshotSuite("PrimaryButton")
@MainActor
struct PrimaryButtonSnapshots {

    @ComponentSnapshot(width: 200, height: 50)
    func default() -> some View {
        PrimaryButton("Tap me")
    }

    @ComponentSnapshot(width: 200, height: 50)
    func disabled() -> some View {
        PrimaryButton("Tap me").disabled(true)
    }

    @Test func snapshots() {
        for snapshotCase in Self.__snapshotCases {
            snapshotCase.run()
        }
    }
}
```

### キャプチャマトリクスをカスタマイズ

`run(configuration:)` に `SnapshotConfiguration` を渡す：

```swift
@Test func snapshots() {
    let config = SnapshotConfiguration(
        devices: [.iPhone16],
        themes: [.light],
        locales: ["en"]
    )
    for snapshotCase in Self.__snapshotCases {
        snapshotCase.run(configuration: config)
    }
}
```

### カスタムテーマシステムを統合

テストのセットアップで `VisualTesting.themeApplicable` を一度設定する：

```swift
// テストヘルパーまたは setUp ブロック内
VisualTesting.themeApplicable = AppThemeApplicable()
```

次に `ThemeApplicable` を実装する：

```swift
struct AppThemeApplicable: ThemeApplicable {
    @MainActor
    func applyTheme<V: View>(_ view: V, theme: SnapshotTheme) -> AnyView {
        let provider = ThemeProvider()
        provider.themeMode = theme == .light ? .light : .dark
        return AnyView(view.environmentObject(provider))
    }
}
```

## ビジュアルギャラリーの生成

テスト実行後、全マニフェストを集約してインタラクティブな HTML ギャラリーを生成できる：

```swift
// テストまたはスクリプト内
let catalog = VisualTesting.generateCatalog(
    rootDirectory: "Tests/MyFeatureTests",
    outputPath: "snapshot-catalog.json"
)
VisualTesting.generateGallery(catalog: catalog, outputPath: "snapshot-gallery.html")
```

ブラウザで `snapshot-gallery.html` を開く（サーバー不要）。ギャラリーはデバイス・テーマ・
ロケールでのフィルタリング、ライト/ダークの横並び比較、ライトボックスをサポートする。
