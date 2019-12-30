// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "PointAndShoot",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "PointAndShoot",
            targets: ["PointAndShoot"]),
    ],
    targets: [
        .target(
            name: "PointAndShoot",
            dependencies: []),
        .testTarget(
            name: "PointAndShootTests",
            dependencies: ["PointAndShoot"]),
    ]
)
