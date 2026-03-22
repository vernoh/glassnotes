import AppleProductTypes
import PackageDescription

let package = Package(
    name: "GlassNotes",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "GlassNotes",
            targets: ["AppModule"],
            bundleIdentifier: "com.vernoh.glassnotes",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .note),
            accentColor: .presetColor(.blue),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeLeft,
                .landscapeRight,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            appCategory: .productivity
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ]
)