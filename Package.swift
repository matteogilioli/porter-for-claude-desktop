// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Porter",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "Porter", path: "Sources/Porter"),
    ]
)
