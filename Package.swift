// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Welltech",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17)
    ],
    products: [
        .executable(
            name: "Welltech",
            targets: ["Welltech"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.10.0"),
        .package(path: "./WellnessKit/Packages/CoreDependencies"),
        .package(path: "./WellnessKit/Packages/AuthenticationKit"),
    ],
    targets: [
        .executableTarget(
            name: "Welltech",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "CoreDependencies", package: "CoreDependencies"),
                .product(name: "AuthenticationKit", package: "AuthenticationKit"),
            ]
        ),
        .testTarget(
            name: "WelltechTests",
            dependencies: [
                "Welltech",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "CoreDependencies", package: "CoreDependencies"),
                .product(name: "AuthenticationKit", package: "AuthenticationKit"),
            ]
        ),
    ]
)
