import AppKit
import WebKit

enum Site: Int, CaseIterable {
    case youtube, music

    var title: String { self == .youtube ? "YouTube" : "Music" }
    var home: URL {
        URL(string: self == .youtube ? "https://www.youtube.com" : "https://music.youtube.com")!
    }
}

/// Panel that can take keyboard focus (search box, shortcuts).
final class PlayerPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Owns the panel and one web view per site. Both web views stay alive,
/// so Music keeps playing while you browse YouTube, and while the panel is hidden.
@MainActor
final class PlayerController: NSObject, NSWindowDelegate, WKUIDelegate {
    // Real Safari UA: Google refuses sign-in from generic embedded-WebKit UAs.
    private static let userAgent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15"
    private static let frameName = "TubeBarPanel"

    private let panel: PlayerPanel
    private let webViews: [WKWebView]
    private let picker: NSSegmentedControl
    private let backButton: NSButton
    private let reloadButton: NSButton
    private let pinButton: NSButton
    private let defaults = UserDefaults.standard
    private(set) var site: Site

    private var currentView: WKWebView { webViews[site.rawValue] }

    var isPinned: Bool {
        get { defaults.bool(forKey: "pinned") }
        set { defaults.set(newValue, forKey: "pinned"); applyPin() }
    }

    override init() {
        site = Site(rawValue: UserDefaults.standard.integer(forKey: "site")) ?? .youtube

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()                  // persistent cookies = stay signed in
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.isElementFullscreenEnabled = true
        webViews = Site.allCases.map { _ in
            let view = WKWebView(frame: .zero, configuration: config)
            view.customUserAgent = PlayerController.userAgent
            view.allowsBackForwardNavigationGestures = true
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }

        panel = PlayerPanel(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 660),
                            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                            backing: .buffered, defer: false)
        picker = NSSegmentedControl(labels: Site.allCases.map(\.title),
                                    trackingMode: .selectOne, target: nil, action: nil)
        backButton = Self.barButton("chevron.left", "Back")
        reloadButton = Self.barButton("arrow.clockwise", "Reload")
        pinButton = Self.barButton("pin", "Keep on Top")
        super.init()

        configurePanel()
        layoutContent()
        applyPin()
        select(site)
    }

    // MARK: Show / hide

    @objc func toggle() {
        if panel.isVisible && panel.isKeyWindow { hide() } else { show() }
    }

    func show(_ newSite: Site? = nil) {
        if let newSite { select(newSite) }
        NSApp.unhideWithoutActivation()
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(currentView)
    }

    @objc func hide() {
        panel.orderOut(nil)
        NSApp.hide(nil)      // hand focus back to the previous app
    }

    // MARK: Actions

    @objc func showYouTube() { show(.youtube) }
    @objc func showMusic() { show(.music) }
    @objc func goBack() { currentView.goBack() }
    @objc func goForward() { currentView.goForward() }
    @objc func reload() { currentView.reload() }
    @objc func togglePin() { isPinned.toggle() }

    @objc private func pickerChanged() {
        select(Site(rawValue: picker.selectedSegment) ?? .youtube)
    }

    private func select(_ newSite: Site) {
        site = newSite
        defaults.set(newSite.rawValue, forKey: "site")
        picker.selectedSegment = newSite.rawValue
        for (index, view) in webViews.enumerated() { view.isHidden = index != newSite.rawValue }
        if currentView.url == nil { currentView.load(URLRequest(url: newSite.home)) }   // lazy load
        panel.makeFirstResponder(currentView)
    }

    private func applyPin() {
        // Pinned = floating mini player that follows you across Spaces.
        panel.level = isPinned ? .floating : .normal
        panel.collectionBehavior = isPinned
            ? [.canJoinAllSpaces, .fullScreenAuxiliary]
            : [.moveToActiveSpace, .fullScreenAuxiliary]
        pinButton.image = NSImage(systemSymbolName: isPinned ? "pin.fill" : "pin",
                                  accessibilityDescription: "Keep on Top")
        pinButton.contentTintColor = isPinned ? .controlAccentColor : nil
    }

    // MARK: NSWindowDelegate

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        hide()
        return false        // keep web views (and playback) alive
    }

    // MARK: WKUIDelegate — target=_blank links

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let url = navigationAction.request.url else { return nil }
        if Self.isYouTube(url) {
            webView.load(navigationAction.request)
        } else {
            NSWorkspace.shared.open(url)        // external links → default browser
        }
        return nil
    }

    // MARK: Setup

    private func configurePanel() {
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.minSize = NSSize(width: 380, height: 260)
        panel.delegate = self
        if !panel.setFrameUsingName(Self.frameName) { panel.center() }
        panel.setFrameAutosaveName(Self.frameName)
    }

    private func layoutContent() {
        picker.target = self
        picker.action = #selector(pickerChanged)
        picker.controlSize = .small
        backButton.target = self;   backButton.action = #selector(goBack)
        reloadButton.target = self; reloadButton.action = #selector(reload)
        pinButton.target = self;    pinButton.action = #selector(togglePin)

        let bar = NSStackView()
        bar.orientation = .horizontal
        bar.spacing = 10
        bar.setViews([backButton, reloadButton], in: .leading)
        bar.setViews([picker], in: .center)
        bar.setViews([pinButton], in: .trailing)
        bar.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        panel.contentView = content
        content.addSubview(bar)
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: content.topAnchor),
            bar.heightAnchor.constraint(equalToConstant: 28),
            bar.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 76),  // clear traffic lights
            bar.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -10),
        ])

        for view in webViews {
            view.uiDelegate = self
            content.addSubview(view)
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: bar.bottomAnchor),
                view.leadingAnchor.constraint(equalTo: content.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: content.trailingAnchor),
                view.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            ])
        }
    }

    private static func barButton(_ symbol: String, _ label: String) -> NSButton {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: label) ?? NSImage()
        let button = NSButton(image: image, target: nil, action: nil)
        button.isBordered = false
        button.toolTip = label
        return button
    }

    private static func isYouTube(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return ["youtube.com", "youtu.be", "google.com"].contains { host == $0 || host.hasSuffix("." + $0) }
    }
}
