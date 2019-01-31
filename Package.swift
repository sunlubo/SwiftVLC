// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SwiftVLC",
  products: [
    .library(name: "SwiftVLC", targets: ["SwiftVLC"])
  ],
  dependencies: [
    .package(url: "https://github.com/sunlubo/SwiftSDL2.git", .branch("master"))
  ],
  targets: [
    .systemLibrary(name: "CVLC", pkgConfig: "vlc"),
    .target(name: "SwiftVLC", dependencies: ["CVLC"]),
    .target(name: "SwiftVLCDemo", dependencies: ["SwiftVLC"]),
    .target(name: "SimplePlayer", dependencies: ["SwiftVLC", "SwiftSDL2"]),
    .testTarget(name: "SwiftVLCTests", dependencies: ["SwiftVLC"])
  ]
)
