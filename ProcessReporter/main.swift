import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

let _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
