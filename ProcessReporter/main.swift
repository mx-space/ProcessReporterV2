import AppKit
import Frostflake
import SwiftData

func main() {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate

    Task { @MainActor in
        Database.shared.initialize()
    }

    Frostflake.setup(sharedGenerator: .init(generatorIdentifier: 2025))

    _ = Reporter()
    _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
}

main()
