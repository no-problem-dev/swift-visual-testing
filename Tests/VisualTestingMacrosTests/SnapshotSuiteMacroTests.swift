import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(VisualTestingMacros)
import VisualTestingMacros

let testMacros: [String: Macro.Type] = [
    "SnapshotSuite": SnapshotSuiteMacro.self,
    "Snapshot": SnapshotMacro.self,
    "ComponentSnapshot": ComponentSnapshotMacro.self,
    "InNavigation": InNavigationMacro.self,
    "WithoutAnimation": WithoutAnimationMacro.self,
]

/// The hand-written runner that suites must contain.
private let runner = """
    @Test func snapshots() {
        for snapshotCase in Self.__snapshotCases {
            snapshotCase.run()
        }
    }
"""
#endif

final class SnapshotSuiteMacroTests: XCTestCase {

    // MARK: - View Snapshots

    func testBasicSnapshot() throws {
        #if canImport(VisualTestingMacros)
        assertMacroExpansion(
            """
            @SnapshotSuite("SettingsView")
            struct SettingsSnapshots {
                @Snapshot
                func loaded() -> some View {
                    SettingsView()
                }

            \(runner)
            }
            """,
            expandedSource: """
            struct SettingsSnapshots {
                func loaded() -> some View {
                    SettingsView()
                }

            \(runner)

                nonisolated static var __snapshotCases: [SnapshotCase] {
                    [
                        SnapshotCase(
                            viewName: "SettingsView",
                            stateName: "loaded",
                            kind: .view(inNavigation: false, disableAnimations: false),
                            makeView: {
                                AnyView(SettingsSnapshots().loaded())
                            }
                        )
                    ]
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testSnapshotWithMarkerAttributes() throws {
        #if canImport(VisualTestingMacros)
        assertMacroExpansion(
            """
            @SnapshotSuite("DetailView")
            struct DetailSnapshots {
                @Snapshot
                @InNavigation
                @WithoutAnimation
                func detail() -> some View {
                    DetailView()
                }

            \(runner)
            }
            """,
            expandedSource: """
            struct DetailSnapshots {
                func detail() -> some View {
                    DetailView()
                }

            \(runner)

                nonisolated static var __snapshotCases: [SnapshotCase] {
                    [
                        SnapshotCase(
                            viewName: "DetailView",
                            stateName: "detail",
                            kind: .view(inNavigation: true, disableAnimations: true),
                            makeView: {
                                AnyView(DetailSnapshots().detail())
                            }
                        )
                    ]
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Component Snapshots

    func testComponentSnapshotWithSize() throws {
        #if canImport(VisualTestingMacros)
        assertMacroExpansion(
            """
            @SnapshotSuite("Card")
            struct CardSnapshots {
                @ComponentSnapshot(width: 340, height: 120)
                func level1() -> some View {
                    Card()
                }

            \(runner)
            }
            """,
            expandedSource: """
            struct CardSnapshots {
                func level1() -> some View {
                    Card()
                }

            \(runner)

                nonisolated static var __snapshotCases: [SnapshotCase] {
                    [
                        SnapshotCase(
                            viewName: "Card",
                            stateName: "level1",
                            kind: .component(width: 340, height: 120),
                            makeView: {
                                AnyView(CardSnapshots().level1())
                            }
                        )
                    ]
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testComponentSnapshotWithoutSize() throws {
        #if canImport(VisualTestingMacros)
        assertMacroExpansion(
            """
            @SnapshotSuite("Chip")
            struct ChipSnapshots {
                @ComponentSnapshot
                func basic() -> some View {
                    Chip()
                }

            \(runner)
            }
            """,
            expandedSource: """
            struct ChipSnapshots {
                func basic() -> some View {
                    Chip()
                }

            \(runner)

                nonisolated static var __snapshotCases: [SnapshotCase] {
                    [
                        SnapshotCase(
                            viewName: "Chip",
                            stateName: "basic",
                            kind: .component(width: nil, height: nil),
                            makeView: {
                                AnyView(ChipSnapshots().basic())
                            }
                        )
                    ]
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Mixed

    func testMixedSnapshotTypes() throws {
        #if canImport(VisualTestingMacros)
        assertMacroExpansion(
            """
            @SnapshotSuite("Mixed")
            struct MixedSnapshots {
                @Snapshot
                func full() -> some View {
                    FullView()
                }

                @ComponentSnapshot(width: 100, height: 50)
                func part() -> some View {
                    PartView()
                }

            \(runner)
            }
            """,
            expandedSource: """
            struct MixedSnapshots {
                func full() -> some View {
                    FullView()
                }
                func part() -> some View {
                    PartView()
                }

            \(runner)

                nonisolated static var __snapshotCases: [SnapshotCase] {
                    [
                        SnapshotCase(
                            viewName: "Mixed",
                            stateName: "full",
                            kind: .view(inNavigation: false, disableAnimations: false),
                            makeView: {
                                AnyView(MixedSnapshots().full())
                            }
                        ),
                        SnapshotCase(
                            viewName: "Mixed",
                            stateName: "part",
                            kind: .component(width: 100, height: 50),
                            makeView: {
                                AnyView(MixedSnapshots().part())
                            }
                        )
                    ]
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Diagnostics

    func testMissingRunnerEmitsError() throws {
        #if canImport(VisualTestingMacros)
        assertMacroExpansion(
            """
            @SnapshotSuite("SettingsView")
            struct SettingsSnapshots {
                @Snapshot
                func loaded() -> some View {
                    SettingsView()
                }
            }
            """,
            expandedSource: """
            struct SettingsSnapshots {
                func loaded() -> some View {
                    SettingsView()
                }

                nonisolated static var __snapshotCases: [SnapshotCase] {
                    [
                        SnapshotCase(
                            viewName: "SettingsView",
                            stateName: "loaded",
                            kind: .view(inNavigation: false, disableAnimations: false),
                            makeView: {
                                AnyView(SettingsSnapshots().loaded())
                            }
                        )
                    ]
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@SnapshotSuite requires a hand-written runner test. Add to the struct: "
                        + "@Test func snapshots() { for snapshotCase in Self.__snapshotCases { snapshotCase.run() } }",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testSnapshotSuiteOnNonStruct() throws {
        #if canImport(VisualTestingMacros)
        assertMacroExpansion(
            """
            @SnapshotSuite("Bad")
            class BadSnapshots {
            }
            """,
            expandedSource: """
            class BadSnapshots {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@SnapshotSuite can only be applied to structs",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testSnapshotOnNonFunction() throws {
        #if canImport(VisualTestingMacros)
        assertMacroExpansion(
            """
            struct Bad {
                @Snapshot
                var view: some View {
                    Text("bad")
                }
            }
            """,
            expandedSource: """
            struct Bad {
                var view: some View {
                    Text("bad")
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Snapshot and @ComponentSnapshot can only be applied to functions",
                    line: 2,
                    column: 5
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
