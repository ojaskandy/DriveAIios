//
//  LiveMonitoringView.swift
//  CruiseAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import SwiftUI
import AVFoundation
import MapKit
import Combine
import MessageUI
import Vision

struct LiveMonitoringView: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject var cameraService: CameraService
    @ObservedObject var tripDataService: TripDataService
    @Binding var selectedTab: Int
    
    @State private var isRecording = false
    @State private var isAnimating = false
    // For haptic feedback rate limiting
    @State private var lastProcessingTime = Date()
    // Default to a reasonable location but will be updated with user's actual location
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    // Traffic light detection cancellable
    @State private var detectionCancellable: AnyCancellable?
    
    // Popup states
    @State private var showDNDReminder = false
    @State private var showStartDrivePopup = false
    @State private var showShareTripPopup = false
    @State private var lastTripSummary: TripSummary?
    
    var body: some View {
        ZStack {
            ZStack {
                // Full screen camera preview
                CameraPreviewView(session: cameraService.session)
                    .edgesIgnoringSafeArea(.all)
                
                // Overlay the bounding boxes on top of the camera feed
                if let debugImage = cameraService.trafficLightDetectionService.debugImage {
                    Image(uiImage: debugImage)
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                        .allowsHitTesting(false) // Allow touches to pass through
                }
                
                // Speed warning overlay
                if locationService.isExceedingSpeedLimit {
                    Text("SPEED")
                        .font(.system(size: 48, weight: .heavy))
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Collision warning overlay removed (no distance estimation)
                
                // Map widget with "Coming Soon" badge
                VStack {
                    Spacer()
                    
                    ZStack(alignment: .topTrailing) {
                        // Map placeholder
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 150)
                            .overlay(
                                Text("Map View")
                                    .foregroundColor(.secondary)
                            )
                            .padding(.horizontal)
                            .padding(.bottom, 80) // Space for control panel
                        
                        // Coming Soon badge
                        Text("COMING SOON")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(10)
                            .padding(.top, 5)
                            .padding(.trailing, 25)
                    }
                }
                
                // UI Overlays
                VStack {
                    // Top bar with speedometer and detection status
                    HStack {
                        speedometer
                            .padding()
                        Spacer()
                        trafficLightDetectionStatusIndicator
                            .padding()
                    }
                    
                    Spacer()
                    
                    // Bottom control panel
                    controlPanel
                        .padding(.bottom)
                }
            }
            
            if let error = locationService.locationError {
                errorBanner(error)
            }
            
            if let error = cameraService.error {
                errorBanner(error)
            }
            
            // Popup overlays
            if showDNDReminder {
                DNDReminderView(isShowingReminder: $showDNDReminder)
            }
            
            if showStartDrivePopup {
                StartDrivePopupView(isShowingPopup: $showStartDrivePopup) {
                    // Start recording when user confirms
                    startRecording()
                }
            }
            
            if showShareTripPopup, let summary = lastTripSummary {
                ShareTripPopupView(
                    isShowingPopup: $showShareTripPopup,
                    tripSummary: summary,
                    selectedTab: $selectedTab,
                    tripId: tripDataService.trips.last?.id
                )
            }
            
            if showDashcamSavePopup {
                DashcamSavePopupView(
                    isShowingPopup: $showDashcamSavePopup,
                    tripDataService: tripDataService
                )
            }
        }
        .onChange(of: locationService.currentLocation) { newLocation in
            if let location = newLocation {
                withAnimation {
                    region.center = location.coordinate
                }
            }
        }
        .onAppear {
            // Resume the camera session if it was paused
            if cameraService.isSessionRunning {
                cameraService.resumeSession()
            } else {
                // Initialize camera if not already running
                cameraService.checkAuthorizationAndSetup()
            }
            
            // Request location permission and center map on user's location
            locationService.requestLocationPermission()
            
            // Force center on user location when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                centerMapOnUserLocation()
            }
            
            // Show start drive popup after a short delay if not already recording
            if !isRecording {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showStartDrivePopup = true
                }
            }
            
            // Subscribe to traffic light detections
            detectionCancellable = cameraService.trafficLightDetectionService.$detectedObjects
                .receive(on: RunLoop.main)
                .sink { detectedObjects in
                    
                    if !detectedObjects.isEmpty {
                        
                        // Play different sounds for each object type
                        for object in detectedObjects {
                            if object.label.lowercased().contains("traffic light") {
                                self.playSound(for: .trafficLight)
                            } else if object.label.lowercased().contains("stop sign") {
                                self.playSound(for: .stopSign)
                            } else if object.label.lowercased().contains("person") {
                                self.playSound(for: .person)
                            } else if object.label.lowercased().contains("parking meter") {
                                self.playSound(for: .parkingMeter)
                            }
                        }
                        
                        // Add haptic feedback (only for the first object to reduce errors)
                        if let firstObject = detectedObjects.first {
                            // Limit haptic feedback to once per second to avoid rate limit errors
                            let currentTime = Date()
                            if currentTime.timeIntervalSince(self.lastProcessingTime) >= 1.0 {
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                                self.lastProcessingTime = currentTime
                            }
                        }
                    }
                }
        }
        .onDisappear {
            // Pause the camera session instead of stopping it
            // This prevents the crash when returning to this view
            cameraService.pauseSession()
            
            // Only stop location tracking if we're not recording
            if !isRecording {
                locationService.stopTracking()
            }
            
            // Cancel the detection subscription
            detectionCancellable?.cancel()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Live Monitoring")
        .withHelpButton()
    }
    
    // Improved speedometer with more accurate speed calculation and smoothing
    @State private var smoothedSpeed: Double = 0
    private let speedSmoothingFactor: Double = 0.3 // Lower value = more smoothing
    
    private var speedometer: some View {
        VStack(alignment: .leading) {
            // Calculate and smooth the speed
            Group {
                if let currentSpeed = locationService.currentLocation?.speed, currentSpeed >= 0 {
                    // Convert to mph and apply smoothing
                    let speedInMph = currentSpeed * 2.237
                    
                    // Update smoothed speed with exponential smoothing
                    let _ = DispatchQueue.main.async {
                        smoothedSpeed = (speedSmoothingFactor * speedInMph) + ((1 - speedSmoothingFactor) * smoothedSpeed)
                    }
                    
                    // Display the smoothed speed
                    Text(String(format: "%.1f mph", max(0, smoothedSpeed)))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    // No valid speed available
                    Text("0.0 mph")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
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
    
    private var trafficLightDetectionStatusIndicator: some View {
        VStack(alignment: .trailing) {
            Image(systemName: cameraService.isTrafficLightDetectionEnabled ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundColor(cameraService.isTrafficLightDetectionEnabled ? .green : .gray)
            
            Text(cameraService.isTrafficLightDetectionEnabled ? "Detection On" : "Detection Off")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
    
    private var controlPanel: some View {
        VStack {
            HStack {
                // Traffic light detection toggle
                Button(action: toggleTrafficLightDetection) {
                    VStack {
                        Image(systemName: cameraService.isTrafficLightDetectionEnabled ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                            .font(.system(size: 30))
                            .foregroundColor(cameraService.isTrafficLightDetectionEnabled ? .green : .gray)
                        
                        Text("Traffic Light")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .frame(width: 100)
                }
                
                Spacer()
                
                // Enhanced record button with glowing effect
                Button(action: toggleRecording) {
                    ZStack {
                        // Glowing effect for Start Drive button
                        if !isRecording {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 80, height: 80)
                                .opacity(0.3)
                                .blur(radius: 10)
                                .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: UUID())
                        }
                        
                        // Main button
                        VStack {
                            Image(systemName: isRecording ? "stop.circle.fill" : "record.circle")
                                .font(.system(size: 64))
                                .foregroundColor(isRecording ? .red : .green)
                            
                            Text(isRecording ? "Stop Drive" : "Start Drive")
                                .font(.caption)
                                .foregroundColor(isRecording ? .red : .green)
                                .fontWeight(.bold)
                        }
                    }
                }
                
                Spacer()
                
                // Settings button
                Button(action: {
                    // Navigate to Settings tab (index 4)
                    withAnimation {
                        selectedTab = 4
                    }
                }) {
                    VStack {
                        Image(systemName: "gear")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                        
                        Text("Settings")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .frame(width: 100)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.8))
    }
    
    private func toggleTrafficLightDetection() {
        withAnimation {
            cameraService.isTrafficLightDetectionEnabled.toggle()
        }
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
        if isRecording {
            // Stop recording
            stopRecording()
        } else {
            // Show start drive popup instead of immediately starting
            showStartDrivePopup = true
        }
    }
    
    private func startRecording() {
        isRecording = true
        
        // Show DND reminder when starting a drive
        showDNDReminder = true
        
        // Start services in the correct order
        tripDataService.startNewTrip()
        locationService.startTracking()
        
        // Camera is already running from onAppear, but ensure it's running
        if !cameraService.isSessionRunning {
            cameraService.startSession()
        }
        
        // Start dashcam recording if enabled
        if UserPreferencesService.shared.isDashcamEnabled {
            startDashcamRecording()
        }
    }
    
    // MARK: - Dashcam and Crash Detection
    
    @State private var isDashcamRecording = false
    @State private var showDashcamSavePopup = false
    @State private var crashDetected = false
    
    private func startDashcamRecording() {
        guard UserPreferencesService.shared.isDashcamEnabled else { return }
        
        isDashcamRecording = true
        
        // In a real app, this would start capturing video frames
        // For this example, we'll simulate adding frames to the buffer
        
        // Start a timer to simulate adding frames every second
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if !self.isDashcamRecording {
                timer.invalidate()
                return
            }
            
            // Simulate adding a frame to the dashcam buffer
            let timestamp = Date()
            let simulatedURL = URL(string: "file:///tmp/frame_\(timestamp.timeIntervalSince1970).mp4")!
            self.tripDataService.addDashcamFrame(timestamp: timestamp, videoURL: simulatedURL)
            
            // Simulate crash detection by checking acceleration
            if self.isRecording && UserPreferencesService.shared.isCrashDetectionEnabled {
                // Get current acceleration from location service (simulated)
                let acceleration = self.simulateCrashDetection()
                
                // Check for crash
                let isCrash = self.tripDataService.detectCrash(acceleration: acceleration, timestamp: timestamp)
                
                if isCrash {
                    self.crashDetected = true
                    
                    // Show alert
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                    
                    // In a real app, we would automatically call emergency services
                    // and send location data
                }
            }
        }
    }
    
    private func stopDashcamRecording() {
        isDashcamRecording = false
        
        // In a real app, this would stop capturing video frames
    }
    
    private func simulateCrashDetection() -> Double {
        // Simulate acceleration values
        // Normal driving: -2 to 2 m/s²
        // Hard braking: -6 to -4 m/s²
        // Crash: < -10 m/s²
        
        // 1 in 1000 chance of simulating a crash during recording
        if isRecording && Int.random(in: 0...999) == 0 {
            return -15.0 // Simulate crash
        }
        
        // Normal driving
        return Double.random(in: -2...2)
    }
    
    private func stopRecording() {
        isRecording = false
        
        // Stop services and save data
        locationService.stopTracking()
        
        // Get trip summary and route data
        let summary = locationService.getTripSummary()
        let route = locationService.tripLocations
        
        // Show dashcam save popup if enabled
        if UserPreferencesService.shared.isDashcamEnabled {
            // Show the dashcam save popup
            showDashcamSavePopup = true
        }
        
        // Update trip with collected data before ending
        tripDataService.updateCurrentTrip(
            with: summary,
            route: route,
            incidents: [] // In a real app, we would collect incidents during the trip
        )
        
        // End and save the trip
        tripDataService.endCurrentTrip()
        
        // Store the summary for sharing
        lastTripSummary = summary
        
        // Show share trip popup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showShareTripPopup = true
        }
        
        // Stop dashcam recording
        stopDashcamRecording()
        
        // Don't stop camera session to keep preview visible
        // Only stop it when view disappears
    }
    
    private func centerMapOnUserLocation() {
        if let location = locationService.currentLocation {
            withAnimation {
                region.center = location.coordinate
                // Zoom in a bit when centering
                region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            }
        } else {
            // If no location is available, request location updates
            locationService.requestLocationPermission()
        }
    }
    
    // MARK: - Audio Feedback
    
    // Enum for different object types
    enum DetectedObjectType {
        case trafficLight
        case stopSign
        case person
        case parkingMeter
    }
    
    // Audio player for warning sounds
    private var audioPlayer: AVAudioPlayer?
    
    // Make the initializer public to fix the error in MainTabView
    init(locationService: LocationService, cameraService: CameraService, tripDataService: TripDataService, selectedTab: Binding<Int> = .constant(1)) {
        self.locationService = locationService
        self.cameraService = cameraService
        self.tripDataService = tripDataService
        self._selectedTab = selectedTab
    }
    
    // Play different sounds for different object types using SoundManager
    private func playSound(for objectType: DetectedObjectType) {
        // Get the appropriate sound file name for the object type
        let soundFileName: String
        switch objectType {
        case .trafficLight:
            soundFileName = "traffic_light"
        case .stopSign:
            soundFileName = "stop_sign"
        case .person:
            soundFileName = "person"
        case .parkingMeter:
            soundFileName = "parking_meter"
        }
        
        // Use the shared SoundManager to play the sound
        SoundManager.shared.playSound(named: soundFileName)
    }
    
    // Play brake warning sound
    private func playBrakeWarningSound() {
        // Use the SoundManager to play the collision warning sound
        SoundManager.shared.playCollisionWarningSound()
    }
}
