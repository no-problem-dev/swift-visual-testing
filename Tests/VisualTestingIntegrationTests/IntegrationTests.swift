#if canImport(UIKit)
import SwiftUI
import Testing
import VisualTesting

// MARK: - Sample Views for Integration Testing

/// Simple view for verifying macro-generated code compiles and runs.
private struct SampleView: View {
    var body: some View {
        VStack {
            Text("Hello, World!")
            Text("Integration Test")
        }
    }
}

private struct SampleComponent: View {
    var body: some View {
        Text("Chip").padding()
    }
}

// MARK: - View Snapshot Integration

/// Verifies that @SnapshotSuite + @Snapshot macros generate compilable @Test methods.
///
/// This is the critical test that would have caught the Swift compiler bug #78611:
/// if the macro generates @Test as direct members (without nested struct),
/// the compilation fails here — not just in assertMacroExpansion string checks.
@SnapshotSuite("SampleView")
@MainActor
struct SampleViewSnapshots {
    @Snapshot
    func hello() -> some View {
        SampleView()
    }

    @Snapshot
    @WithoutAnimation
    func withDisabledAnimation() -> some View {
        SampleView()
    }

    @Snapshot
    @InNavigation
    func inNavigationStack() -> some View {
        SampleView()
    }

    @Snapshot
    @InNavigation
    @WithoutAnimation
    func allAttributes() -> some View {
        SampleView()
    }

    @Test func snapshots() {
        for snapshotCase in Self.__snapshotCases {
            snapshotCase.run()
        }
    }
}

// MARK: - Component Snapshot Integration

/// Verifies @ComponentSnapshot macro works with size parameters.
@SnapshotSuite("SampleComponent")
@MainActor
struct SampleComponentSnapshots {
    @ComponentSnapshot(width: 200, height: 60)
    func withSize() -> some View {
        SampleComponent()
    }

    @ComponentSnapshot()
    func withoutSize() -> some View {
        SampleComponent()
    }

    @Test func snapshots() {
        for snapshotCase in Self.__snapshotCases {
            snapshotCase.run()
        }
    }
}

// MARK: - iPad Split Widths and Dynamic Type

/// Verifies the iPad window widths and the Dynamic Type axis render end-to-end.
///
/// These axes are opt-in: `SnapshotConfiguration.default` keeps the original three devices
/// and the standard text size, so adding them here must not change any other suite's output.
@Suite("iPad widths and Dynamic Type")
@MainActor
struct AdaptiveAxesSnapshots {
    @Test func splitWidths() {
        VisualTesting.assertViewSnapshot(
            of: SampleView(),
            viewName: "AdaptiveSample",
            stateName: "splitWidths",
            inNavigation: false,
            disableAnimations: true,
            configuration: SnapshotConfiguration(
                devices: [.iPadPro11Half, .iPadPro11Third],
                themes: [.light],
                locales: ["en"]
            ),
            file: #filePath,
            line: #line
        )
    }

    /// The standard size keeps the 2.0 file name; only the accessibility size gets a suffix.
    @Test func dynamicType() {
        VisualTesting.assertViewSnapshot(
            of: SampleView(),
            viewName: "AdaptiveSample",
            stateName: "dynamicType",
            inNavigation: false,
            disableAnimations: true,
            configuration: SnapshotConfiguration(
                devices: [.iPhoneSE],
                themes: [.light],
                locales: ["en"],
                dynamicTypes: [.standard, .accessibility3]
            ),
            file: #filePath,
            line: #line
        )
    }
}

// MARK: - Mixed Integration

/// Verifies @Snapshot and @ComponentSnapshot can coexist in the same suite.
@SnapshotSuite("MixedSample")
@MainActor
struct MixedSampleSnapshots {
    @Snapshot
    func fullScreen() -> some View {
        SampleView()
    }

    @ComponentSnapshot(width: 200, height: 60)
    func component() -> some View {
        SampleComponent()
    }

    @Test func snapshots() {
        for snapshotCase in Self.__snapshotCases {
            snapshotCase.run()
        }
    }
}
#endif
