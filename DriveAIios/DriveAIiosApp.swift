//
//  CruiseAIiosApp.swift
//  CruiseAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import SwiftUI

@main
struct CruiseAIiosApp: App {
    @State private var isShowingSplash = true
    @StateObject private var userPreferences = UserPreferencesService.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Apply custom background color if set
                if let colorHex = userPreferences.customBackgroundColor,
                   let backgroundColor = Color(hex: colorHex) {
                    backgroundColor
                        .ignoresSafeArea()
                        .opacity(0.15) // Subtle background
                }
                
                // Main app content
                MainTabView()
                    .opacity(isShowingSplash ? 0 : 1)
                    .preferredColorScheme(userPreferences.isDarkMode ? .dark : .light)
                
                // Splash screen overlay
                if isShowingSplash {
                    SplashScreenView(isShowingSplash: $isShowingSplash)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: isShowingSplash)
        }
    }
}
