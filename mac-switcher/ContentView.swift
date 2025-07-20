//
//  ContentView.swift
//  mac-switcher
//
//  Created by Manu Prasad on 20/07/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var licenseManager: LicenseManager
    @State private var selectedTab = 0
    @State private var showPremiumFeatures = false
    
    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("MacSwitcher")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Switch between windows like Windows Alt+Tab")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Tab selection
                Picker("Tab", selection: $selectedTab) {
                    Text("Status").tag(0)
                    Text("Settings").tag(1)
                    Text("About").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Tab content
                TabView(selection: $selectedTab) {
                    StatusView()
                        .tag(0)
                    
                    SettingsView()
                        .tag(1)
                    
                    AboutView()
                        .tag(2)
                }
            }
            .frame(width: 300, height: 400)
            
            // Window Switcher Overlay
            WindowSwitcher()
        }
        .sheet(isPresented: $showPremiumFeatures) {
            PremiumFeaturesView()
                .environmentObject(licenseManager)
        }
        .onReceive(licenseManager.$showUpgradePrompt) { show in
            if show {
                showPremiumFeatures = true
            }
        }
    }
}

struct StatusView: View {
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var licenseManager: LicenseManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Status indicators
            VStack(spacing: 15) {
                StatusRow(
                    icon: "checkmark.circle.fill",
                    title: "Status",
                    subtitle: "Active",
                    color: .green
                )
                
                StatusRow(
                    icon: "keyboard",
                    title: "Hotkey",
                    subtitle: "⌥+Tab",
                    color: .blue
                )
                
                StatusRow(
                    icon: "rectangle.stack",
                    title: "Windows Found",
                    subtitle: "\(windowManager.windows.count)",
                    color: .orange
                )
                
                if licenseManager.isPremium {
                    StatusRow(
                        icon: "star.fill",
                        title: "License",
                        subtitle: "Premium",
                        color: .yellow
                    )
                } else if licenseManager.isTrialActive {
                    StatusRow(
                        icon: "clock",
                        title: "Trial",
                        subtitle: "\(licenseManager.trialDaysRemaining) days left",
                        color: .blue
                    )
                } else {
                    StatusRow(
                        icon: "exclamationmark.triangle",
                        title: "License",
                        subtitle: "Trial Expired",
                        color: .red
                    )
                }
            }
            
            // Quick actions
            VStack(spacing: 10) {
                Button("Refresh Windows") {
                    windowManager.refreshWindows()
                }
                .buttonStyle(.bordered)
                
                if !licenseManager.isPremium {
                    Button("Upgrade to Premium") {
                        // This will trigger the sheet
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
    }
}

struct SettingsView: View {
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var licenseManager: LicenseManager
    @AppStorage("autoRefresh") private var autoRefresh = true
    @AppStorage("showAppIcons") private var showAppIcons = true
    @AppStorage("animationSpeed") private var animationSpeed = 1.0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // General Settings
                SettingsSection(title: "General") {
                    Toggle("Auto-refresh windows", isOn: $autoRefresh)
                    Toggle("Show app icons", isOn: $showAppIcons)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Animation Speed")
                        Slider(value: $animationSpeed, in: 0.5...2.0, step: 0.1)
                        Text("\(String(format: "%.1f", animationSpeed))x")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Premium Features (if available)
                if licenseManager.canUsePremiumFeatures() {
                    SettingsSection(title: "Premium Features") {
                        Toggle("Advanced switching", isOn: .constant(true))
                            .disabled(!licenseManager.canUseAdvancedSwitching())
                        
                        Toggle("Custom hotkeys", isOn: .constant(false))
                            .disabled(!licenseManager.canUseCustomHotkeys())
                        
                        Toggle("Window history", isOn: .constant(false))
                            .disabled(!licenseManager.canUseWindowHistory())
                        
                        Toggle("Multiple displays", isOn: .constant(true))
                            .disabled(!licenseManager.canUseMultipleDisplays())
                    }
                }
                
                // License Information
                SettingsSection(title: "License") {
                    if licenseManager.isPremium {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Premium License")
                            Spacer()
                        }
                    } else if licenseManager.isTrialActive {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                            Text("Trial Period")
                            Spacer()
                            Text("\(licenseManager.trialDaysRemaining) days left")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                            Text("Trial Expired")
                            Spacer()
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct AboutView: View {
    @EnvironmentObject var licenseManager: LicenseManager
    
    var body: some View {
        VStack(spacing: 20) {
            // App info
            VStack(spacing: 10) {
                Image(systemName: "rectangle.stack")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("MacSwitcher")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("A Windows-style window switcher for macOS")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Features
            VStack(alignment: .leading, spacing: 10) {
                Text("Features")
                    .font(.headline)
                
                FeatureItem(icon: "arrow.left.arrow.right", text: "Switch between individual windows")
                FeatureItem(icon: "keyboard", text: "Global hotkey support (⌘+Tab)")
                FeatureItem(icon: "eye", text: "Visual window preview")
                FeatureItem(icon: "gear", text: "Customizable settings")
                
                if licenseManager.canUsePremiumFeatures() {
                    FeatureItem(icon: "star.fill", text: "Premium features enabled")
                }
            }
            
            // Links
            VStack(spacing: 10) {
                Button("Visit Website") {
                    NSWorkspace.shared.open(URL(string: "https://macswitcher.app")!)
                }
                .buttonStyle(.bordered)
                
                Button("Report Issue") {
                    NSWorkspace.shared.open(URL(string: "mailto:support@macswitcher.app")!)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

struct StatusRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
                .padding(.leading)
        }
    }
}

struct FeatureItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
            
            Spacer()
        }
    }
}

struct PremiumFeaturesView: View {
    @EnvironmentObject var licenseManager: LicenseManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 10) {
                Image(systemName: "star.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
                
                Text("Upgrade to Premium")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Unlock advanced features and remove limitations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Features list
            VStack(alignment: .leading, spacing: 15) {
                FeatureRow(icon: "arrow.left.arrow.right", title: "Advanced Window Switching", description: "Switch between windows with more precision")
                FeatureRow(icon: "keyboard", title: "Custom Hotkeys", description: "Set your own keyboard shortcuts")
                FeatureRow(icon: "clock", title: "Window History", description: "Remember your recent window order")
                FeatureRow(icon: "display", title: "Multiple Displays", description: "Switch windows across all displays")
                FeatureRow(icon: "gear", title: "Advanced Settings", description: "Fine-tune your switching experience")
            }
            
            // Trial info
            if licenseManager.isTrialActive {
                VStack(spacing: 5) {
                    Text("Trial Period")
                        .font(.headline)
                    
                    Text("\(licenseManager.trialDaysRemaining) days remaining")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            
            // Action buttons
            VStack(spacing: 10) {
                Button("Upgrade Now ($9.99)") {
                    licenseManager.purchasePremium()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("Restore Purchases") {
                    licenseManager.restorePurchases()
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Continue with Trial") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WindowManager())
        .environmentObject(LicenseManager())
}
