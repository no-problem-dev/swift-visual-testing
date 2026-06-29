import CoreGraphics

/// View またはコンポーネントのスナップショットテストスイートを定義するマクロ。
///
/// 子関数の `@Snapshot` / `@ComponentSnapshot` を走査して `__snapshotCases` 静的プロパティに収集する。
/// スイートには手書きのランナーテストを 1 つ宣言する必要があり、欠落した場合はコンパイルエラーを出力する。
///
/// ```swift
/// @SnapshotSuite("SettingsView")
/// @MainActor
/// struct SettingsSnapshots {
///     @Snapshot
///     func loaded() -> some View {
///         SettingsView()
///     }
///
///     @Test func snapshots() {
///         for snapshotCase in Self.__snapshotCases { snapshotCase.run() }
///     }
/// }
/// ```
///
/// ランナーはマクロで生成できない。マクロ生成の宣言内で `@Test` を展開するとコンパイラが
/// lexical context を失い、swift-testing のテストコンテンツレコードが型の内部でコンパイルできなくなるためである。
@attached(member, names: named(__snapshotCases))
public macro SnapshotSuite(_ viewName: String) =
    #externalMacro(module: "VisualTestingMacros", type: "SnapshotSuiteMacro")

/// View スナップショット対象としてマーク付けするマクロ。
///
/// 関数は `some View` を返す必要がある。`@SnapshotSuite` がデバイス × テーマ × ロケールの
/// マトリクスで `VisualTesting.assertViewSnapshot` を呼び出す `@Test` メソッドを生成する。
@attached(peer)
public macro Snapshot() =
    #externalMacro(module: "VisualTestingMacros", type: "SnapshotMacro")

/// コンポーネントスナップショット対象としてマーク付けするマクロ（サイズ指定付き）。
///
/// テーマ軸のみでキャプチャする（デバイスフレーム・ロケール変動なし）。
///
/// ```swift
/// @ComponentSnapshot(width: 340, height: 120)
/// func level1() -> some View {
///     Card(elevation: .level1) { Text("Card Level 1") }
/// }
/// ```
@attached(peer)
public macro ComponentSnapshot(width: CGFloat? = nil, height: CGFloat? = nil) =
    #externalMacro(module: "VisualTestingMacros", type: "ComponentSnapshotMacro")

/// View を `NavigationStack` でラップするよう指定するマクロ。
@attached(peer)
public macro InNavigation() =
    #externalMacro(module: "VisualTestingMacros", type: "InNavigationMacro")

/// スナップショットキャプチャ中にアニメーションを無効化するよう指定するマクロ。
@attached(peer)
public macro WithoutAnimation() =
    #externalMacro(module: "VisualTestingMacros", type: "WithoutAnimationMacro")
