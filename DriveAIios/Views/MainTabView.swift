//
//  MainTabView.swift
//  CruiseAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import SwiftUI
import AVFoundation

struct MainTabView: View {
    @StateObject private var locationService = LocationService()
    @StateObject private var cameraService = CameraService()
    @StateObject private var tripDataService = TripDataService()
    @StateObject private var userPreferences = UserPreferencesService.shared
    @State private var selectedTab = 0
    
    // Get theme color from user preferences
    private var themeColor: Color {
        Color(hex: userPreferences.themeColor ?? "#000000") ?? .black
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(
                    locationService: locationService,
                    cameraService: cameraService,
                    tripDataService: tripDataService,
                    selectedTab: $selectedTab
                )
                .tag(0)
                
                LiveMonitoringView(
                    locationService: locationService,
                    cameraService: cameraService,
                    tripDataService: tripDataService,
                    selectedTab: $selectedTab
                )
                .tag(1)
                
                FSDVisualizationView(
                    locationService: locationService,
                    cameraService: cameraService
                )
                .tag(2)
                
                TripHistoryView(tripDataService: tripDataService)
                .tag(3)
                
                SettingsView(
                    locationService: locationService,
                    cameraService: cameraService
                )
                .tag(4)
            }
            .background(Color(.systemBackground)) // Add background color
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            // Initialize camera service first to ensure it's ready
            cameraService.checkAuthorizationAndSetup()
            
            // Then request location permissions
            locationService.requestLocationPermission()
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Namespace private var namespace
    @ObservedObject private var userPreferences = UserPreferencesService.shared
    
    private var themeColor: Color {
        Color(hex: userPreferences.themeColor ?? "#000000") ?? .black
    }
    
    private let tabs = [
        TabItem(icon: "house.fill", title: "Home", tag: 0),
        TabItem(icon: "video.fill", title: "Monitor", tag: 1),
        TabItem(icon: "map.fill", title: "Map", tag: 2),
        TabItem(icon: "clock.fill", title: "History", tag: 3),
        TabItem(icon: "gear", title: "Settings", tag: 4)
    ]
    
    var body: some View {
        HStack {
            ForEach(tabs, id: \.tag) { tab in
                Spacer()
                TabButton(
                    icon: tab.icon,
                    title: tab.title,
                    isSelected: selectedTab == tab.tag,
                    namespace: namespace
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab.tag
                    }
                }
                Spacer()
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            ZStack {
                Color(.systemBackground)
                    .opacity(0.95)
                
                // Add a subtle gradient of the theme color at the top
                LinearGradient(
                    gradient: Gradient(colors: [
                        themeColor.opacity(0.1),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: -4)
        )
    }
}

struct TabButton: View {
    @ObservedObject private var userPreferences = UserPreferencesService.shared
    let icon: String
    let title: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    private var themeColor: Color {
        Color(hex: userPreferences.themeColor ?? "#000000") ?? .black
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: isSelected ? 24 : 20))
                    .foregroundColor(isSelected ? themeColor : .gray)
                    .frame(height: 24)
                
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? themeColor : .gray)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeColor.opacity(0.1))
                            .matchedGeometryEffect(id: "TabBackground", in: namespace)
                    }
                }
            )
        }
    }
}

struct TabItem {
    let icon: String
    let title: String
    let tag: Int
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
