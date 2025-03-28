//
//  SettingsView.swift
//  DriveAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import SwiftUI
import CoreLocation
import AVFoundation

struct SettingsView: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject var cameraService: CameraService
    
    var body: some View {
        NavigationView {
            List {
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
                    
                    NavigationLink(destination: HelpView()) {
                        Label("Help & Support", systemImage: "questionmark.circle.fill")
                    }
                    
                    HStack {
                        Label("Version", systemImage: "info.circle.fill")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .listStyle(InsetGroupedListStyle())
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
                
                Text("DriveAI is committed to protecting your privacy. This policy explains how we collect, use, and safeguard your data.")
                
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
                NavigationLink("How to Use DriveAI") {
                    helpContent(
                        title: "How to Use DriveAI",
                        content: "1. Enable location and camera permissions\n2. Start a new trip by tapping the record button\n3. Mount your device securely on your dashboard\n4. DriveAI will monitor your driving and provide alerts"
                    )
                }
                
                NavigationLink("Safety Features") {
                    helpContent(
                        title: "Safety Features",
                        content: "• Real-time hazard detection\n• Speed monitoring\n• Lane departure warnings\n• Distance maintenance alerts\n• Traffic rule violation prevention"
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
                        content: "Email: support@driveai.com\nPhone: 1-800-DRIVEAI\n\nOur support team is available Monday through Friday, 9 AM to 5 PM EST."
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