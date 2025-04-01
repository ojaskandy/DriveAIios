//
//  StartDrivePopupView.swift
//  CruiseAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import SwiftUI

struct StartDrivePopupView: View {
    @Binding var isShowingPopup: Bool
    var onStartDrive: () -> Void
    
    @State private var isAnimating = false
    @StateObject private var userPreferences = UserPreferencesService.shared
    @State private var showFirstTimeSetup = false
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isShowingPopup = false
                    }
                }
            
            // Popup card
            VStack(spacing: 25) {
                // Header
                Text("Ready to Drive?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                // Car icon
                ZStack {
                    // Glowing effect
                    Circle()
                        .fill(Color.green)
                        .frame(width: 120, height: 120)
                        .opacity(isAnimating ? 0.3 : 0.6)
                        .blur(radius: 15)
                    
                    Image(systemName: "car.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                }
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                }
                
                // Safety Mode Toggle
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "ear.and.waveform")
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        Text("Improve Driving Safety")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Text("Enable soothing sounds to help condition your response to stop signs, traffic lights, and pedestrians. Also warns you when approaching objects too quickly.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Toggle("Enable Safety Features", isOn: $userPreferences.isSafetyModeEnabled)
                        .padding(.top, 5)
                        .tint(.green)
                    
                    if userPreferences.isSafetyModeEnabled {
                        Text("Helps drivers who have previously been in accidents by providing extra awareness of surroundings")
                            .font(.caption)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                            .padding(.top, 2)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(15)
                .animation(.easeInOut, value: userPreferences.isSafetyModeEnabled)
                
                // DND reminder
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "bell.slash.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        
                        Text("Important")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Text("Please disable Do Not Disturb (DND) mode to allow for sound immersion and conditioning.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(15)
                
                // Start Drive button
                Button(action: {
                    // Save safety mode preference
                    userPreferences.setSafetyModeEnabled(userPreferences.isSafetyModeEnabled)
                    
                    // Check if first time setup needs to be shown
                    if userPreferences.isFirstLaunch && !userPreferences.hasSeenFirstTimeSetup {
                        showFirstTimeSetup = true
                    } else {
                        withAnimation {
                            isShowingPopup = false
                            onStartDrive()
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Drive")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .shadow(color: Color.green.opacity(0.5), radius: 10, x: 0, y: 5)
                }
                
                // Cancel button
                Button(action: {
                    withAnimation {
                        isShowingPopup = false
                    }
                }) {
                    Text("Cancel")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 5)
            }
            .padding(30)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(.horizontal, 30)
            .transition(.scale.combined(with: .opacity))
        }
        .fullScreenCover(isPresented: $showFirstTimeSetup) {
            FirstTimeSetupView(isShowingSetup: $showFirstTimeSetup)
                .onDisappear {
                    // When first time setup is dismissed, start the drive
                    isShowingPopup = false
                    onStartDrive()
                }
        }
    }
}

struct StartDrivePopupView_Previews: PreviewProvider {
    static var previews: some View {
        StartDrivePopupView(isShowingPopup: .constant(true), onStartDrive: {})
    }
}
