//
//  TripDataService.swift
//  DriveAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import Foundation
import CoreLocation
import Combine

class TripDataService: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var currentTrip: Trip?
    @Published var dashcamFrames: [(timestamp: Date, videoURL: URL)] = []
    @Published var isInitialized: Bool = true
    
    // Temporary storage for the current trip's data
    private var startTime: Date?
    private var endTime: Date?
    private var distance: Double = 0
    private var averageSpeed: Double = 0
    private var maxSpeed: Double = 0
    private var minSpeed: Double = Double.greatestFiniteMagnitude
    private var route: [LocationPoint] = []
    private var incidents: [Incident] = []
    private var safetyScore: Int = 100
    private var dashcamFootagePath: String?
    private var hasCrashDetected: Bool = false
    private var crashTimestamp: Date?
    private var crashFootagePath: String?
    
    // Dashcam buffer
    private var dashcamBuffer: [Date: URL] = [:]
    private let dashcamBufferDuration: TimeInterval = 300 // 5 minutes
    
    // Crash detection
    private var crashDetected: Bool = false
    private var lastAccelerationValues: [Double] = []
    
    // UserDefaults
    private let userDefaults = UserDefaults.standard
    private let tripsKey = "savedTrips"
    
    init() {
        loadTrips()
    }
    
    func startNewTrip() {
        // Reset crash detection state
        crashDetected = false
        crashTimestamp = nil
        crashFootagePath = nil
        dashcamFootagePath = nil
        
        // Clear dashcam buffer
        dashcamBuffer.removeAll()
        
        let newTrip = Trip(
            startTime: Date(),
            endTime: Date(),
            distance: 0,
            averageSpeed: 0,
            maxSpeed: 0,
            minSpeed: 0,
            route: [],
            safetyScore: 100,
            incidents: []
        )
        currentTrip = newTrip
    }
    
    func updateCurrentTrip(with summary: TripSummary, route: [CLLocation], incidents: [Incident]) {
        guard let trip = currentTrip else { return }
        
        let updatedTrip = Trip(
            id: trip.id,
            startTime: summary.startTime ?? trip.startTime,
            endTime: summary.endTime ?? Date(),
            distance: summary.distance,
            averageSpeed: summary.averageSpeed,
            maxSpeed: summary.maxSpeed,
            minSpeed: summary.minSpeed,
            route: route.map { LocationPoint(location: $0) },
            safetyScore: calculateSafetyScore(incidents: incidents),
            incidents: incidents,
            dashcamFootagePath: dashcamFootagePath,
            hasCrashDetected: crashDetected,
            crashTimestamp: crashTimestamp,
            crashFootagePath: crashFootagePath
        )
        
        currentTrip = updatedTrip
    }
    
    // MARK: - Dashcam Methods
    
    func addDashcamFrame(timestamp: Date, videoURL: URL) {
        // Only keep frames from the last 5 minutes
        let cutoffTime = Date().addingTimeInterval(-dashcamBufferDuration)
        
        // Add new frame
        dashcamBuffer[timestamp] = videoURL
        
        // Remove old frames
        dashcamBuffer = dashcamBuffer.filter { $0.key > cutoffTime }
    }
    
    // Save the default 2 minutes of dashcam footage
    func saveDashcamFootage() -> String? {
        guard !dashcamBuffer.isEmpty, let userPreferences = UserPreferencesService.shared as? UserPreferencesService else {
            return nil
        }
        
        // Only save if dashcam is enabled
        guard userPreferences.isDashcamEnabled else {
            return nil
        }
        
        // Create a unique filename for the footage
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        let filename = "dashcam_\(dateString).mp4"
        
        // In a real app, we would merge the video clips in dashcamBuffer
        // For this example, we'll just return the filename as if it was saved
        dashcamFootagePath = filename
        return filename
    }
    
    // Save extended (5 minutes) dashcam footage
    func saveExtendedDashcamFootage() -> String? {
        guard !dashcamBuffer.isEmpty, let userPreferences = UserPreferencesService.shared as? UserPreferencesService else {
            return nil
        }
        
        // Only save if dashcam is enabled
        guard userPreferences.isDashcamEnabled else {
            return nil
        }
        
        // Create a unique filename for the extended footage
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        let filename = "dashcam_extended_\(dateString).mp4"
        
        // In a real app, we would merge the video clips in dashcamBuffer
        // using the extended buffer duration (5 minutes)
        // For this example, we'll just return the filename as if it was saved
        dashcamFootagePath = filename
        return filename
    }
    
    // MARK: - Crash Detection Methods
    
    func detectCrash(acceleration: Double, timestamp: Date) -> Bool {
        guard let userPreferences = UserPreferencesService.shared as? UserPreferencesService else {
            return false
        }
        
        // Only detect crashes if crash detection is enabled
        guard userPreferences.isCrashDetectionEnabled else {
            return false
        }
        
        // Keep a buffer of recent acceleration values
        lastAccelerationValues.append(acceleration)
        if lastAccelerationValues.count > 10 {
            lastAccelerationValues.removeFirst()
        }
        
        // Check for sudden deceleration (negative acceleration)
        // In a real app, this would be much more sophisticated
        if acceleration < -10.0 && !crashDetected {
            // Crash detected!
            crashDetected = true
            crashTimestamp = timestamp
            
            // Save footage from 2 minutes before to 2 minutes after crash
            crashFootagePath = saveCrashFootage(timestamp: timestamp)
            
            // Create a crash incident
            if let location = currentTrip?.route.last {
                let crashIncident = Incident(
                    type: .crash,
                    timestamp: timestamp,
                    location: location,
                    description: "Crash detected with deceleration of \(String(format: "%.1f", acceleration)) m/s²"
                )
                
                // Add to incidents
                var incidents = currentTrip?.incidents ?? []
                incidents.append(crashIncident)
                
                // Update trip with new incident
                if let trip = currentTrip {
                    currentTrip = Trip(
                        id: trip.id,
                        startTime: trip.startTime,
                        endTime: trip.endTime,
                        distance: trip.distance,
                        averageSpeed: trip.averageSpeed,
                        maxSpeed: trip.maxSpeed,
                        minSpeed: trip.minSpeed,
                        route: trip.route,
                        safetyScore: calculateSafetyScore(incidents: incidents),
                        incidents: incidents,
                        dashcamFootagePath: trip.dashcamFootagePath,
                        hasCrashDetected: true,
                        crashTimestamp: timestamp,
                        crashFootagePath: crashFootagePath
                    )
                }
            }
            
            return true
        }
        
        return false
    }
    
    private func saveCrashFootage(timestamp: Date) -> String? {
        // Create a unique filename for the crash footage
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: timestamp)
        let filename = "crash_\(dateString).mp4"
        
        // In a real app, we would extract and merge video clips from dashcamBuffer
        // from 2 minutes before to 2 minutes after the crash
        // For this example, we'll just return the filename as if it was saved
        return filename
    }
    
    func endCurrentTrip() {
        guard let trip = currentTrip else { return }
        trips.append(trip)
        saveTrips()
        currentTrip = nil
    }
    
    private func calculateSafetyScore(incidents: [Incident]) -> Int {
        let baseScore = 100
        let deductions: [IncidentType: Int] = [
            .speedingViolation: 15,
            .suddenBraking: 10,
            .suddenAcceleration: 10,
            .trafficLightDetection: 5,
            .trafficViolation: 20
        ]
        
        let totalDeduction = incidents.reduce(0) { total, incident in
            total + (deductions[incident.type] ?? 0)
        }
        
        return max(0, baseScore - totalDeduction)
    }
    
    private func loadTrips() {
        guard let data = userDefaults.data(forKey: tripsKey),
              let decodedTrips = try? JSONDecoder().decode([Trip].self, from: data) else {
            return
        }
        trips = decodedTrips
    }
    
    private func saveTrips() {
        guard let encodedData = try? JSONEncoder().encode(trips) else { return }
        userDefaults.set(encodedData, forKey: tripsKey)
    }
    
    // Analytics Methods
    func getAverageSpeedForLastNTrips(_ n: Int) -> Double {
        let recentTrips = Array(trips.suffix(n))
        guard !recentTrips.isEmpty else { return 0 }
        return recentTrips.reduce(0) { $0 + $1.averageSpeed } / Double(recentTrips.count)
    }
    
    func getTotalDistance() -> Double {
        trips.reduce(0) { $0 + $1.distance }
    }
    
    func getAverageSafetyScore() -> Int {
        guard !trips.isEmpty else { return 0 }
        let totalScore = trips.reduce(0) { $0 + $1.safetyScore }
        return totalScore / trips.count
    }
    
    func getMostCommonIncidentType() -> IncidentType? {
        let allIncidents = trips.flatMap { $0.incidents }
        guard !allIncidents.isEmpty else { return nil }
        
        var incidentCounts: [IncidentType: Int] = [:]
        allIncidents.forEach { incident in
            incidentCounts[incident.type, default: 0] += 1
        }
        
        return incidentCounts.max(by: { $0.value < $1.value })?.key
    }
    
    func getTotalIncidents() -> Int {
        return trips.flatMap { $0.incidents }.count
    }
}
