# ``VisualTesting``

SwiftUI View とデザインシステムコンポーネント向けのマクロ駆動スナップショットテストライブラリ。

## Overview

`VisualTesting` は、デバイス × テーマ × ロケールの全スナップショットマトリクスを
1 つの struct アノテーションから自動化する。何を（what）キャプチャするかを記述するだけで、
どのように（how）実行するかはマクロとアサーションエンジンが処理する。

```swift
@SnapshotSuite("SettingsView")
@MainActor
struct SettingsViewSnapshots {

    @Snapshot
    func loaded() -> some View {
        SettingsView(model: .preview)
    }

    @Snapshot
    @InNavigation
    func inNavigation() -> some View {
        SettingsView(model: .preview)
    }

    @Test func snapshots() {
        for snapshotCase in Self.__snapshotCases {
            snapshotCase.run()
        }
    }
}
```

テストスイートを実行すると、デバイス（iPhone 16・iPhone SE・iPad Pro 11）、テーマ（ライト・ダーク）、
ロケール（en・ja）の全組み合わせの PNG が `__Snapshots__/SettingsView/` に保存される。

### 主要な型

| シンボル | 役割 |
|---|---|
| `SnapshotSuite(_:)` | struct をスナップショットテストスイートとしてマーク付けし、ケースを収集する |
| `Snapshot()` | ファクトリ関数を全画面 View スナップショット対象としてマーク付けする |
| `ComponentSnapshot(width:height:)` | ファクトリ関数をコンポーネント（テーマ軸のみ）スナップショット対象としてマーク付けする |
| `InNavigation()` | キャプチャ時に `NavigationStack` で View をラップする |
| `WithoutAnimation()` | キャプチャ中に UIKit アニメーションを無効化する |
| `SnapshotCase` | 1 つのスナップショットケースのランタイム表現。`run()` を駆動する |
| `SnapshotConfiguration` | デバイス × テーマ × ロケールのマトリクスを設定する |
| `ThemeApplicable` | カスタムテーマシステムを注入するためのプロトコル |

## Topics

### 入門

- <doc:GettingStarted>

### マクロ

- ``SnapshotSuite(_:)``
- ``Snapshot()``
- ``ComponentSnapshot(width:height:)``
- ``InNavigation()``
- ``WithoutAnimation()``

### ランタイム

- ``SnapshotCase``
- ``SnapshotCase/Kind``
- ``SnapshotCase/run(configuration:file:line:)``

### 設定

- ``SnapshotConfiguration``
- ``SnapshotDevice``
- ``SnapshotTheme``

### テーマ統合

- ``ThemeApplicable``
- ``DefaultThemeApplicable``
- ``VisualTesting/themeApplicable``

### カタログとギャラリー

- ``VisualTesting/generateCatalog(rootDirectory:outputPath:)``
- ``VisualTesting/generateGallery(catalog:outputPath:)``
- ``SnapshotCatalog``
- ``SnapshotManifest``
- ``SnapshotType``
- ``StateManifest``
- ``SnapshotEntry``
- ``CatalogConfiguration``
- ``CatalogSummary``
