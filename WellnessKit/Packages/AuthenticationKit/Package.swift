// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "AuthenticationKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "AuthenticationKit",
            targets: ["AuthenticationKit"]
        ),
    ],
    dependencies: [
        .package(path: "../CoreDependencies"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.10.0"),
    ],
    targets: [
        .target(
            name: "AuthenticationKit",
            dependencies: [
                .product(name: "CoreDependencies", package: "CoreDependencies"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .testTarget(
            name: "AuthenticationKitTests",
            dependencies: [
                "AuthenticationKit",
                .product(name: "CoreDependencies", package: "CoreDependencies"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
    ]
)
