import SwiftSyntax
import SwiftSyntaxMacros

/// Marker macro for view snapshot functions.
/// Does not generate any code; used by `@SnapshotSuite` to detect snapshot targets.
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

/// Marker macro for component snapshot functions with optional size.
/// Does not generate any code; used by `@SnapshotSuite` to detect component snapshot targets.
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

/// Marker macro indicating the view should be wrapped in NavigationStack.
public struct InNavigationMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}

/// Marker macro indicating animations should be disabled during snapshot.
public struct WithoutAnimationMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}
