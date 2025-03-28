//
//  MainTabView.swift
//  DriveAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var locationService = LocationService()
    @StateObject private var cameraService = CameraService()
    @StateObject private var tripDataService = TripDataService()
    
    var body: some View {
        TabView {
            LiveMonitoringView(
                locationService: locationService,
                cameraService: cameraService,
                tripDataService: tripDataService
            )
            .tabItem {
                Label("Monitor", systemImage: "video.fill")
            }
            
            TripHistoryView(tripDataService: tripDataService)
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
            
            AnalyticsView(tripDataService: tripDataService)
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
            
            SettingsView(
                locationService: locationService,
                cameraService: cameraService
            )
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .onAppear {
            locationService.requestLocationPermission()
        }
    }
}

#Preview {
    MainTabView()
}