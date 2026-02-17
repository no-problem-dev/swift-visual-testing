// swift-tools-version: 6.2
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "swift-visual-testing",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
    ],
    products: [
        .library(
            name: "VisualTesting",
            targets: ["VisualTesting"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", .upToNextMajor(from: "602.0.0")),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.17.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin.git", .upToNextMajor(from: "1.4.0")),
    ],
    targets: [
        // MARK: - Macro Implementation
        .macro(
            name: "VisualTestingMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),

        // MARK: - Client Library
        .target(
            name: "VisualTesting",
            dependencies: [
                "VisualTestingMacros",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),

        // MARK: - Tests
        .testTarget(
            name: "VisualTestingMacrosTests",
            dependencies: [
                "VisualTestingMacros",
                "VisualTesting",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),

        // MARK: - Integration Tests (iOS only)
        // Verifies that macros generate compilable code (catches issues assertMacroExpansion misses).
        // Build with: xcodebuild build-for-testing -scheme swift-visual-testing -destination 'platform=iOS Simulator,...'
        .testTarget(
            name: "VisualTestingIntegrationTests",
            dependencies: [
                "VisualTesting",
            ]
        ),
    ]
)
