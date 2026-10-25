import AppKit
import Carbon.HIToolbox
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var player: PlayerController!
    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        player = PlayerController()
        buildMainMenu()
        buildStatusItem()
        // ⌥` = Option + the key left of 1 (physical key, layout-independent)
        hotKey = HotKey(keyCode: kVK_ANSI_Grave, modifiers: optionKey) { [weak self] in
            self?.player.toggle()
        }
    }

    /// Opening the app again (Finder/Spotlight/Raycast) shows the player.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        player.show()
        return false
    }

    // MARK: Menu bar icon

    private func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "play.rectangle.fill", accessibilityDescription: "TubeBar")
        button.target = self
        button.action = #selector(statusItemClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    /// Left-click toggles the player; right-click (or ⌃-click) opens the menu.
    @objc private func statusItemClicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            statusItem.menu = statusMenu()
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            player.toggle()
        }
    }

    private func statusMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(item("Show / Hide", #selector(PlayerController.toggle), target: player,
                          key: "`", modifiers: .option))
        menu.addItem(item("YouTube", #selector(PlayerController.showYouTube), target: player))
        menu.addItem(item("YouTube Music", #selector(PlayerController.showMusic), target: player))
        menu.addItem(.separator())
        let pin = item("Keep on Top", #selector(PlayerController.togglePin), target: player)
        pin.state = player.isPinned ? .on : .off
        menu.addItem(pin)
        let login = item("Open at Login", #selector(toggleLoginItem), target: self)
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        menu.addItem(.separator())
        menu.addItem(item("Quit TubeBar", #selector(NSApplication.terminate(_:)), target: NSApp))
        return menu
    }

    @objc private func toggleLoginItem() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled { try service.unregister() } else { try service.register() }
        } catch {
            NSSound.beep()
        }
    }

    // MARK: Main menu (never shown, but needed so ⌘C/⌘V/⌘W etc. work in the panel)

    private func buildMainMenu() {
        let app = NSMenu()
        app.addItem(item("Hide Player", #selector(PlayerController.hide), target: player, key: "w"))
        app.addItem(item("Quit TubeBar", #selector(NSApplication.terminate(_:)), target: NSApp, key: "q"))

        let edit = NSMenu(title: "Edit")
        edit.addItem(item("Undo", Selector(("undo:")), target: nil, key: "z"))
        edit.addItem(item("Redo", Selector(("redo:")), target: nil, key: "z", modifiers: [.command, .shift]))
        edit.addItem(.separator())
        edit.addItem(item("Cut", #selector(NSText.cut(_:)), target: nil, key: "x"))
        edit.addItem(item("Copy", #selector(NSText.copy(_:)), target: nil, key: "c"))
        edit.addItem(item("Paste", #selector(NSText.paste(_:)), target: nil, key: "v"))
        edit.addItem(item("Select All", #selector(NSText.selectAll(_:)), target: nil, key: "a"))

        let view = NSMenu(title: "View")
        view.addItem(item("YouTube", #selector(PlayerController.showYouTube), target: player, key: "1"))
        view.addItem(item("YouTube Music", #selector(PlayerController.showMusic), target: player, key: "2"))
        view.addItem(item("Back", #selector(PlayerController.goBack), target: player, key: "["))
        view.addItem(item("Forward", #selector(PlayerController.goForward), target: player, key: "]"))
        view.addItem(item("Reload", #selector(PlayerController.reload), target: player, key: "r"))
        view.addItem(item("Keep on Top", #selector(PlayerController.togglePin), target: player, key: "t"))

        let main = NSMenu()
        for submenu in [app, edit, view] {
            let holder = NSMenuItem()
            holder.submenu = submenu
            main.addItem(holder)
        }
        NSApp.mainMenu = main
    }

    private func item(_ title: String, _ action: Selector, target: AnyObject?,
                      key: String = "", modifiers: NSEvent.ModifierFlags = .command) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = target
        item.keyEquivalentModifierMask = modifiers
        return item
    }
}
