// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "prlctl",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "prlctl",
            targets: ["prlctl"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(
            url: "https://github.com/JohnSundell/ShellOut",
            from: "2.3.0"
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "prlctl",
            dependencies: [
                .product(
                    name: "ShellOut",
                    package: "ShellOut"
                )
            ]),
        .testTarget(
            name: "prlctlTests",
            dependencies: ["prlctl"],
            resources: [
                .copy("resources/invalid-vm-details.json"),
                .copy("resources/invalid-vm.json"),
                .copy("resources/packaged-vm-details.json"),
                .copy("resources/packaged-vm.json"),
                .copy("resources/resuming-vm-details.json"),
                .copy("resources/resuming-vm.json"),
                .copy("resources/running-vm-with-ip-details.json"),
                .copy("resources/running-vm-with-ip.json"),
                .copy("resources/running-vm-with-ipv6-details.json"),
                .copy("resources/running-vm-with-ipv6.json"),
                .copy("resources/running-vm-without-ip-details.json"),
                .copy("resources/running-vm-without-ip.json"),
                .copy("resources/stopped-vm-details.json"),
                .copy("resources/stopped-vm.json"),
                .copy("resources/suspended-vm-details.json"),
                .copy("resources/suspended-vm.json"),
                .copy("resources/vm-list.json"),
                .copy("resources/vm-snapshot-list.json")
            ]
        )
    ]
)
