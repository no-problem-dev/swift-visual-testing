import SwiftSyntax
import SwiftSyntaxMacros

/// The core macro that generates `@Test` methods for each `@Snapshot` / `@ComponentSnapshot` function.
///
/// Uses the **nested `@Suite` struct** pattern to work around Swift compiler bug
/// [swiftlang/swift#78611](https://github.com/swiftlang/swift/issues/78611):
/// `@Test` methods are placed inside a nested `__VisualTests` struct with its own `@Suite`,
/// providing complete lexical context for `@Test` macro expansion.
///
/// Follows the same collection pattern as `APIGroupMacro.collectEndpoints()`:
/// iterates struct members, collects annotated functions, and generates test methods.
public struct SnapshotSuiteMacro: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw VisualTestingMacroError.onlyApplicableToStruct
        }

        let structName = structDecl.name.text
        let viewName = try parseViewName(from: node)

        let snapshots = collectSnapshotFunctions(from: declaration)
        let components = collectComponentFunctions(from: declaration)

        // Build all @Test methods as a single string
        var testMethods = ""
        for info in snapshots {
            testMethods += generateViewTestMethod(
                structName: structName, viewName: viewName, info: info)
        }
        for info in components {
            testMethods += generateComponentTestMethod(
                structName: structName, componentName: viewName, info: info)
        }

        // Wrap in a nested @Suite struct for complete @Test lexical context
        return ["""
        @Suite("\(raw: viewName)")
        @MainActor
        struct __VisualTests {
        \(raw: testMethods)}
        """]
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

    /// Generate a `@Test` method for a view snapshot inside the nested struct.
    private static func generateViewTestMethod(
        structName: String, viewName: String, info: SnapshotFunctionInfo
    ) -> String {
        """
            @Test("\(info.name)")
            func _\(info.name)() {
                let _outer = \(structName)()
                let _view = _outer.\(info.name)()
                VisualTesting.assertViewSnapshot(
                    of: _view,
                    viewName: "\(viewName)",
                    stateName: "\(info.name)",
                    inNavigation: \(info.inNavigation),
                    disableAnimations: \(info.disableAnimations),
                    file: #filePath, line: #line
                )
            }

        """
    }

    /// Generate a `@Test` method for a component snapshot inside the nested struct.
    private static func generateComponentTestMethod(
        structName: String, componentName: String, info: ComponentFunctionInfo
    ) -> String {
        let sizeArg: String
        if let w = info.width, let h = info.height {
            sizeArg = "CGSize(width: \(w), height: \(h))"
        } else {
            sizeArg = "nil"
        }

        return """
            @Test("\(info.name)")
            func _\(info.name)() {
                let _outer = \(structName)()
                let _view = _outer.\(info.name)()
                VisualTesting.assertComponentSnapshot(
                    of: _view,
                    componentName: "\(componentName)",
                    stateName: "\(info.name)",
                    size: \(sizeArg),
                    file: #filePath, line: #line
                )
            }

        """
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
