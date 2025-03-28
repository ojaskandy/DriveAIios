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
    
    private let userDefaults = UserDefaults.standard
    private let tripsKey = "saved_trips"
    
    init() {
        loadTrips()
    }
    
    func startNewTrip() {
        let newTrip = Trip(
            startTime: Date(),
            endTime: Date(),
            distance: 0,
            averageSpeed: 0,
            maxSpeed: 0,
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
            route: route.map { LocationPoint(location: $0) },
            safetyScore: calculateSafetyScore(incidents: incidents),
            incidents: incidents
        )
        
        currentTrip = updatedTrip
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
            .laneDeparture: 5,
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
}