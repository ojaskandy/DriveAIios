//
//  LiveMonitoringView.swift
//  DriveAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import SwiftUI
import AVFoundation
import MapKit

struct LiveMonitoringView: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject var cameraService: CameraService
    @ObservedObject var tripDataService: TripDataService
    
    @State private var isRecording = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3346, longitude: -122.0090),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                CameraPreviewView(session: cameraService.session)
                    .frame(height: UIScreen.main.bounds.height * 0.4)
                    .overlay(alignment: .topLeading) {
                        speedometer
                            .padding()
                    }
                
                Map(coordinateRegion: $region,
                    showsUserLocation: true,
                    userTrackingMode: .constant(.follow))
                    .frame(height: UIScreen.main.bounds.height * 0.4)
                
                controlPanel
            }
            
            if let error = locationService.locationError {
                errorBanner(error)
            }
            
            if let error = cameraService.error {
                errorBanner(error)
            }
        }
        .onChange(of: locationService.currentLocation) { newLocation in
            if let location = newLocation {
                region.center = location.coordinate
            }
        }
        .onAppear {
            locationService.requestLocationPermission()
            // Only initialize camera after location permission is granted
            if locationService.locationManager.authorizationStatus == .authorizedAlways {
                cameraService.initializeSession()
            }
        }
        .onChange(of: locationService.locationManager.authorizationStatus) { status in
            if status == .authorizedAlways {
                cameraService.initializeSession()
            }
        }
        .onDisappear {
            cameraService.stopSession()
            locationService.stopTracking()
        }
    }
    
    private var speedometer: some View {
        VStack(alignment: .leading) {
            Text(String(format: "%.1f mph", 
                       (locationService.currentLocation?.speed ?? 0) * 2.237))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            if isRecording {
                Text("Recording")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
    
    private var controlPanel: some View {
        HStack(spacing: 20) {
            Button(action: toggleRecording) {
                Image(systemName: isRecording ? "stop.circle.fill" : "record.circle")
                    .font(.system(size: 64))
                    .foregroundColor(isRecording ? .red : .green)
            }
        }
        .padding()
    }
    
    private func errorBanner(_ error: Error) -> some View {
        VStack {
            Text(error.localizedDescription)
                .foregroundColor(.white)
                .padding()
                .background(Color.red.opacity(0.8))
                .cornerRadius(8)
            Spacer()
        }
        .padding(.top)
    }
    
    private func toggleRecording() {
        isRecording.toggle()
        if isRecording {
            locationService.startTracking()
            cameraService.startSession()
            tripDataService.startNewTrip()
        } else {
            locationService.stopTracking()
            cameraService.stopSession()
            let summary = locationService.getTripSummary()
            tripDataService.endCurrentTrip()
        }
    }
}