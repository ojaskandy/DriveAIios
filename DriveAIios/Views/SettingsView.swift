//
//  SettingsView.swift
//  CruiseAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import SwiftUI
import CoreLocation
import AVFoundation

struct SettingsView: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject var cameraService: CameraService
    @StateObject private var userPreferences = UserPreferencesService.shared
    
    @State private var showingColorPicker = false
    @State private var customColor = Color.blue
    @State private var hexColor: String = "#0000FF"
    @State private var showDebugInfo = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Appearance")) {
                    Toggle(isOn: $userPreferences.isDarkMode) {
                        Label("Dark Mode", systemImage: "moon.fill")
                    }
                    .onChange(of: userPreferences.isDarkMode) { newValue in
                        userPreferences.setDarkMode(newValue)
                    }
                    
                    Button(action: {
                        showingColorPicker = true
                    }) {
                        HStack {
                            Label("Theme Color", systemImage: "paintpalette.fill")
                            Spacer()
                            if let colorHex = userPreferences.themeColor {
                                Circle()
                                    .fill(Color(hex: colorHex) ?? .black)
                                    .frame(width: 24, height: 24)
                            } else {
                                Text("Default (Black)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .sheet(isPresented: $showingColorPicker) {
                        ColorPickerView(
                            selectedColor: $customColor,
                            hexColor: $hexColor,
                            onSave: { color, hex in
                                userPreferences.setThemeColor(hex)
                                showingColorPicker = false
                            },
                            onCancel: {
                                showingColorPicker = false
                            }
                        )
                    }
                    
                    Text("Theme colors create a gradient from top to bottom of the screen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                Section(header: Text("Safety Features")) {
                    Toggle(isOn: $userPreferences.isDashcamEnabled) {
                        Label("Dashcam", systemImage: "video.fill")
                    }
                    .onChange(of: userPreferences.isDashcamEnabled) { newValue in
                        userPreferences.setDashcamEnabled(newValue)
                    }
                    
                    Toggle(isOn: $userPreferences.isCrashDetectionEnabled) {
                        Label("Crash Detection", systemImage: "exclamationmark.triangle.fill")
                    }
                    .onChange(of: userPreferences.isCrashDetectionEnabled) { newValue in
                        userPreferences.setCrashDetectionEnabled(newValue)
                    }
                    
                    Toggle(isOn: $userPreferences.isSafetyModeEnabled) {
                        Label("Safety Mode", systemImage: "shield.fill")
                    }
                    .onChange(of: userPreferences.isSafetyModeEnabled) { newValue in
                        userPreferences.setSafetyModeEnabled(newValue)
                    }
                    
                    Toggle(isOn: $userPreferences.isAudioAidsEnabled) {
                        Label("Audio Aids", systemImage: "speaker.wave.2.fill")
                    }
                    .onChange(of: userPreferences.isAudioAidsEnabled) { newValue in
                        userPreferences.setAudioAidsEnabled(newValue)
                    }
                }
                
                Section(header: Text("Permissions")) {
                    HStack {
                        Label("Location", systemImage: "location.fill")
                        Spacer()
                        Text(locationAuthorizationStatus)
                            .foregroundColor(locationAuthorizationColor)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        locationService.requestLocationPermission()
                    }
                    
                    HStack {
                        Label("Camera", systemImage: "camera.fill")
                        Spacer()
                        Text(cameraAuthorizationStatus)
                            .foregroundColor(cameraAuthorizationColor)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        AVCaptureDevice.requestAccess(for: .video) { _ in }
                    }
                }
                
                Section(header: Text("About")) {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    
                    NavigationLink(destination: ContactSupportView()) {
                        Label("Contact Support", systemImage: "questionmark.circle.fill")
                    }
                    
                    HStack {
                        Label("Version", systemImage: "info.circle.fill")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        showDebugInfo.toggle()
                    }) {
                        Label("Debug Info", systemImage: "ladybug.fill")
                    }
                }
                
                if showDebugInfo {
                    Section(header: Text("Debug Information")) {
                        Text("Theme Color: \(userPreferences.themeColor ?? "None")")
                        Text("Dark Mode: \(userPreferences.isDarkMode ? "On" : "Off")")
                        Text("Audio Aids: \(userPreferences.isAudioAidsEnabled ? "On" : "Off")")
                        
                        Button(action: {
                            // Reset user preferences to defaults
                            userPreferences.resetFirstLaunchState()
                        }) {
                            Text("Reset All Settings")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .listStyle(InsetGroupedListStyle())
            .withHelpButton()
        }
    }
    
    private var locationAuthorizationStatus: String {
        switch CLLocationManager().authorizationStatus {
        case .authorizedAlways:
            return "Always"
        case .authorizedWhenInUse:
            return "While Using"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .notDetermined:
            return "Not Determined"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var locationAuthorizationColor: Color {
        switch CLLocationManager().authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return .green
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
    
    private var cameraAuthorizationStatus: String {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .notDetermined:
            return "Not Determined"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var cameraAuthorizationColor: Color {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .green
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("CruiseAI is committed to protecting your privacy. This policy explains how we collect, use, and safeguard your data.")
                
                Group {
                    privacySection(
                        title: "Location Data",
                        content: "We collect location data to provide real-time navigation and tracking features. This data is only used when the app is active and tracking is enabled."
                    )
                    
                    privacySection(
                        title: "Camera Usage",
                        content: "Camera access is used for real-time hazard detection. Video processing is done on-device and is not stored or transmitted unless explicitly saved."
                    )
                    
                    privacySection(
                        title: "Data Storage",
                        content: "Trip data and analytics are stored locally on your device. You can delete this data at any time through the app settings."
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .withHelpButton()
    }
    
    private func privacySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .foregroundColor(.secondary)
        }
    }
}

struct HelpView: View {
    var body: some View {
        List {
            Section(header: Text("Getting Started")) {
                NavigationLink("How to Use CruiseAI") {
                    helpContent(
                        title: "How to Use CruiseAI",
                        content: "1. Enable location and camera permissions\n2. Start a new trip by tapping the record button\n3. Mount your device securely on your dashboard\n4. CruiseAI will monitor your driving and provide alerts"
                    )
                }
                
                NavigationLink("Safety Features") {
                    helpContent(
                        title: "Safety Features",
                        content: "• Real-time hazard detection\n• Speed monitoring\n• Traffic light detection\n• Distance maintenance alerts\n• Traffic rule violation prevention"
                    )
                }
            }
            
            Section(header: Text("Troubleshooting")) {
                NavigationLink("Common Issues") {
                    helpContent(
                        title: "Common Issues",
                        content: "• Check if location services are enabled\n• Ensure camera permissions are granted\n• Verify internet connection for map features\n• Restart the app if tracking is inconsistent"
                    )
                }
                
                NavigationLink("Contact Support") {
                    helpContent(
                        title: "Contact Support",
                        content: "Email: ojaskandy@gmail.com\n\nPlease contact us for any questions, feedback, or support issues."
                    )
                }
            }
        }
        .navigationTitle("Help & Support")
    }
    
    private func helpContent(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(content)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
