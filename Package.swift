// swift-tools-version:5.1

import PackageDescription

// @FIXME: Change this to a `conditional:` argument when that feature is
// implemented by SPM and incorporated into Xcode:
let etceteraBranchName = "develop"
// Proposal: https://github.com/apple/swift-evolution/blob/master/proposals/0273-swiftpm-conditional-target-dependencies.md

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
    dependencies: [
        .package(url: "https://github.com/jaredsinclair/etcetera.git", .branch(etceteraBranchName)),
        .package(url: "https://github.com/jaredsinclair/OrientationObserver", .branch("master")),
    ],
    targets: [
        .target(
            name: "PointAndShoot",
            dependencies: [
                "OrientationObserver",
                "Etcetera"]),
        .testTarget(
            name: "PointAndShootTests",
            dependencies: ["PointAndShoot"]),
    ]
)
