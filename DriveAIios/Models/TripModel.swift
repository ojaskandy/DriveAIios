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
    let dashcamFootagePath: String?
    let hasCrashDetected: Bool
    let crashTimestamp: Date?
    let crashFootagePath: String?
    
    var date: Date {
        startTime
    }
    
    init(id: UUID = UUID(),
         startTime: Date,
         endTime: Date,
         distance: Double,
         averageSpeed: Double,
         maxSpeed: Double,
         route: [LocationPoint],
         safetyScore: Int,
         incidents: [Incident],
         dashcamFootagePath: String? = nil,
         hasCrashDetected: Bool = false,
         crashTimestamp: Date? = nil,
         crashFootagePath: String? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.distance = distance
        self.averageSpeed = averageSpeed
        self.maxSpeed = maxSpeed
        self.route = route
        self.safetyScore = safetyScore
        self.incidents = incidents
        self.dashcamFootagePath = dashcamFootagePath
        self.hasCrashDetected = hasCrashDetected
        self.crashTimestamp = crashTimestamp
        self.crashFootagePath = crashFootagePath
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
    case trafficLightDetection
    case trafficViolation
    case crash
}

struct TripSummary: Codable {
    let distance: Double
    let averageSpeed: Double
    let maxSpeed: Double
    let startTime: Date?
    let endTime: Date?
}
