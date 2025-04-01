//
//  UserPreferencesService.swift
//  DriveAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import Foundation
import Combine

class UserPreferencesService: ObservableObject {
    // Published properties
    @Published var isFirstLaunch: Bool
    @Published var hasSeenHowItWorks: Bool
    @Published var hasProvidedEmail: Bool
    @Published var hasSeenFirstTimeSetup: Bool
    @Published var isSafetyModeEnabled: Bool
    @Published var email: String?
    @Published var phoneNumber: String?
    @Published var isDarkMode: Bool
    @Published var customBackgroundColor: String?
    @Published var isDashcamEnabled: Bool
    @Published var isCrashDetectionEnabled: Bool
    
    // UserDefaults keys
    private enum Keys {
        static let isFirstLaunch = "isFirstLaunch"
        static let hasSeenHowItWorks = "hasSeenHowItWorks"
        static let hasProvidedEmail = "hasProvidedEmail"
        static let hasSeenFirstTimeSetup = "hasSeenFirstTimeSetup"
        static let isSafetyModeEnabled = "isSafetyModeEnabled"
        static let email = "userEmail"
        static let phoneNumber = "userPhoneNumber"
        static let isDarkMode = "isDarkMode"
        static let customBackgroundColor = "customBackgroundColor"
        static let isDashcamEnabled = "isDashcamEnabled"
        static let isCrashDetectionEnabled = "isCrashDetectionEnabled"
    }
    
    // Singleton instance
    static let shared = UserPreferencesService()
    
    private init() {
        // Load values from UserDefaults
        let defaults = UserDefaults.standard
        
        // Check if this is the first launch
        if defaults.object(forKey: Keys.isFirstLaunch) == nil {
            // First time launching the app
            isFirstLaunch = true
            defaults.set(false, forKey: Keys.isFirstLaunch)
        } else {
            isFirstLaunch = false
        }
        
        // Load other preferences
        hasSeenHowItWorks = defaults.bool(forKey: Keys.hasSeenHowItWorks)
        hasProvidedEmail = defaults.bool(forKey: Keys.hasProvidedEmail)
        hasSeenFirstTimeSetup = defaults.bool(forKey: Keys.hasSeenFirstTimeSetup)
        
        // Default safety mode to enabled
        isSafetyModeEnabled = defaults.object(forKey: Keys.isSafetyModeEnabled) == nil ? 
            true : defaults.bool(forKey: Keys.isSafetyModeEnabled)
            
        // User contact information
        email = defaults.string(forKey: Keys.email)
        phoneNumber = defaults.string(forKey: Keys.phoneNumber)
        
        // Appearance preferences
        // Default to system appearance (nil means follow system)
        isDarkMode = defaults.object(forKey: Keys.isDarkMode) == nil ?
            true : defaults.bool(forKey: Keys.isDarkMode)
        customBackgroundColor = defaults.string(forKey: Keys.customBackgroundColor)
        
        // Safety features
        // Default dashcam to enabled
        isDashcamEnabled = defaults.object(forKey: Keys.isDashcamEnabled) == nil ?
            true : defaults.bool(forKey: Keys.isDashcamEnabled)
        // Default crash detection to enabled
        isCrashDetectionEnabled = defaults.object(forKey: Keys.isCrashDetectionEnabled) == nil ?
            true : defaults.bool(forKey: Keys.isCrashDetectionEnabled)
    }
    
    // MARK: - Public Methods
    
    func markHowItWorksAsSeen() {
        hasSeenHowItWorks = true
        UserDefaults.standard.set(true, forKey: Keys.hasSeenHowItWorks)
    }
    
    func saveUserEmail(_ email: String, phoneNumber: String? = nil) {
        self.email = email
        self.phoneNumber = phoneNumber
        self.hasProvidedEmail = true
        
        let defaults = UserDefaults.standard
        defaults.set(email, forKey: Keys.email)
        defaults.set(phoneNumber, forKey: Keys.phoneNumber)
        defaults.set(true, forKey: Keys.hasProvidedEmail)
    }
    
    func markFirstTimeSetupAsSeen() {
        hasSeenFirstTimeSetup = true
        UserDefaults.standard.set(true, forKey: Keys.hasSeenFirstTimeSetup)
    }
    
    func setSafetyModeEnabled(_ enabled: Bool) {
        isSafetyModeEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Keys.isSafetyModeEnabled)
    }
    
    // MARK: - Appearance Methods
    
    func setDarkMode(_ enabled: Bool) {
        isDarkMode = enabled
        UserDefaults.standard.set(enabled, forKey: Keys.isDarkMode)
    }
    
    func setCustomBackgroundColor(_ hexColor: String?) {
        customBackgroundColor = hexColor
        UserDefaults.standard.set(hexColor, forKey: Keys.customBackgroundColor)
    }
    
    // MARK: - Safety Feature Methods
    
    func setDashcamEnabled(_ enabled: Bool) {
        isDashcamEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Keys.isDashcamEnabled)
    }
    
    func setCrashDetectionEnabled(_ enabled: Bool) {
        isCrashDetectionEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Keys.isCrashDetectionEnabled)
    }
    
    func resetFirstLaunchState() {
        // For testing purposes - reset the first launch state
        isFirstLaunch = true
        hasSeenHowItWorks = false
        hasProvidedEmail = false
        hasSeenFirstTimeSetup = false
        isSafetyModeEnabled = true
        isDarkMode = true
        customBackgroundColor = nil
        isDashcamEnabled = true
        isCrashDetectionEnabled = true
        
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: Keys.isFirstLaunch)
        defaults.set(false, forKey: Keys.hasSeenHowItWorks)
        defaults.set(false, forKey: Keys.hasProvidedEmail)
        defaults.set(false, forKey: Keys.hasSeenFirstTimeSetup)
        defaults.set(true, forKey: Keys.isSafetyModeEnabled)
        defaults.set(true, forKey: Keys.isDarkMode)
        defaults.removeObject(forKey: Keys.customBackgroundColor)
        defaults.set(true, forKey: Keys.isDashcamEnabled)
        defaults.set(true, forKey: Keys.isCrashDetectionEnabled)
    }
}
