// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UsageMonitorCore",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "UsageMonitorCore",
            targets: ["UsageMonitorCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.1.1")
    ],
    targets: [
        .target(
            name: "UsageMonitorCore",
            dependencies: [.product(name: "GRDB", package: "GRDB.swift")],
            path: "Sources/UsageMonitorCore"
        ),
        .testTarget(
            name: "UsageMonitorCoreTests",
            dependencies: ["UsageMonitorCore"],
            path: "Tests/UsageMonitorCoreTests"
        )
    ]
)
