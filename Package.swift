// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SoberLifeCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SoberLifeCore",
            targets: ["SoberLifeCore"]
        )
    ],
    targets: [
        .target(
            name: "SoberLifeCore"
        ),
        .testTarget(
            name: "SoberLifeCoreTests",
            dependencies: ["SoberLifeCore"]
        )
    ]
)
