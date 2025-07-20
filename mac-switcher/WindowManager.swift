import Foundation
import AppKit
import Carbon
import SwiftUI

class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    @Published var windows: [WindowInfo] = []
    @Published var isSwitcherVisible = false
    @Published var selectedIndex = 0
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var hotkeyMonitor: Any?
    
    struct WindowInfo: Identifiable, Hashable {
        let id = UUID()
        let windowID: CGWindowID
        let appName: String
        let windowTitle: String
        let appIcon: NSImage?
        let isActive: Bool
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(windowID)
        }
        
        static func == (lhs: WindowInfo, rhs: WindowInfo) -> Bool {
            return lhs.windowID == rhs.windowID
        }
    }
    
    init() {
        setupHotkeyMonitor()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        setupEventTap()
        refreshWindows()
    }
    
    func stopMonitoring() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
        }
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
    }
    
    private func setupEventTap() {
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                let windowManager = Unmanaged<WindowManager>.fromOpaque(refcon!).takeUnretainedValue()
                return windowManager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap")
            return
        }
        
        self.eventTap = eventTap
        
        guard let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0) else {
            print("Failed to create run loop source")
            return
        }
        
        self.runLoopSource = runLoopSource
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags
            
            // Check for Option+Tab (Alt+Tab on Mac)
            if keyCode == kVK_Tab && flags.contains(.maskAlternate) {
                showSwitcher()
                return nil // Consume the event
            }
            
            // Handle arrow keys and enter when switcher is visible
            if isSwitcherVisible {
                switch keyCode {
                case Int64(kVK_LeftArrow):
                    selectPreviousWindow()
                    return nil
                case Int64(kVK_RightArrow):
                    selectNextWindow()
                    return nil
                case Int64(kVK_Return):
                    selectCurrentWindow()
                    return nil
                case Int64(kVK_Escape):
                    hideSwitcher()
                    return nil
                default:
                    break
                }
            }
        } else if type == .flagsChanged {
            let flags = event.flags
            
            // Hide switcher when Option is released
            if !flags.contains(.maskAlternate) && isSwitcherVisible {
                hideSwitcher()
            }
        }
        
        return Unmanaged.passRetained(event)
    }
    
    private func setupHotkeyMonitor() {
        // Alternative hotkey monitoring using NSEvent
        NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == 48 && event.modifierFlags.contains(.option) { // Tab key with Option
                self?.showSwitcher()
            }
        }
    }
    
    func refreshWindows() {
        let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
        let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []
        
        var newWindows: [WindowInfo] = []
        let activeApp = NSWorkspace.shared.frontmostApplication
        
        for windowDict in windowList {
            guard let windowID = windowDict[kCGWindowNumber as String] as? CGWindowID,
                  let ownerName = windowDict[kCGWindowOwnerName as String] as? String,
                  let windowTitle = windowDict[kCGWindowName as String] as? String,
                  let windowLayer = windowDict[kCGWindowLayer as String] as? Int else {
                continue
            }
            
            // Skip system windows and windows with no title
            if windowLayer != 0 || windowTitle.isEmpty || ownerName == "Dock" || ownerName == "Finder" {
                continue
            }
            
            // Get app icon
            let appIcon = getAppIcon(for: ownerName)
            
            let windowInfo = WindowInfo(
                windowID: windowID,
                appName: ownerName,
                windowTitle: windowTitle,
                appIcon: appIcon,
                isActive: activeApp?.bundleIdentifier == getBundleIdentifier(for: ownerName)
            )
            
            newWindows.append(windowInfo)
        }
        
        // Sort windows: active app first, then by app name, then by window title
        newWindows.sort { first, second in
            if first.isActive != second.isActive {
                return first.isActive
            }
            if first.appName != second.appName {
                return first.appName < second.appName
            }
            return first.windowTitle < second.windowTitle
        }
        
        DispatchQueue.main.async {
            self.windows = newWindows
            if self.selectedIndex >= newWindows.count {
                self.selectedIndex = 0
            }
        }
    }
    
    private func getAppIcon(for appName: String) -> NSImage? {
        guard let bundleId = getBundleIdentifier(for: appName),
              let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            return nil
        }
        
        let icon = NSWorkspace.shared.icon(forFile: app.path)
        return icon
    }
    
    private func getBundleIdentifier(for appName: String) -> String? {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.first { $0.localizedName == appName }?.bundleIdentifier
    }
    
    func showSwitcher() {
        refreshWindows()
        DispatchQueue.main.async {
            self.isSwitcherVisible = true
            self.selectedIndex = 0
        }
    }
    
    func hideSwitcher() {
        DispatchQueue.main.async {
            self.isSwitcherVisible = false
        }
    }
    
    func selectNextWindow() {
        if !windows.isEmpty {
            selectedIndex = (selectedIndex + 1) % windows.count
        }
    }
    
    func selectPreviousWindow() {
        if !windows.isEmpty {
            selectedIndex = selectedIndex == 0 ? windows.count - 1 : selectedIndex - 1
        }
    }
    
    func selectCurrentWindow() {
        guard selectedIndex < windows.count else { return }
        
        let windowInfo = windows[selectedIndex]
        
        // Activate the window
        if let window = getWindowByID(windowInfo.windowID) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        
        hideSwitcher()
    }
    
    private func getWindowByID(_ windowID: CGWindowID) -> NSWindow? {
        for window in NSApplication.shared.windows {
            if window.windowNumber == windowID {
                return window
            }
        }
        return nil
    }
} 