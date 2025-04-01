//
//  LocationService.swift
//  CruiseAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import Foundation
import CoreLocation
import Combine
import MapKit
import AVFoundation

class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var locationError: LocationError?
    @Published var isTracking = false
    @Published var currentSpeedLimit: Double = 0 // mph
    @Published var isExceedingSpeedLimit = false
    @Published var speedLimitExceededTime: Date?
    
    // Speed limit warning cooldown
    private var lastSpeedWarningTime: Date?
    private let speedWarningCooldown: TimeInterval = 30.0 // 30 seconds between speed warnings
    
    public let locationManager = CLLocationManager()
    // Make tripLocations accessible to other classes
    private(set) var tripLocations: [CLLocation] = []
    
    // MKDirections for getting route information including speed limits
    private let mapHelper = MKDirections.Request()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation // Highest accuracy for navigation
        locationManager.distanceFilter = 5 // Update every 5 meters for more frequent updates
        locationManager.activityType = .automotiveNavigation // Optimize for driving
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // Request location immediately when the app starts
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            // Start with "when in use" permission first, which is less intrusive
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            DispatchQueue.main.async {
                self.locationError = .permissionDenied
            }
        case .authorizedWhenInUse:
            // Only request "always" if absolutely necessary
            // For testing on a physical device, "when in use" is sufficient
            locationManager.startUpdatingLocation()
        case .authorizedAlways:
            enableBackgroundUpdates()
            locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    func startTracking() {
        isTracking = true
        tripLocations.removeAll()
        locationManager.startUpdatingLocation()
    }
    
    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        // Save trip data here
    }
    
    func getTripSummary() -> TripSummary {
        let distance = calculateTotalDistance()
        let averageSpeed = calculateAverageSpeed()
        let maxSpeed = calculateMaxSpeed()
        let minSpeed = calculateMinSpeed()
        
        return TripSummary(
            distance: Double(distance),
            averageSpeed: averageSpeed,
            maxSpeed: maxSpeed,
            minSpeed: minSpeed,
            startTime: tripLocations.first?.timestamp,
            endTime: tripLocations.last?.timestamp
        )
    }
    
    // Convert CLLocation to LocationPoint
    func locationPoint(from location: CLLocation) -> LocationPoint {
        return LocationPoint(location: location)
    }
    
    private func calculateTotalDistance() -> CLLocationDistance {
        guard tripLocations.count > 1 else { return 0 }
        
        var totalDistance: CLLocationDistance = 0
        for i in 0..<tripLocations.count - 1 {
            totalDistance += tripLocations[i].distance(from: tripLocations[i + 1])
        }
        
        return totalDistance
    }
    
    private func calculateAverageSpeed() -> Double {
        guard !tripLocations.isEmpty else { return 0 }
        let speeds = tripLocations.compactMap { $0.speed >= 0 ? $0.speed : nil }
        return speeds.reduce(0, +) / Double(speeds.count)
    }
    
    private func calculateMaxSpeed() -> Double {
        guard !tripLocations.isEmpty else { return 0 }
        return tripLocations.compactMap { $0.speed >= 0 ? $0.speed : nil }.max() ?? 0
    }
    
    private func calculateMinSpeed() -> Double {
        guard !tripLocations.isEmpty else { return 0 }
        // Filter out negative speeds (which indicate invalid readings) and get non-zero minimum
        let validSpeeds = tripLocations.compactMap { $0.speed >= 0 ? $0.speed : nil }
        // Filter out zero speeds when the vehicle is stationary, unless all speeds are zero
        let movingSpeeds = validSpeeds.filter { $0 > 0.1 } // Consider speeds above 0.1 m/s as moving
        return movingSpeeds.isEmpty ? 0 : (movingSpeeds.min() ?? 0)
    }
    
    // Check if user is exceeding speed limit
    func checkSpeedLimit(currentSpeed: Double) {
        // Only check if we have a valid speed limit
        guard currentSpeedLimit > 0 else { return }
        
        // Convert m/s to mph for comparison
        let speedMph = currentSpeed * 2.237
        
        // Check if speed is 10% over the limit
        let speedLimitThreshold = currentSpeedLimit * 1.1
        let isExceeding = speedMph > speedLimitThreshold
        
        // Check if we should show a warning (first time or after cooldown)
        let shouldWarn = isExceeding && 
                        (lastSpeedWarningTime == nil || 
                         (lastSpeedWarningTime != nil &&
                          Date().timeIntervalSince(lastSpeedWarningTime!) >= speedWarningCooldown))
        
        if shouldWarn {
            // Update warning time
            lastSpeedWarningTime = Date()
            speedLimitExceededTime = Date()
            
            // Update published property to trigger UI update
            DispatchQueue.main.async {
                self.isExceedingSpeedLimit = true
                
                // Play speed warning sound
                self.speakSpeedWarning()
                
                // Reset after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.isExceedingSpeedLimit = false
                }
            }
        }
    }
    
    // Get speed limit for current location
    func updateSpeedLimit(at location: CLLocation) {
        // Create a map item from the location
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        
        // Get the address for this location
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self, error == nil, let _ = placemarks?.first else { return }
            
            // Use MKDirections to get route information including speed limit
            let request = MKDirections.Request()
            request.source = MKMapItem.forCurrentLocation()
            request.destination = mapItem
            
            let directions = MKDirections(request: request)
            directions.calculate { [weak self] response, error in
                guard let self = self, let _ = response?.routes.first else { return }
                
                // For demonstration, we'll use a default value of 30 mph
                // In a real app, you would use actual speed limit data from the route
                let speedLimitMph = 30.0
                
                DispatchQueue.main.async {
                    self.currentSpeedLimit = speedLimitMph
                    
                    // Check if user is exceeding speed limit
                    if let currentLocation = self.currentLocation {
                        self.checkSpeedLimit(currentSpeed: currentLocation.speed)
                    }
                }
            }
        }
    }
    
    // Speak speed warning
    private func speakSpeedWarning() {
        let speechSynthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: "Speed")
        utterance.rate = 0.5
        utterance.volume = 1.0
        utterance.pitchMultiplier = 1.2
        speechSynthesizer.speak(utterance)
    }
    
    public func enableBackgroundUpdates() {
        locationManager.allowsBackgroundLocationUpdates = true
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location
            if self.isTracking {
                self.tripLocations.append(location)
            }
            
            // Update speed limit every 30 seconds or when location changes significantly
            let shouldUpdateSpeedLimit = self.lastSpeedWarningTime == nil || 
                                        (self.lastSpeedWarningTime != nil && 
                                         Date().timeIntervalSince(self.lastSpeedWarningTime!) >= 30.0)
            if shouldUpdateSpeedLimit {
                self.updateSpeedLimit(at: location)
            }
            
            // Check if user is exceeding speed limit
            self.checkSpeedLimit(currentSpeed: location.speed)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = .locationUpdateFailed
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways:
            enableBackgroundUpdates()
            manager.startUpdatingLocation()
        case .authorizedWhenInUse:
            // For testing on a physical device, "when in use" is sufficient
            // Don't request "always" permission again to avoid annoying the user
            manager.startUpdatingLocation()
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.locationError = .permissionDenied
            }
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}

enum LocationError: Error {
    case permissionDenied
    case locationUpdateFailed
}

// Using TripSummary from TripModel
