import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct VisualTestingPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SnapshotSuiteMacro.self,
        SnapshotMacro.self,
        ComponentSnapshotMacro.self,
        InNavigationMacro.self,
        WithoutAnimationMacro.self,
    ]
}
