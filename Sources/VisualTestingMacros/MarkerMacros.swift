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

/// Marker read by `@SnapshotSuite`, and an error anywhere it would not be read.
///
/// A capture shape it cannot change is a compile error rather than a mark that quietly does nothing:
/// `@ComponentSnapshot` has no device frame to put a navigation bar in, and a function with neither
/// marker is captured by nothing at all.
public struct InNavigationMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let markers = captureMarkers(on: declaration)
        if markers.contains("ComponentSnapshot") {
            throw VisualTestingMacroError.inNavigationOnComponent
        }
        guard markers.contains("Snapshot") else {
            throw VisualTestingMacroError.markerWithoutTarget(marker: "@InNavigation", targets: "@Snapshot")
        }
        return []
    }
}

/// Marker read by `@SnapshotSuite` on either capture shape, and an error where neither is present.
public struct WithoutAnimationMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let markers = captureMarkers(on: declaration)
        guard markers.contains("Snapshot") || markers.contains("ComponentSnapshot") else {
            throw VisualTestingMacroError.markerWithoutTarget(
                marker: "@WithoutAnimation",
                targets: "@Snapshot or @ComponentSnapshot"
            )
        }
        return []
    }
}

/// The capture markers written on the declaration this marker is attached to.
private func captureMarkers(on declaration: some DeclSyntaxProtocol) -> Set<String> {
    guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else { return [] }
    var names: Set<String> = []
    for attribute in funcDecl.attributes {
        guard let attr = attribute.as(AttributeSyntax.self),
              let identifier = attr.attributeName.as(IdentifierTypeSyntax.self) else {
            continue
        }
        names.insert(identifier.name.text)
    }
    return names
}
