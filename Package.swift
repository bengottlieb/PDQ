// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PDQ",
	 platforms: [
			  .macOS(.v12),
			  .iOS(.v14),
			  .watchOS(.v8)
		 ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "PDQ",
            targets: ["PDQ"]),
    ],
    dependencies: [
        // Here we define our package's external dependencies
        // and from where they can be fetched:
        .package(
            url: "https://github.com/bengottlieb/CrossPlatformKit",
            from: "1.0.10"
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "PDQ",
				dependencies: ["CrossPlatformKit"]),
    ]
)
