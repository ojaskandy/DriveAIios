//
//  TripModel.swift
//  DriveAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import Foundation
import CoreLocation

struct Trip: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let distance: Double
    let averageSpeed: Double
    let maxSpeed: Double
    let route: [LocationPoint]
    let safetyScore: Int
    let incidents: [Incident]
    
    init(id: UUID = UUID(),
         startTime: Date,
         endTime: Date,
         distance: Double,
         averageSpeed: Double,
         maxSpeed: Double,
         route: [LocationPoint],
         safetyScore: Int,
         incidents: [Incident]) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.distance = distance
        self.averageSpeed = averageSpeed
        self.maxSpeed = maxSpeed
        self.route = route
        self.safetyScore = safetyScore
        self.incidents = incidents
    }
}

struct LocationPoint: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let speed: Double
    
    init(location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.timestamp = location.timestamp
        self.speed = location.speed
    }
}

struct Incident: Identifiable, Codable {
    let id: UUID
    let type: IncidentType
    let timestamp: Date
    let location: LocationPoint
    let description: String
    
    init(id: UUID = UUID(),
         type: IncidentType,
         timestamp: Date,
         location: LocationPoint,
         description: String) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.location = location
        self.description = description
    }
}

enum IncidentType: String, Codable {
    case speedingViolation
    case suddenBraking
    case suddenAcceleration
    case laneDeparture
    case trafficViolation
}

struct TripSummary: Codable {
    let distance: Double
    let averageSpeed: Double
    let maxSpeed: Double
    let startTime: Date?
    let endTime: Date?
}