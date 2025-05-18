// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CombineGenericNetworking",
    platforms: [
            .iOS(.v17), // Set the minimum iOS version here (e.g., iOS 13)
            .macOS(.v10_15),
            .tvOS(.v13),
            .watchOS(.v6)
        ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CombineGenericNetworking",
            targets: ["CombineGenericNetworking"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CombineGenericNetworking"),
        .testTarget(
            name: "CombineGenericNetworkingTests",
            dependencies: ["CombineGenericNetworking"]
        ),
    ]
)
