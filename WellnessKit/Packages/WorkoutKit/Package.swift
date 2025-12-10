// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WorkoutKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "WorkoutKit",
            targets: ["WorkoutKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.10.0"),
        .package(path: "../CoreDependencies"),
    ],
    targets: [
        .target(
            name: "WorkoutKit",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "CoreDependencies", package: "CoreDependencies"),
            ]),
        .testTarget(
            name: "WorkoutKitTests",
            dependencies: ["WorkoutKit"]),
    ]
)