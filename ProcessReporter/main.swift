import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

ApplicationMonitor.shared.startMouseMonitoring()
ApplicationMonitor.shared.startWindowFocusMonitoring()
ApplicationMonitor.shared.onWindowFocusChanged = { print($0) }
ApplicationMonitor.shared.onMouseClicked = { print($0) }

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
