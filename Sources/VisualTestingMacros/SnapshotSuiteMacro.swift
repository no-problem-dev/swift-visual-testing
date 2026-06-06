import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Collects `@Snapshot` / `@ComponentSnapshot` functions into a
/// `__snapshotCases` static property.
///
/// Design note: this macro must NOT generate `@Test` / `@Suite`
/// declarations. The compiler loses lexical context when expanding
/// swift-testing macros inside macro-generated declarations, so
/// swift-testing emits file-scope test content records (`@_section` /
/// `@_used` non-static properties) that do not compile inside a type
/// (broken since the Xcode 26.4 toolchain; previously this macro
/// generated a nested `@Suite` struct, which is exactly that failure
/// mode). Instead, the user writes one parameterized runner test by
/// hand — ``expansion`` diagnoses an error when it is missing.
public struct SnapshotSuiteMacro: MemberMacro {

    static let runnerTemplate =
        "@Test func snapshots() { for snapshotCase in Self.__snapshotCases { snapshotCase.run() } }"

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

        if !hasHandwrittenTestRunner(declaration) {
            context.diagnose(Diagnostic(node: node, message: MissingRunnerMessage()))
        }

        var cases: [String] = []
        for info in collectSnapshotFunctions(from: declaration) {
            cases.append("""
                    SnapshotCase(
                        viewName: "\(viewName)",
                        stateName: "\(info.name)",
                        kind: .view(inNavigation: \(info.inNavigation), disableAnimations: \(info.disableAnimations)),
                        makeView: {
                            AnyView(\(structName)().\(info.name)())
                        }
                    )
            """)
        }
        for info in collectComponentFunctions(from: declaration) {
            cases.append("""
                    SnapshotCase(
                        viewName: "\(viewName)",
                        stateName: "\(info.name)",
                        kind: .component(width: \(info.width ?? "nil"), height: \(info.height ?? "nil")),
                        makeView: {
                            AnyView(\(structName)().\(info.name)())
                        }
                    )
            """)
        }

        let body = cases.isEmpty
            ? "[]"
            : "[\n\(cases.joined(separator: ",\n"))\n    ]"

        return ["""
        nonisolated static var __snapshotCases: [SnapshotCase] {
            \(raw: body)
        }
        """]
    }

    // MARK: - Runner Detection

    /// Whether the struct already declares a hand-written `@Test` function.
    private static func hasHandwrittenTestRunner(_ declaration: some DeclGroupSyntax) -> Bool {
        for member in declaration.memberBlock.members {
            guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else { continue }
            if collectAttributes(from: funcDecl).contains("Test") {
                return true
            }
        }
        return false
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

    private static func collectSnapshotFunctions(from declaration: some DeclGroupSyntax) -> [SnapshotFunctionInfo] {
        var results: [SnapshotFunctionInfo] = []

        for member in declaration.memberBlock.members {
            guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else {
                continue
            }

            let attrs = collectAttributes(from: funcDecl)
            guard attrs.contains("Snapshot") else { continue }

            results.append(SnapshotFunctionInfo(
                name: funcDecl.name.text,
                inNavigation: attrs.contains("InNavigation"),
                disableAnimations: attrs.contains("WithoutAnimation")
            ))
        }

        return results
    }

    private static func collectComponentFunctions(from declaration: some DeclGroupSyntax) -> [ComponentFunctionInfo] {
        var results: [ComponentFunctionInfo] = []

        for member in declaration.memberBlock.members {
            guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else {
                continue
            }

            let attrs = collectAttributes(from: funcDecl)
            guard attrs.contains("ComponentSnapshot") else { continue }

            let (width, height) = parseComponentSize(from: funcDecl)
            results.append(ComponentFunctionInfo(
                name: funcDecl.name.text,
                width: width,
                height: height
            ))
        }

        return results
    }

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
}

// MARK: - Diagnostics

private struct MissingRunnerMessage: DiagnosticMessage {
    let message = "@SnapshotSuite requires a hand-written runner test. Add to the struct: "
        + SnapshotSuiteMacro.runnerTemplate
    let diagnosticID = MessageID(domain: "VisualTestingMacros", id: "missingRunner")
    let severity: DiagnosticSeverity = .error
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
