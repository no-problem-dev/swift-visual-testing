import SwiftSyntax
import SwiftSyntaxMacros

/// The core macro that generates `@Test` methods for each `@Snapshot` / `@ComponentSnapshot` function.
///
/// Follows the same pattern as `APIGroupMacro.collectEndpoints()`:
/// iterates struct members, collects annotated functions, and generates test methods.
public struct SnapshotSuiteMacro: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else {
            throw VisualTestingMacroError.onlyApplicableToStruct
        }

        let viewName = try parseViewName(from: node)

        let snapshots = collectSnapshotFunctions(from: declaration)
        let components = collectComponentFunctions(from: declaration)

        var members: [DeclSyntax] = []

        for info in snapshots {
            members.append(generateViewTest(viewName: viewName, info: info))
        }
        for info in components {
            members.append(generateComponentTest(componentName: viewName, info: info))
        }

        return members
    }

    // MARK: - Argument Parsing

    private static func parseViewName(from node: AttributeSyntax) throws -> String {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
              let firstArg = arguments.first,
              let stringLiteral = firstArg.expression.as(StringLiteralExprSyntax.self),
              let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) else {
            throw VisualTestingMacroError.missingViewName
        }
        return segment.content.text
    }

    // MARK: - Function Collection

    /// Collect functions annotated with `@Snapshot` (same pattern as `collectEndpoints`)
    private static func collectSnapshotFunctions(from declaration: some DeclGroupSyntax) -> [SnapshotFunctionInfo] {
        var results: [SnapshotFunctionInfo] = []

        for member in declaration.memberBlock.members {
            guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else {
                continue
            }

            let attrs = collectAttributes(from: funcDecl)
            guard attrs.contains("Snapshot") else { continue }

            let name = funcDecl.name.text
            let inNavigation = attrs.contains("InNavigation")
            let disableAnimations = attrs.contains("WithoutAnimation")

            results.append(SnapshotFunctionInfo(
                name: name,
                inNavigation: inNavigation,
                disableAnimations: disableAnimations
            ))
        }

        return results
    }

    /// Collect functions annotated with `@ComponentSnapshot`
    private static func collectComponentFunctions(from declaration: some DeclGroupSyntax) -> [ComponentFunctionInfo] {
        var results: [ComponentFunctionInfo] = []

        for member in declaration.memberBlock.members {
            guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else {
                continue
            }

            let attrs = collectAttributes(from: funcDecl)
            guard attrs.contains("ComponentSnapshot") else { continue }

            let name = funcDecl.name.text
            let (width, height) = parseComponentSize(from: funcDecl)

            results.append(ComponentFunctionInfo(
                name: name,
                width: width,
                height: height
            ))
        }

        return results
    }

    /// Extract attribute names from a function declaration
    private static func collectAttributes(from funcDecl: FunctionDeclSyntax) -> Set<String> {
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

    /// Parse width/height from `@ComponentSnapshot(width: 340, height: 120)`
    private static func parseComponentSize(from funcDecl: FunctionDeclSyntax) -> (width: String?, height: String?) {
        for attribute in funcDecl.attributes {
            guard let attr = attribute.as(AttributeSyntax.self),
                  let identifier = attr.attributeName.as(IdentifierTypeSyntax.self),
                  identifier.name.text == "ComponentSnapshot",
                  let arguments = attr.arguments?.as(LabeledExprListSyntax.self) else {
                continue
            }

            var width: String?
            var height: String?

            for arg in arguments {
                let value = arg.expression.trimmedDescription
                switch arg.label?.text {
                case "width":
                    width = value
                case "height":
                    height = value
                default:
                    continue
                }
            }

            return (width, height)
        }
        return (nil, nil)
    }

    // MARK: - Code Generation

    private static func generateViewTest(viewName: String, info: SnapshotFunctionInfo) -> DeclSyntax {
        """
        @Test("\(raw: info.name)")
        func _snapshot_\(raw: info.name)() {
            let _view = \(raw: info.name)()
            VisualTesting.assertViewSnapshot(
                of: _view,
                viewName: "\(raw: viewName)",
                stateName: "\(raw: info.name)",
                inNavigation: \(raw: info.inNavigation),
                disableAnimations: \(raw: info.disableAnimations),
                file: #filePath, line: #line
            )
        }
        """
    }

    private static func generateComponentTest(componentName: String, info: ComponentFunctionInfo) -> DeclSyntax {
        let sizeArg: String
        if let w = info.width, let h = info.height {
            sizeArg = "CGSize(width: \(w), height: \(h))"
        } else {
            sizeArg = "nil"
        }

        return DeclSyntax(stringLiteral: """
        @Test("\(info.name)")
        func _snapshot_\(info.name)() {
            let _view = \(info.name)()
            VisualTesting.assertComponentSnapshot(
                of: _view,
                componentName: "\(componentName)",
                stateName: "\(info.name)",
                size: \(sizeArg),
                file: #filePath, line: #line
            )
        }
        """)
    }
}

// MARK: - Supporting Types

private struct SnapshotFunctionInfo {
    let name: String
    let inNavigation: Bool
    let disableAnimations: Bool
}

private struct ComponentFunctionInfo {
    let name: String
    let width: String?
    let height: String?
}
