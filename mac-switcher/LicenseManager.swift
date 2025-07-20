import Foundation
import StoreKit
import SwiftUI

class LicenseManager: ObservableObject {
    static let shared = LicenseManager()
    
    @Published var isPremium = false
    @Published var isTrialActive = false
    @Published var trialDaysRemaining = 0
    @Published var showUpgradePrompt = false
    
    private let userDefaults = UserDefaults.standard
    private let trialKey = "trial_start_date"
    private let premiumKey = "is_premium"
    private let trialDuration: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    init() {
        loadLicenseStatus()
        checkTrialStatus()
    }
    
    // MARK: - License Management
    
    func loadLicenseStatus() {
        isPremium = userDefaults.bool(forKey: premiumKey)
        
        if let trialStartDate = userDefaults.object(forKey: trialKey) as? Date {
            let trialEndDate = trialStartDate.addingTimeInterval(trialDuration)
            isTrialActive = Date() < trialEndDate
            trialDaysRemaining = max(0, Int(trialEndDate.timeIntervalSince(Date()) / (24 * 60 * 60)))
        } else {
            // Start trial if not already started
            startTrial()
        }
    }
    
    func startTrial() {
        userDefaults.set(Date(), forKey: trialKey)
        isTrialActive = true
        trialDaysRemaining = 7
    }
    
    func checkTrialStatus() {
        guard let trialStartDate = userDefaults.object(forKey: trialKey) as? Date else {
            startTrial()
            return
        }
        
        let trialEndDate = trialStartDate.addingTimeInterval(trialDuration)
        isTrialActive = Date() < trialEndDate
        trialDaysRemaining = max(0, Int(trialEndDate.timeIntervalSince(Date()) / (24 * 60 * 60)))
        
        // Show upgrade prompt if trial expired
        if !isTrialActive && !isPremium {
            showUpgradePrompt = true
        }
    }
    
    // MARK: - Premium Features
    
    func canUsePremiumFeatures() -> Bool {
        // Dummy bypass for development - replace with actual license check
        #if DEBUG
        return true
        #else
        return isPremium || isTrialActive
        #endif
    }
    
    func unlockPremium() {
        isPremium = true
        userDefaults.set(true, forKey: premiumKey)
    }
    
    // MARK: - StoreKit Integration (Placeholder)
    
    func purchasePremium() {
        // TODO: Implement actual StoreKit purchase
        // For now, just unlock premium
        unlockPremium()
    }
    
    func restorePurchases() {
        // TODO: Implement StoreKit restore
        // For now, just unlock premium
        unlockPremium()
    }
    
    // MARK: - Feature Gating
    
    func canUseAdvancedSwitching() -> Bool {
        return canUsePremiumFeatures()
    }
    
    func canUseCustomHotkeys() -> Bool {
        return canUsePremiumFeatures()
    }
    
    func canUseWindowHistory() -> Bool {
        return canUsePremiumFeatures()
    }
    
    func canUseMultipleDisplays() -> Bool {
        return canUsePremiumFeatures()
    }
    
    // MARK: - Upgrade Prompts
    
    func showUpgradeIfNeeded() {
        if !isPremium && !isTrialActive {
            showUpgradePrompt = true
        }
    }
    
    func dismissUpgradePrompt() {
        showUpgradePrompt = false
    }
} 