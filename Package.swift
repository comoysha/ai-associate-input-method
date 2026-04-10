// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "AIAssociateInputMethod",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "AIAssociateInputMethod",
            path: "AIAssociateInputMethod",
            linkerSettings: [
                .unsafeFlags(["-framework", "ApplicationServices"]),
            ]
        )
    ]
)
