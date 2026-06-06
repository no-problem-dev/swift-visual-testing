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
