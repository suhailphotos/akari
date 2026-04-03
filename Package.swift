// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "akari",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "akari"
        ),
        .testTarget(
            name: "akariTests",
            dependencies: ["akari"]
        ),
    ]
)
