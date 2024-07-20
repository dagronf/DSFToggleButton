// swift-tools-version: 5.4

import PackageDescription

let package = Package(
	name: "DSFToggleButton",
	platforms: [
		.macOS(.v10_13)
	],
	products: [
		.library(name: "DSFToggleButton", targets: ["DSFToggleButton"]),
		.library(name: "DSFToggleButton-static", type: .static, targets: ["DSFToggleButton"]),
		.library(name: "DSFToggleButton-shared", type: .dynamic, targets: ["DSFToggleButton"]),
	],
	dependencies: [
		.package(url: "https://github.com/dagronf/DSFAppearanceManager", .upToNextMinor(from: "3.5.0"))
	],
	targets: [
		.target(
			name: "DSFToggleButton",
			dependencies: ["DSFAppearanceManager"]),
		.testTarget(
			name: "DSFToggleButtonTests",
			dependencies: ["DSFToggleButton"]),
	]
)
