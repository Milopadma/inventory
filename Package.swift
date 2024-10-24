// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Inventory2",
    platforms: [
        .iOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/magicien/GLTFSceneKit.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "Inventory2",
            dependencies: ["GLTFSceneKit"]
        )
    ]
)
