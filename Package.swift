// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Porter",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.6"),
    ],
    targets: [
        .executableTarget(name: "Porter", dependencies: [.product(name: "Sparkle", package: "Sparkle")],
                          path: "Sources/Porter",
                          // Sparkle.framework: next to the binary in the build folder, in Contents/Frameworks in the app.
                          linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path",
                                                         "-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]),
    ]
)
