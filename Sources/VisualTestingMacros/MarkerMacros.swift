import SwiftSyntax
import SwiftSyntaxMacros

/// Marker for a view snapshot function.
///
/// Generates nothing; it exists so `@SnapshotSuite` can find the function, and so applying the
/// attribute to anything other than a function is a compile error.
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

/// Marker for a component snapshot function, carrying the requested size in its arguments.
///
/// Generates nothing; `@SnapshotSuite` reads both the mark and the size off the attribute.
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

/// Marker read by `@SnapshotSuite`; on a function with no `@Snapshot` it is silently inert.
public struct InNavigationMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}

/// Marker read by `@SnapshotSuite`; on a function with no `@Snapshot` it is silently inert.
public struct WithoutAnimationMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}
