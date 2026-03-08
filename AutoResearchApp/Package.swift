// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "AutoResearchApp",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "AutoResearchApp",
            path: "Sources"
        ),
        .testTarget(
            name: "AutoResearchAppTests",
            dependencies: ["AutoResearchApp"],
            path: "Tests"
        )
    ]
)
