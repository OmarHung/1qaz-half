// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "1qaz-Half",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "OneQazHalf",
            path: "Sources/OneQazHalf",
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("CoreGraphics")
            ]
        )
    ]
)
