// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Checkpoint",
	platforms: [
		.macOS(.v13)
	],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Checkpoint",
            targets: ["Checkpoint"]),
    ],
	dependencies: [
		// 💧 A server-side Swift web framework.
		.package(url: "https://github.com/vapor/vapor.git", from: "4.99.3"),
		// Redis. Rate-Limit middleware
		.package(url: "https://github.com/vapor/redis.git", from: "4.0.0"),
	],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Checkpoint",
			dependencies: [
				.product(name: "Vapor", package: "vapor"),
				.product(name: "Redis", package: "redis")
			]
		),
        .testTarget(
            name: "CheckpointTests",
            dependencies: ["Checkpoint"]
        ),
    ]
)
