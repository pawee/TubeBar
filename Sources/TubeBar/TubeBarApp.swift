import AppKit

@main
struct TubeBarApp {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)   // no Dock icon, not in ⌘-Tab
        withExtendedLifetime(delegate) { app.run() }
    }
}
