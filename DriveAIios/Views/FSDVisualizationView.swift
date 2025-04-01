//
//  FSDVisualizationView.swift
//  DriveAIios
//
//  Created by Ojas Kandhare on 3/31/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct FSDVisualizationView: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject var cameraService: CameraService
    
    // Map state
    @State private var region: MKCoordinateRegion
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var mapType: MKMapType = .standard
    
    // Traffic elements
    @State private var trafficElements: [TrafficElement] = []
    
    init(locationService: LocationService, cameraService: CameraService) {
        self.locationService = locationService
        self.cameraService = cameraService
        
        // Initialize with default region (will be updated with user location)
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        ZStack {
            // Map view
            Group {
                if #available(iOS 17.0, *) {
                    Map(coordinateRegion: $region, 
                        showsUserLocation: true,
                        userTrackingMode: $userTrackingMode,
                        annotationItems: trafficElements) { element in
                        MapAnnotation(coordinate: element.coordinate) {
                            TrafficElementMarker(type: element.type)
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic, emphasis: .muted))
                } else {
                    // Fallback for iOS versions earlier than 17.0
                    Map(coordinateRegion: $region, 
                        showsUserLocation: true,
                        userTrackingMode: $userTrackingMode,
                        annotationItems: trafficElements) { element in
                        MapAnnotation(coordinate: element.coordinate) {
                            TrafficElementMarker(type: element.type)
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            
            // Controls overlay
            VStack {
                // Top bar with title and map type toggle
                HStack {
                    Text("Traffic Map")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Map type toggle
                    Button(action: toggleMapType) {
                        Image(systemName: mapType == .standard ? "map" : "map.fill")
                            .padding(8)
                            .background(Color(.systemBackground).opacity(0.8))
                            .clipShape(Circle())
                    }
                }
                .padding()
                .background(Color(.systemBackground).opacity(0.8))
                .cornerRadius(10)
                .padding(.top)
                .padding(.horizontal)
                
                Spacer()
                
                // Bottom controls
                HStack {
                    // Recenter button
                    Button(action: centerOnUserLocation) {
                        Image(systemName: "location.fill")
                            .padding(12)
                            .background(Color(.systemBackground).opacity(0.8))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Zoom controls
                    VStack(spacing: 8) {
                        Button(action: zoomIn) {
                            Image(systemName: "plus")
                                .padding(12)
                                .background(Color(.systemBackground).opacity(0.8))
                                .clipShape(Circle())
                        }
                        
                        Button(action: zoomOut) {
                            Image(systemName: "minus")
                                .padding(12)
                                .background(Color(.systemBackground).opacity(0.8))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding()
                .padding(.horizontal)
            }
        }
        .onAppear {
            // Request location permissions
            locationService.requestLocationPermission()
            
            // Center map on user's location when available
            if let location = locationService.currentLocation?.coordinate {
                centerMapOn(location)
            }
            
            // Generate simulated traffic elements
            generateSimulatedTrafficElements()
        }
        .onChange(of: locationService.currentLocation) { newLocation in
            if let location = newLocation?.coordinate, userTrackingMode == .follow {
                centerMapOn(location)
            }
        }
    }
    
    // MARK: - Map Control Functions
    
    private func centerOnUserLocation() {
        if let location = locationService.currentLocation?.coordinate {
            centerMapOn(location)
            userTrackingMode = .follow
        }
    }
    
    private func centerMapOn(_ coordinate: CLLocationCoordinate2D) {
        withAnimation {
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        }
    }
    
    private func zoomIn() {
        withAnimation {
            region.span.latitudeDelta = max(region.span.latitudeDelta / 2, 0.001)
            region.span.longitudeDelta = max(region.span.longitudeDelta / 2, 0.001)
        }
    }
    
    private func zoomOut() {
        withAnimation {
            region.span.latitudeDelta = min(region.span.latitudeDelta * 2, 0.2)
            region.span.longitudeDelta = min(region.span.longitudeDelta * 2, 0.2)
        }
    }
    
    private func toggleMapType() {
        mapType = mapType == .standard ? .hybrid : .standard
    }
    
    // MARK: - Traffic Element Generation
    
    private func generateSimulatedTrafficElements() {
        // Clear existing elements
        trafficElements.removeAll()
        
        // Only generate if we have a user location
        guard let userLocation = locationService.currentLocation?.coordinate else { return }
        
        // Generate traffic lights and stop signs in a grid around the user
        let gridSize = 5
        let spacing = 0.001 // Approximately 100 meters
        
        for i in -gridSize...gridSize {
            for j in -gridSize...gridSize {
                // Skip the center point (user's location)
                if i == 0 && j == 0 { continue }
                
                // Calculate position
                let latitude = userLocation.latitude + Double(i) * spacing
                let longitude = userLocation.longitude + Double(j) * spacing
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                
                // Determine element type - alternate between traffic lights and stop signs
                let type: TrafficElementType = (abs(i) + abs(j)) % 2 == 0 ? .trafficLight : .stopSign
                
                // Add to array
                trafficElements.append(TrafficElement(coordinate: coordinate, type: type))
            }
        }
    }
}

// MARK: - Supporting Types

struct TrafficElement: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: TrafficElementType
}

enum TrafficElementType {
    case trafficLight
    case stopSign
}

struct TrafficElementMarker: View {
    let type: TrafficElementType
    
    var body: some View {
        ZStack {
            // Background circle for better visibility
            Circle()
                .fill(Color.white)
                .frame(width: 30, height: 30)
            
            // Icon based on type
            if type == .trafficLight {
                Image(systemName: "light.traffic")
                    .font(.system(size: 18))
                    .foregroundColor(.red)
            } else {
                Image(systemName: "octagon.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Preview

struct FSDVisualizationView_Previews: PreviewProvider {
    static var previews: some View {
        FSDVisualizationView(
            locationService: LocationService(),
            cameraService: CameraService()
        )
    }
}
