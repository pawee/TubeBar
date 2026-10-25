// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TubeBar",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "TubeBar", path: "Sources/TubeBar")
    ]
)
