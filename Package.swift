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
        ),
        .library(
            name: "SoberLifeAppShell",
            targets: ["SoberLifeAppShell"]
        )
    ],
    targets: [
        .target(
            name: "SoberLifeCore"
        ),
        .target(
            name: "SoberLifeAppShell",
            dependencies: ["SoberLifeCore"]
        ),
        .testTarget(
            name: "SoberLifeCoreTests",
            dependencies: ["SoberLifeCore", "SoberLifeAppShell"]
        )
    ]
)
