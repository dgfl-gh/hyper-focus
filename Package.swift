// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "focus-app",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/Building42/Telegraph.git", from: "0.30.0"),
        .package(url: "https://github.com/envoy/Embassy.git", from: "4.1.4"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "focus-app",
            dependencies: ["Telegraph", "Embassy"]),
        .testTarget(
            name: "focus-appTests",
            dependencies: ["focus-app"]),
    ]
)
