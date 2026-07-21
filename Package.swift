// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Takukku",
    defaultLocalization: "ms",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "SolatNotch", targets: ["SolatNotch"])],
    dependencies: [
        .package(path: "Vendor/DynamicNotchKit"),
        .package(url: "https://github.com/batoulapps/adhan-swift.git", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "SolatNotch",
            dependencies: ["DynamicNotchKit", .product(name: "Adhan", package: "adhan-swift")],
            path: "Sources/SolatNotch",
            resources: [.process("Resources")]
        ),
        .testTarget(name: "SolatNotchTests", dependencies: ["SolatNotch"], path: "Tests/SolatNotchTests")
    ]
)
