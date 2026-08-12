// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwipeableRow",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SwipeableRow", targets: ["SwipeableRow"])
    ],
    targets: [
        .target(name: "SwipeableRow")
    ]
)
