//
//  HomeView.swift
//  CruiseAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import SwiftUI
import MapKit
import MessageUI

struct HomeView: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject var cameraService: CameraService
    @ObservedObject var tripDataService: TripDataService
    @StateObject private var userPreferences = UserPreferencesService.shared
    @Binding var selectedTab: Int
    
    @State private var showComingSoon = false
    @State private var showHowItWorks = false
    @State private var showEmailCollection = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                headerSection
                
                // Quick Actions
                quickActionsSection
                
                // Stats Summary
                if !tripDataService.trips.isEmpty {
                    StatsSummaryView(tripDataService: tripDataService)
                        .transition(.opacity)
                }
                
                // Recent Activity
                recentActivitySection
                
                // Features
                featuresSection
            }
            .padding(.horizontal)
        }
        .background(backgroundGradient)
        .sheet(isPresented: $showEmailCollection) {
            EmailCollectionView(isShowingEmailCollection: $showEmailCollection)
        }
        .onAppear {
            setupInitialState()
        }
    }
    
    private var backgroundGradient: some View {
        let themeColor = Color(hex: userPreferences.themeColor ?? "#000000") ?? .black
        
        return LinearGradient(
            gradient: Gradient(colors: [
                themeColor,
                themeColor.opacity(0.8),
                themeColor.opacity(0.5),
                themeColor.opacity(0.2),
                Color(.systemBackground)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(spacing: 15) {
            Image("CruiseAILogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
            
            VStack(spacing: 8) {
                Text("Welcome to CruiseAI")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Your Intelligent Driving Assistant")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 20)
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 15) {
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                QuickActionButton(
                    title: "Start Drive",
                    icon: "car.circle.fill",
                    color: .green
                ) {
                    // Navigate to Monitor tab (index 1)
                    withAnimation {
                        selectedTab = 1
                    }
                }
                
                QuickActionButton(
                    title: "Settings",
                    icon: "gear",
                    color: .orange
                ) {
                    // Navigate to Settings tab (index 4)
                    withAnimation {
                        selectedTab = 4
                    }
                }
                
                QuickActionButton(
                    title: "Maps",
                    icon: "map.fill",
                    color: .blue
                ) {
                    // Open Apple Maps
                    openMaps()
                }
                
                QuickActionButton(
                    title: "History",
                    icon: "clock.fill",
                    color: .purple
                ) {
                    // Navigate to History tab (index 3)
                    withAnimation {
                        selectedTab = 3
                    }
                }
            }
        }
        .padding(.vertical, 10)
    }
    
    private var recentActivitySection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Recent Activity")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    // Navigate to History tab (index 3)
                    withAnimation {
                        selectedTab = 3
                    }
                }) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            if tripDataService.trips.isEmpty {
                // Empty state view
                VStack(spacing: 15) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No trips yet")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Start your first drive to begin tracking your journeys")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Color(.systemBackground))
                .cornerRadius(15)
            } else {
                ForEach(tripDataService.trips.prefix(3)) { trip in
                    TripCard(trip: trip)
                }
            }
        }
    }
    
    private var featuresSection: some View {
        VStack(spacing: 15) {
            Text("Discover Features")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 15) {
                // Feature cards
                Button(action: {
                    showComingSoon = true
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 28))
                            .foregroundColor(.orange)
                        
                        Text("Coming Soon")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("See what's next")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.orange.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                }
                
                Button(action: {
                    showHowItWorks = true
                    userPreferences.markHowItWorksAsSeen()
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                        
                        Text("How It Works")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Learn the basics")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.blue.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                }
            }
        }
        .padding(.bottom, 30)
    }
    
    private func setupInitialState() {
        locationService.requestLocationPermission()
        
        if userPreferences.isFirstLaunch {
            if !userPreferences.hasProvidedEmail {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showEmailCollection = true
                }
            }
            
            if !userPreferences.hasSeenHowItWorks && !showEmailCollection {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showHowItWorks = true
                }
            }
        }
        
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ShowHowItWorks"),
            object: nil,
            queue: .main
        ) { _ in
            showHowItWorks = true
        }
    }
    
    private func openMaps() {
        if let url = URL(string: "maps://") {
            UIApplication.shared.open(url)
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemBackground))
                    .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
            )
        }
    }
}

struct TripCard: View {
    let trip: Trip
    
    var body: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "car.fill")
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.date, style: .date)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("\(String(format: "%.1f", trip.distance / 1609.34)) miles • \(String(format: "%.0f", trip.averageSpeed * 2.237)) mph avg")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    NavigationView {
        HomeView(
            locationService: LocationService(),
            cameraService: CameraService(),
            tripDataService: TripDataService(),
            selectedTab: .constant(0)
        )
    }
}
