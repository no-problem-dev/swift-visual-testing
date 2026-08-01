# Changelog

このプロジェクトのすべての注目すべき変更はこのファイルに記録されます。

フォーマットは [Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) に基づいており、
このプロジェクトは [Semantic Versioning](https://semver.org/lang/ja/) に従います。

## [未リリース]

なし

## [2.1.0] - 2026-08-02

### 追加

- **iPad の分割幅を `SnapshotDevice` に追加**: `iPadPro11Half`（597×834）と
  `iPadPro11Third`（398×834）。iPadOS 26 で Split View / Slide Over が廃止され、
  ウィンドウが自由リサイズになったため、HIG が求める 1/2・1/3 幅での検証を撮れるようにした。
  幅は横向き（1194pt）を基準に取る —— 縦向きの 1/3（278pt）は iPadOS が許す
  ウィンドウ最小幅を下回り、実際には作れない面になるため。
  **どちらの幅も horizontal size class は compact に落ちる。**
- **文字サイズの軸 `SnapshotDynamicType`**: `.standard`（`.large`）と
  `.accessibility3`。`SnapshotConfiguration.dynamicTypes` で指定する。
  SwiftUI の `\.dynamicTypeSize` 環境と `ViewImageConfig` の
  `preferredContentSizeCategory` trait の両方に効かせる —— 環境だけだと、
  UIKit が寸法を決める部分（ナビゲーションバー・リスト行の最小高）が既定サイズのまま残る。
- `SnapshotEntry.dynamicType`（`String?`）。既定サイズでは `nil`。
- `SnapshotConfiguration.standardDevices`（既定で撮る 3 端末）。

### 変更

- **`SnapshotConfiguration` の既定端末を `SnapshotDevice.allCases` から
  `standardDevices` に変更した。** 端末を 1 つ足すたびに既存の全スイートが撮る枚数が
  黙って増え、参照画像の無い面が失敗として現れるため。分割幅は使うスイートが明示的に足す。
  **2.0 系で撮った参照画像はそのまま使える**（既定の行列は変わっていない）。

### 互換性

- 既定の文字サイズでは参照画像の名前を変えない（`{state}.{theme}_{locale}.png`）。
  アクセシビリティサイズのときだけ `_{dynamicType}` が付く。2.0 系で記録した画像の
  撮り直しは不要。

## [2.0.0] - 2026-06-06

### 破壊的変更

- **`@Test` の自動生成を廃止し、`SnapshotCase` 収集方式へ再設計**: Xcode 26.4 で、マクロが生成した
  `@Test` は宣言元の lexical context を失い swift-testing のテストレコードを壊すため、
  `@SnapshotSuite` は `__snapshotCases` の収集だけを行うようになった。各スイートには
  `@Test func snapshots() { for snapshotCase in Self.__snapshotCases { snapshotCase.run() } }`
  のランナーを手書きで置く。`run(file:)` は既定で呼び出し元の `#filePath` を使うため、
  ランナーはそのスイート自身のファイルに置くこと（参照画像の探索位置がそこで決まる）。
- **参照画像のパス構成を変更**: View は `{view}/{device}/{state}.{theme}_{locale}.png`、
  コンポーネントは `{component}/{state}.{theme}.png`。1.x で記録した画像は再記録が必要。

### 追加

- `SnapshotDevice` に `iPadPro11` を追加
- HTML ギャラリー自動生成（`generateGallery`）と `basePath` / `category`
- デバイス別サブディレクトリとメタデータカタログ（`manifest.json`）

### 修正

- ランナー検出を `__snapshotCases` 参照ベースに厳密化
- Swift 6.2 の multiline string literal で明示的 `return` が必要な箇所を修正
- マクロ生成コードでの `SourceLocation` クラッシュ

## [1.0.0] - 2026-02-17

### 追加

- **@SnapshotSuite マクロ**: 宣言的なスナップショットテストスイート
  - struct に付与して `@Snapshot` / `@ComponentSnapshot` 関数を探索し `@Test` メソッドを自動生成
  - `collectSnapshotFunctions` パターンによる子関数の自動探索（`@APIGroup` と同じ設計哲学）

- **@Snapshot マクロ**: View スナップショット対象のマーカー
  - デバイス × テーマ × ロケール の全組み合わせでスナップショットを自動生成
  - `__Snapshots__/{viewName}/{stateName}.{device}_{theme}_{locale}.png` のディレクトリ構造

- **@ComponentSnapshot マクロ**: コンポーネントスナップショット対象のマーカー
  - テーマ軸のみ（デバイスフレーム不要）
  - オプションの `width` / `height` パラメータでサイズ指定

- **@InNavigation マクロ**: NavigationStack ラップのマーカー

- **@WithoutAnimation マクロ**: アニメーション無効化のマーカー

- **VisualTesting.assertViewSnapshot**: View スナップショットの核心関数
  - `snapshotDirectory` を自動算出して意味のあるディレクトリ階層に配置
  - `verifySnapshot` 連携で swift-snapshot-testing との統合

- **VisualTesting.assertComponentSnapshot**: コンポーネントスナップショット関数
  - テーマ軸のみのマトリックス
  - 自動サイズ計算またはサイズ指定

- **SnapshotConfiguration**: スナップショットテストマトリックス設定
  - `devices`, `themes`, `locales`, `precision`, `perceptualPrecision`

- **ThemeApplicable プロトコル**: プラグ可能なテーマシステム
  - デフォルト実装: `colorScheme` environment
  - カスタムテーマシステム（ThemeProvider 等）への拡張ポイント

- **SnapshotDevice**: iPhone 16 / iPhone SE デバイス設定

- **SnapshotTheme**: ライト / ダーク テーマ設定

### ドキュメント

- RELEASE_PROCESS.md

[未リリース]: https://github.com/no-problem-dev/swift-visual-testing/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/no-problem-dev/swift-visual-testing/releases/tag/v1.0.0
