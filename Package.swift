import PackageDescription

let package = Package(
    name: "Swiffer",
    targets: [
        Target(name: "Core"),
        Target(name: "Checkers", dependencies: ["Core"]),
        Target(name: "Swiffer", dependencies: ["Core", "Checkers"])
    ]
)
