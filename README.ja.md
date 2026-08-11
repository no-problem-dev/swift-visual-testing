[English](./README.md) | 日本語

# VisualTesting

SwiftUI のスナップショットテスト。撮りたい状態に名前を付けるだけで、デバイス × テーマ × ロケール × 文字サイズの全組み合わせが撮られる。

![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)
![iOS 17+](https://img.shields.io/badge/iOS-17+-blue.svg)
![macOS 14+](https://img.shields.io/badge/macOS-14+-purple.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 特徴

- **宣言的マクロ。** `@SnapshotSuite` / `@Snapshot` / `@ComponentSnapshot` — View を返す関数を書けば、それがテストそのものになる。
- **マトリクスで撮る。** 既定は 3 デバイス・ライト/ダーク・`en`/`ja`。iPadOS 26 のウィンドウ幅とアクセシビリティ文字サイズは明示指定の軸なので、足しても記録済みの参照画像は無効にならない。
- **View とコンポーネントを分ける。** 全画面 View は全軸マトリクス、デザインシステムのコンポーネントはテーマ軸のみ。
- **どのテーマ機構でも繋がる。** `ThemeApplicable` がテーマ軸をアプリの実際の見た目の駆動経路に接続するので、スナップショットはアプリと同じ経路を通る。
- **見られる出力。** 実行ごとに画像の隣へ `manifest.json` が書かれ、それを集約してカタログと、フィルタ・検索・ライト/ダーク比較を備えた自己完結 HTML ギャラリーになる。

## 使い方

```swift
import SwiftUI
import Testing
import VisualTesting

@SnapshotSuite("SettingsView")
@MainActor
struct SettingsViewSnapshots {
    @Snapshot
    func loaded() -> some View {
        SettingsView()
    }

    @Test func snapshots() {
        for snapshotCase in Self.__snapshotCases { snapshotCase.run() }
    }
}
```

この関数 1 つで、`__Snapshots__/SettingsView/{device}/loaded.{theme}_{locale}.png` に
12 枚の参照画像が記録される。

ランナーテストを手で書くのは意図的なもの。マクロから `@Test` を展開すると swift-testing の
テストレコードが壊れるため、`@SnapshotSuite` はケースの収集だけを行う。ランナーが無い場合は、
追加すべき行を提示するコンパイルエラーになる。

## ドキュメント

[Getting Started と API リファレンス](https://no-problem-dev.github.io/swift-visual-testing/documentation/visualtesting/)
に、コンポーネントスナップショット・カスタムテーマ機構・マトリクスの変更・参照画像の記録・
HTML ギャラリーの生成をまとめてある。

## インストール

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-visual-testing.git", from: "2.0.0")
]
```

```swift
.testTarget(
    name: "YourTests",
    dependencies: [
        .product(name: "VisualTesting", package: "swift-visual-testing")
    ]
)
```

## コントリビュート

[CONTRIBUTING.md](CONTRIBUTING.md) を参照。

## ライセンス

MIT — 詳細は [LICENSE](LICENSE) を参照。
