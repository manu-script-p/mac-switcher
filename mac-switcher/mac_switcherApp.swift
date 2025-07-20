//
//  mac_switcherApp.swift
//  mac-switcher
//
//  Created by Manu Prasad on 20/07/25.
//

import SwiftUI
import AppKit

@main
struct mac_switcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var windowManager = WindowManager()
    @StateObject private var licenseManager = LicenseManager()
    
    var body: some Scene {
        Settings {
            ContentView()
                .environmentObject(windowManager)
                .environmentObject(licenseManager)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var isEnabled = true
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon and make it a background app
        NSApp.setActivationPolicy(.accessory)
        
        // Setup status bar item
        setupStatusBar()
        
        // Request accessibility permissions
        requestAccessibilityPermissions()
        
        // Start window monitoring
        WindowManager.shared.startMonitoring()
        
        // Show initial popover after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showPopover()
        }
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "rectangle.stack", accessibilityDescription: "MacSwitcher")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create menu for right-click
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Settings", action: #selector(showSettings), keyEquivalent: "s"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Enable/Disable", action: #selector(toggleEnabled), keyEquivalent: "e"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: ContentView()
            .environmentObject(WindowManager.shared)
            .environmentObject(LicenseManager.shared))
    }
    
    @objc func togglePopover() {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                showPopover()
            }
        }
    }
    
    func showPopover() {
        if let button = statusItem?.button {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            popover?.contentViewController?.view.window?.makeKey()
        }
    }
    
    @objc func showSettings() {
        // Show the main app window
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Create and show the main window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "MacSwitcher Settings"
        window.center()
        
        let contentView = ContentView()
            .environmentObject(WindowManager.shared)
            .environmentObject(LicenseManager.shared)
        
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        
        // Switch back to accessory mode after window is closed
        window.delegate = self
    }
    
    @objc func toggleEnabled() {
        isEnabled.toggle()
        updateStatusBarIcon()
        
        if isEnabled {
            WindowManager.shared.startMonitoring()
        } else {
            WindowManager.shared.stopMonitoring()
        }
    }
    
    func updateStatusBarIcon() {
        if let button = statusItem?.button {
            if isEnabled {
                button.image = NSImage(systemSymbolName: "rectangle.stack", accessibilityDescription: "MacSwitcher")
            } else {
                button.image = NSImage(systemSymbolName: "rectangle.stack.slash", accessibilityDescription: "MacSwitcher (Disabled)")
            }
        }
    }
    
    func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !trusted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permission Required"
                alert.informativeText = "MacSwitcher needs accessibility permissions to switch between windows. Please grant permission in System Preferences > Security & Privacy > Privacy > Accessibility."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Open System Preferences")
                alert.addButton(withTitle: "Later")
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        WindowManager.shared.stopMonitoring()
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        // Switch back to accessory mode when the settings window is closed
        NSApp.setActivationPolicy(.accessory)
    }
}
