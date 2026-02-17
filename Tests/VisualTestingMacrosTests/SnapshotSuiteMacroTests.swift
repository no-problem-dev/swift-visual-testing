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
#endif

final class SnapshotSuiteMacroTests: XCTestCase {

    // MARK: - Basic @Snapshot

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
            }
            """,
            expandedSource: """
            struct SettingsSnapshots {
                func loaded() -> some View {
                    SettingsView()
                }

                @Suite("SettingsView")
                @MainActor
                struct __VisualTests {
                    @Test("loaded")
                    func _loaded() {
                        let _outer = SettingsSnapshots()
                        let _view = _outer.loaded()
                        VisualTesting.assertViewSnapshot(
                            of: _view,
                            viewName: "SettingsView",
                            stateName: "loaded",
                            inNavigation: false,
                            disableAnimations: false,
                            file: #filePath, line: #line
                        )
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - @InNavigation

    func testSnapshotWithInNavigation() throws {
        #if canImport(VisualTestingMacros)
        assertMacroExpansion(
            """
            @SnapshotSuite("InterestEditView")
            struct InterestEditSnapshots {
                @Snapshot
                @InNavigation
                func withCategories() -> some View {
                    InterestEditView()
                }
            }
            """,
            expandedSource: """
            struct InterestEditSnapshots {
                func withCategories() -> some View {
                    InterestEditView()
                }

                @Suite("InterestEditView")
                @MainActor
                struct __VisualTests {
                    @Test("withCategories")
                    func _withCategories() {
                        let _outer = InterestEditSnapshots()
                        let _view = _outer.withCategories()
                        VisualTesting.assertViewSnapshot(
                            of: _view,
                            viewName: "InterestEditView",
                            stateName: "withCategories",
                            inNavigation: true,
                            disableAnimations: false,
                            file: #filePath, line: #line
                        )
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - @WithoutAnimation

    func testSnapshotWithoutAnimation() throws {
        #if canImport(VisualTestingMacros)
        assertMacroExpansion(
            """
            @SnapshotSuite("BreathAnimationView")
            struct BreathAnimationSnapshots {
                @Snapshot
                @WithoutAnimation
                func initial() -> some View {
                    BreathAnimationView(onComplete: { })
                }
            }
            """,
            expandedSource: """
            struct BreathAnimationSnapshots {
                func initial() -> some View {
                    BreathAnimationView(onComplete: { })
                }

                @Suite("BreathAnimationView")
                @MainActor
                struct __VisualTests {
                    @Test("initial")
                    func _initial() {
                        let _outer = BreathAnimationSnapshots()
                        let _view = _outer.initial()
                        VisualTesting.assertViewSnapshot(
                            of: _view,
                            viewName: "BreathAnimationView",
                            stateName: "initial",
                            inNavigation: false,
                            disableAnimations: true,
                            file: #filePath, line: #line
                        )
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - @ComponentSnapshot with size

    func testComponentSnapshotWithSize() throws {
        #if canImport(VisualTestingMacros)
        assertMacroExpansion(
            """
            @SnapshotSuite("Card")
            struct CardSnapshots {
                @ComponentSnapshot(width: 340, height: 120)
                func level1() -> some View {
                    Card(elevation: .level1) { Text("Card") }
                }
            }
            """,
            expandedSource: """
            struct CardSnapshots {
                func level1() -> some View {
                    Card(elevation: .level1) { Text("Card") }
                }

                @Suite("Card")
                @MainActor
                struct __VisualTests {
                    @Test("level1")
                    func _level1() {
                        let _outer = CardSnapshots()
                        let _view = _outer.level1()
                        VisualTesting.assertComponentSnapshot(
                            of: _view,
                            componentName: "Card",
                            stateName: "level1",
                            size: CGSize(width: 340, height: 120),
                            file: #filePath, line: #line
                        )
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - @ComponentSnapshot without size

    func testComponentSnapshotWithoutSize() throws {
        #if canImport(VisualTestingMacros)
        assertMacroExpansion(
            """
            @SnapshotSuite("Badge")
            struct BadgeSnapshots {
                @ComponentSnapshot()
                func small() -> some View {
                    Badge(text: "New")
                }
            }
            """,
            expandedSource: """
            struct BadgeSnapshots {
                func small() -> some View {
                    Badge(text: "New")
                }

                @Suite("Badge")
                @MainActor
                struct __VisualTests {
                    @Test("small")
                    func _small() {
                        let _outer = BadgeSnapshots()
                        let _view = _outer.small()
                        VisualTesting.assertComponentSnapshot(
                            of: _view,
                            componentName: "Badge",
                            stateName: "small",
                            size: nil,
                            file: #filePath, line: #line
                        )
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Multiple functions

    func testMultipleFunctions() throws {
        #if canImport(VisualTestingMacros)
        assertMacroExpansion(
            """
            @SnapshotSuite("SettingsView")
            struct SettingsSnapshots {
                @Snapshot
                func loaded() -> some View {
                    SettingsView()
                }

                @Snapshot
                func loading() -> some View {
                    SettingsView()
                }

                @Snapshot
                func error() -> some View {
                    SettingsView()
                }
            }
            """,
            expandedSource: """
            struct SettingsSnapshots {
                func loaded() -> some View {
                    SettingsView()
                }
                func loading() -> some View {
                    SettingsView()
                }
                func error() -> some View {
                    SettingsView()
                }

                @Suite("SettingsView")
                @MainActor
                struct __VisualTests {
                    @Test("loaded")
                    func _loaded() {
                        let _outer = SettingsSnapshots()
                        let _view = _outer.loaded()
                        VisualTesting.assertViewSnapshot(
                            of: _view,
                            viewName: "SettingsView",
                            stateName: "loaded",
                            inNavigation: false,
                            disableAnimations: false,
                            file: #filePath, line: #line
                        )
                    }
                    @Test("loading")
                    func _loading() {
                        let _outer = SettingsSnapshots()
                        let _view = _outer.loading()
                        VisualTesting.assertViewSnapshot(
                            of: _view,
                            viewName: "SettingsView",
                            stateName: "loading",
                            inNavigation: false,
                            disableAnimations: false,
                            file: #filePath, line: #line
                        )
                    }
                    @Test("error")
                    func _error() {
                        let _outer = SettingsSnapshots()
                        let _view = _outer.error()
                        VisualTesting.assertViewSnapshot(
                            of: _view,
                            viewName: "SettingsView",
                            stateName: "error",
                            inNavigation: false,
                            disableAnimations: false,
                            file: #filePath, line: #line
                        )
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Mixed @Snapshot and @ComponentSnapshot

    func testMixedSnapshotTypes() throws {
        #if canImport(VisualTestingMacros)
        assertMacroExpansion(
            """
            @SnapshotSuite("MyView")
            struct MyViewSnapshots {
                @Snapshot
                func fullScreen() -> some View {
                    MyView()
                }

                @ComponentSnapshot(width: 200, height: 100)
                func widget() -> some View {
                    MyWidget()
                }
            }
            """,
            expandedSource: """
            struct MyViewSnapshots {
                func fullScreen() -> some View {
                    MyView()
                }
                func widget() -> some View {
                    MyWidget()
                }

                @Suite("MyView")
                @MainActor
                struct __VisualTests {
                    @Test("fullScreen")
                    func _fullScreen() {
                        let _outer = MyViewSnapshots()
                        let _view = _outer.fullScreen()
                        VisualTesting.assertViewSnapshot(
                            of: _view,
                            viewName: "MyView",
                            stateName: "fullScreen",
                            inNavigation: false,
                            disableAnimations: false,
                            file: #filePath, line: #line
                        )
                    }
                    @Test("widget")
                    func _widget() {
                        let _outer = MyViewSnapshots()
                        let _view = _outer.widget()
                        VisualTesting.assertComponentSnapshot(
                            of: _view,
                            componentName: "MyView",
                            stateName: "widget",
                            size: CGSize(width: 200, height: 100),
                            file: #filePath, line: #line
                        )
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Error: Applied to non-struct

    func testSnapshotSuiteOnNonStruct() throws {
        #if canImport(VisualTestingMacros)
        assertMacroExpansion(
            """
            @SnapshotSuite("MyView")
            class NotAStruct {
            }
            """,
            expandedSource: """
            class NotAStruct {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@SnapshotSuite can only be applied to structs", line: 1, column: 1)
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Error: @Snapshot on non-function

    func testSnapshotOnNonFunction() throws {
        #if canImport(VisualTestingMacros)
        assertMacroExpansion(
            """
            @Snapshot
            var notAFunction = 42
            """,
            expandedSource: """
            var notAFunction = 42
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Snapshot and @ComponentSnapshot can only be applied to functions", line: 1, column: 1)
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - @InNavigation + @WithoutAnimation combined

    func testAllAttributesCombined() throws {
        #if canImport(VisualTestingMacros)
        assertMacroExpansion(
            """
            @SnapshotSuite("OnboardingView")
            struct OnboardingSnapshots {
                @Snapshot
                @InNavigation
                @WithoutAnimation
                func welcome() -> some View {
                    OnboardingView()
                }
            }
            """,
            expandedSource: """
            struct OnboardingSnapshots {
                func welcome() -> some View {
                    OnboardingView()
                }

                @Suite("OnboardingView")
                @MainActor
                struct __VisualTests {
                    @Test("welcome")
                    func _welcome() {
                        let _outer = OnboardingSnapshots()
                        let _view = _outer.welcome()
                        VisualTesting.assertViewSnapshot(
                            of: _view,
                            viewName: "OnboardingView",
                            stateName: "welcome",
                            inNavigation: true,
                            disableAnimations: true,
                            file: #filePath, line: #line
                        )
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
