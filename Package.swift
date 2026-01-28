// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AsyncReactor",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "AsyncReactor",
            targets: ["AsyncReactor"]
        ),
        .library(
            name: "Reactor",
            targets: ["Reactor"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ReactorBase",
            dependencies: []
        ),
        .target(
            name: "Reactor",
            dependencies: ["ReactorBase"]
        ),
        .target(
            name: "AsyncReactor",
            dependencies: ["ReactorBase"]
        ),
        .testTarget(
            name: "AsyncReactorTests",
            dependencies: ["AsyncReactor"],
            path: "Tests"
        ),
    ]
)
