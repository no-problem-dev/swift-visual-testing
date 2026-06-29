import SwiftSyntax
import SwiftSyntaxMacros

/// View スナップショット関数用のマーカーマクロ実装。
/// コードを生成しない。`@SnapshotSuite` がスナップショット対象の検出に使用する。
public struct SnapshotMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(FunctionDeclSyntax.self) else {
            throw VisualTestingMacroError.snapshotOnlyOnFunction
        }
        return []
    }
}

/// コンポーネントスナップショット関数用のマーカーマクロ実装（サイズ指定付き）。
/// コードを生成しない。`@SnapshotSuite` がコンポーネントスナップショット対象の検出に使用する。
public struct ComponentSnapshotMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(FunctionDeclSyntax.self) else {
            throw VisualTestingMacroError.snapshotOnlyOnFunction
        }
        return []
    }
}

/// `NavigationStack` でラップすることを示すマーカーマクロ実装。
public struct InNavigationMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}

/// スナップショットキャプチャ中のアニメーション無効化を示すマーカーマクロ実装。
public struct WithoutAnimationMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}
