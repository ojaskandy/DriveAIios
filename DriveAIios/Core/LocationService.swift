//
//  LocationService.swift
//  DriveAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var locationError: LocationError?
    @Published var isTracking = false
    
    public let locationManager = CLLocationManager()
    private var tripLocations: [CLLocation] = []
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        // Initialize basic settings but don't enable background updates yet
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .restricted, .denied:
            DispatchQueue.main.async {
                self.locationError = .permissionDenied
            }
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
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
        
        return TripSummary(
            distance: Double(distance),
            averageSpeed: averageSpeed,
            maxSpeed: maxSpeed,
            startTime: tripLocations.first?.timestamp,
            endTime: tripLocations.last?.timestamp
        )
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
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        
        DispatchQueue.main.async {
            self.currentLocation = location
            if self.isTracking {
                self.tripLocations.append(location)
            }
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
            // Request "Always" permission for background tracking
            manager.requestAlwaysAuthorization()
            manager.startUpdatingLocation()
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.locationError = .permissionDenied
            }
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        @unknown default:
            break
        }
    }
    
    public func enableBackgroundUpdates() {
        locationManager.allowsBackgroundLocationUpdates = true
    }
}

enum LocationError: Error {
    case permissionDenied
    case locationUpdateFailed
}

// Using TripSummary from TripModel