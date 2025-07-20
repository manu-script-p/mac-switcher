import SwiftUI
import AppKit

struct WindowSwitcher: View {
    @EnvironmentObject var windowManager: WindowManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if windowManager.isSwitcherVisible {
            ZStack {
                // Background overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        windowManager.hideSwitcher()
                    }
                
                // Window switcher content
                VStack(spacing: 20) {
                    Text("Window Switcher")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if windowManager.windows.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "rectangle.stack")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            Text("No windows available")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Open some applications to switch between windows")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 3), spacing: 15) {
                                ForEach(Array(windowManager.windows.enumerated()), id: \.element.id) { index, window in
                                    WindowCard(
                                        window: window,
                                        isSelected: index == windowManager.selectedIndex
                                    )
                                    .onTapGesture {
                                        windowManager.selectedIndex = index
                                        windowManager.selectCurrentWindow()
                                    }
                                }
                            }
                            .padding()
                        }
                        .frame(maxHeight: 300)
                    }
                    
                    // Instructions
                    VStack(spacing: 5) {
                        Text("Use arrow keys to navigate, Enter to select, Esc to cancel")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Press ⌘+Tab to show/hide")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(colorScheme == .dark ? Color(.windowBackgroundColor) : Color(.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                )
                .frame(maxWidth: 600)
                .padding()
            }
            .transition(.opacity.combined(with: .scale))
            .animation(.easeInOut(duration: 0.2), value: windowManager.isSwitcherVisible)
        }
    }
}

struct WindowCard: View {
    let window: WindowManager.WindowInfo
    let isSelected: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            // App icon
            if let appIcon = window.appIcon {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "app")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
            }
            
            // Window title
            Text(window.windowTitle)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            // App name
            Text(window.appName)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(width: 120, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? 
                      (colorScheme == .dark ? Color.blue.opacity(0.3) : Color.blue.opacity(0.1)) :
                      (colorScheme == .dark ? Color(.controlBackgroundColor) : Color(.windowBackgroundColor)))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }
}

struct WindowSwitcher_Previews: PreviewProvider {
    static var previews: some View {
        WindowSwitcher()
            .environmentObject(WindowManager())
    }
} 