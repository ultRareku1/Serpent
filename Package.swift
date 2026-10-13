// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Serpent",
    defaultLocalization: "en",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "Serpent", targets: ["Serpent"])],
    targets: [
        .executableTarget(name: "Serpent", resources: [.process("Resources")]),
        .testTarget(name: "SerpentTests", dependencies: ["Serpent"])
    ]
)
