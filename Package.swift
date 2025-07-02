// swift-tools-version: 6.0
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "CoordinatorKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v13),
        .watchOS(.v9),
    ],
    products: [
        .library(
            name: "CoordinatorKit",
            targets: ["CoordinatorKit"]
        ),
        .library(
            name: "CoordinatorKitInterface",
            targets: ["CoordinatorKitInterface"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        /// Interface module (shared between runtime & macro)
        .target(
            name: "CoordinatorKitInterface",
            dependencies: []
        ),

        /// Macro implementation
        .macro(
            name: "CoordinatorKitMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        /// Runtime coordinator logic
        .target(
            name: "CoordinatorKit",
            dependencies: [
                "CoordinatorKitInterface",   // ✅ Interface protocol
                "CoordinatorKitMacros"       // ✅ Macro expansion
            ]
        ),

        /// Test target
        .testTarget(
            name: "CoordinatorKitTests",
            dependencies: [
                "CoordinatorKit",
                "CoordinatorKitInterface",
                "CoordinatorKitMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ]
        ),
    ]
)

