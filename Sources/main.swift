import Cocoa

// MarketTime - NYSE Market Status Menu Bar App
// Runs as an accessory app (no Dock icon, menu bar only)

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
