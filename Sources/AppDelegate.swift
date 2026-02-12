import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var marketTimer: MarketTimer!
    private var updateTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        marketTimer = MarketTimer()

        // --- Configure Popover ---
        popover = NSPopover()
        popover.contentSize = NSSize(width: 420, height: 480)
        popover.behavior = .transient
        popover.animates = true
        popover.appearance = NSAppearance(named: .darkAqua)
        popover.contentViewController = NSHostingController(
            rootView: MarketStatusView(timer: marketTimer)
        )

        // --- Configure Status Bar Item ---
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(handleStatusItemClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        updateMenuBar()

        // --- Start 1-second update loop ---
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.marketTimer.update()
                self?.updateMenuBar()
            }
        }
        RunLoop.main.add(updateTimer!, forMode: .common)
    }

    // MARK: - Menu Bar Display

    private func updateMenuBar() {
        guard let button = statusItem.button else { return }

        let isOpen = marketTimer.isMarketOpen
        let countdown = marketTimer.menuBarCountdown

        let title = NSMutableAttributedString()

        // Status dot (colored)
        let dotColor: NSColor = isOpen ? .systemGreen : .systemRed
        let dot = NSAttributedString(
            string: "\u{25CF} ",
            attributes: [
                .foregroundColor: dotColor,
                .font: NSFont.systemFont(ofSize: 9)
            ]
        )
        title.append(dot)

        // Status text + countdown
        let statusLabel = isOpen ? "OPEN" : "CLOSED"
        let text = NSAttributedString(
            string: "\(statusLabel)  \(countdown)",
            attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
                .baselineOffset: 0.5
            ]
        )
        title.append(text)

        button.attributedTitle = title
    }

    // MARK: - Click Handling

    @objc private func handleStatusItemClick() {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - Right-Click Context Menu

    private func showContextMenu() {
        let menu = NSMenu()

        let aboutItem = NSMenuItem(title: "MarketTime v1.0", action: nil, keyEquivalent: "")
        aboutItem.isEnabled = false
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit MarketTime", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil // Reset so left-click shows popover again
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
