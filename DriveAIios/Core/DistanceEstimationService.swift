//
//  DistanceEstimationService.swift
//  CruiseAIios
//
//  Created by Ojas Kandhare on 3/31/25.
//

import Foundation
import UIKit
import CoreMotion
import AVFoundation
import Vision
import Combine

enum CollisionRisk: String {
    case none = "No Risk"
    case low = "Low Risk"
    case medium = "Medium Risk"
    case high = "High Risk"
    case imminent = "BRAKE NOW"
    
    var color: UIColor {
        switch self {
        case .none: return .green
        case .low: return .yellow
        case .medium: return .orange
        case .high: return .red
        case .imminent: return .red
        }
    }
}

struct TrackedObject {
    let id: UUID
    let detectedObject: DetectedObject
    let estimatedDistance: Double?
    let estimatedApproachSpeed: Double?
    let collisionRisk: CollisionRisk
    let firstDetectedAt: Date
    let lastUpdatedAt: Date
    
    // Previous frame data for tracking
    var previousBoundingBox: CGRect?
    var previousDistance: Double?
    var previousTimestamp: Date?
}

class DistanceEstimationService: ObservableObject {
    // Published properties for UI updates
    @Published private(set) var trackedObjects: [TrackedObject] = []
    @Published private(set) var collisionWarning: CollisionRisk = .none
    @Published private(set) var closestObjectDistance: Double = Double.infinity
    
    // Camera parameters (will be calibrated)
    private var focalLength: Double = 1000.0 // Default value, will be calibrated
    private var principalPoint: CGPoint = .zero
    private var imageSize: CGSize = .zero
    
    // Known object dimensions (in meters)
    private let knownObjectDimensions: [String: Double] = [
        "person": 0.5,
        "car": 1.8,
        "bicycle": 0.6,
        "motorcycle": 0.8,
        "truck": 2.5,
        "bus": 2.5,
        "train": 3.0,
        "boat": 2.0,
        "traffic light": 0.3,
        "stop sign": 0.6,
        "parking meter": 0.3
    ]
    
    // Object tracking
    private var previousFrameObjects: [TrackedObject] = []
    private let objectTrackingTimeout: TimeInterval = 1.0 // Remove objects not seen for 1 second
    
    // Motion manager for device orientation
    private let motionManager = CMMotionManager()
    
    // Collision risk thresholds - more aggressive for safety
    private let collisionRiskThresholds: [CollisionRisk: (distance: Double, ttc: Double)] = [
        .low: (distance: 60.0, ttc: 6.0),
        .medium: (distance: 40.0, ttc: 4.0),
        .high: (distance: 20.0, ttc: 2.5),
        .imminent: (distance: 10.0, ttc: 1.5)
    ]
    
    // Object-specific risk thresholds - more sensitive for vulnerable road users
    private let objectSpecificThresholds: [String: [CollisionRisk: (distance: Double, ttc: Double)]] = [
        "person": [
            .low: (distance: 70.0, ttc: 7.0),
            .medium: (distance: 50.0, ttc: 5.0),
            .high: (distance: 30.0, ttc: 3.0),
            .imminent: (distance: 15.0, ttc: 2.0)
        ],
        "bicycle": [
            .low: (distance: 65.0, ttc: 6.5),
            .medium: (distance: 45.0, ttc: 4.5),
            .high: (distance: 25.0, ttc: 2.8),
            .imminent: (distance: 12.0, ttc: 1.8)
        ],
        "motorcycle": [
            .low: (distance: 65.0, ttc: 6.5),
            .medium: (distance: 45.0, ttc: 4.5),
            .high: (distance: 25.0, ttc: 2.8),
            .imminent: (distance: 12.0, ttc: 1.8)
        ]
    ]
    
    init() {
        setupMotionManager()
    }
    
    private func setupMotionManager() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates()
        }
    }
    
    // Call this method to calibrate the camera
    func calibrateCamera(with captureDevice: AVCaptureDevice, imageSize: CGSize) {
        self.imageSize = imageSize
        
        // Get intrinsic matrix if available
        if let intrinsicMatrix = CMGetHomographicMatrix(for: .intrinsic, from: captureDevice) {
            // Extract focal length and principal point from intrinsic matrix - convert Float to Double explicitly
            focalLength = Double(intrinsicMatrix.columns.0.x)
            principalPoint = CGPoint(x: Double(intrinsicMatrix.columns.2.x), 
                                   y: Double(intrinsicMatrix.columns.2.y))
        } else {
            // Fallback to approximation based on field of view
            let fov = Double(captureDevice.activeFormat.videoFieldOfView)
            focalLength = Double(imageSize.width) / (2.0 * tan(fov * .pi / 360.0))
            principalPoint = CGPoint(x: imageSize.width / 2.0, y: imageSize.height / 2.0)
        }
        
        print("Camera calibrated - Focal length: \(focalLength), Principal point: \(principalPoint)")
    }
    
    // Process detected objects and update tracking
    func processDetectedObjects(_ detectedObjects: [DetectedObject], 
                               currentSpeed: Double,
                               timestamp: Date,
                               imageSize: CGSize) {
        // Update image size if needed
        if self.imageSize != imageSize {
            self.imageSize = imageSize
        }
        
        // Track objects across frames
        let currentTrackedObjects = trackObjectsAcrossFrames(detectedObjects, 
                                                           currentSpeed: currentSpeed,
                                                           timestamp: timestamp)
        
        // Update tracked objects
        self.trackedObjects = currentTrackedObjects
        
        // Find closest object and assess collision risk
        updateCollisionWarning(currentSpeed: currentSpeed)
    }
    
    // Track objects across frames
    private func trackObjectsAcrossFrames(_ currentObjects: [DetectedObject],
                                        currentSpeed: Double,
                                        timestamp: Date) -> [TrackedObject] {
        var newTrackedObjects: [TrackedObject] = []
        
        // Process each detected object
        for object in currentObjects {
            // Try to find matching object in previous frame
            if let matchIndex = findMatchingObjectIndex(for: object) {
                let previousObject = previousFrameObjects[matchIndex]
                
                // Calculate distance
                let distance = estimateDistance(for: object)
                
                // Calculate approach speed
                var approachSpeed = currentSpeed
                if let prevDistance = previousObject.estimatedDistance,
                   let prevTimestamp = previousObject.previousTimestamp {
                    let timeDelta = timestamp.timeIntervalSince(prevTimestamp)
                    if timeDelta > 0 {
                        let distanceDelta = prevDistance - distance
                        approachSpeed = distanceDelta / timeDelta
                    }
                }
                
                // Assess collision risk
                let risk = assessCollisionRisk(distance: distance, 
                                              approachSpeed: approachSpeed,
                                              currentSpeed: currentSpeed,
                                              objectType: object.label)
                
                // Create updated tracked object
                let trackedObject = TrackedObject(
                    id: previousObject.id,
                    detectedObject: object,
                    estimatedDistance: distance,
                    estimatedApproachSpeed: approachSpeed,
                    collisionRisk: risk,
                    firstDetectedAt: previousObject.firstDetectedAt,
                    lastUpdatedAt: timestamp,
                    previousBoundingBox: previousObject.detectedObject.boundingBox,
                    previousDistance: previousObject.estimatedDistance,
                    previousTimestamp: previousObject.lastUpdatedAt
                )
                
                newTrackedObjects.append(trackedObject)
            } else {
                // New object detected
                let distance = estimateDistance(for: object)
                
                let trackedObject = TrackedObject(
                    id: UUID(),
                    detectedObject: object,
                    estimatedDistance: distance,
                    estimatedApproachSpeed: currentSpeed,
                    collisionRisk: .none,  // Start with no risk for new objects
                    firstDetectedAt: timestamp,
                    lastUpdatedAt: timestamp,
                    previousBoundingBox: nil,
                    previousDistance: nil,
                    previousTimestamp: nil
                )
                
                newTrackedObjects.append(trackedObject)
            }
        }
        
        // Keep track of objects that are still in frame
        previousFrameObjects = newTrackedObjects
        
        return newTrackedObjects
    }
    
    // Find matching object from previous frame
    private func findMatchingObjectIndex(for object: DetectedObject) -> Int? {
        // Simple IoU (Intersection over Union) based matching
        for (index, trackedObject) in previousFrameObjects.enumerated() {
            // Only match objects of the same type
            if trackedObject.detectedObject.label == object.label {
                let iou = calculateIoU(box1: trackedObject.detectedObject.boundingBox,
                                      box2: object.boundingBox)
                
                // If IoU is above threshold, consider it the same object
                if iou > 0.5 {
                    return index
                }
            }
        }
        
        return nil
    }
    
    // Calculate Intersection over Union for two bounding boxes
    private func calculateIoU(box1: CGRect, box2: CGRect) -> Double {
        let intersectionRect = box1.intersection(box2)
        
        // If there's no intersection, IoU is 0
        if intersectionRect.isEmpty {
            return 0.0
        }
        
        let intersectionArea = intersectionRect.width * intersectionRect.height
        let box1Area = box1.width * box1.height
        let box2Area = box2.width * box2.height
        let unionArea = box1Area + box2Area - intersectionArea
        
        return Double(intersectionArea / unionArea)
    }
    
    // Estimate distance based on object size
    private func estimateDistance(for object: DetectedObject) -> Double {
        // Get known width for this object type
        let objectType = getBaseObjectType(from: object.label)
        guard let knownWidth = knownObjectDimensions[objectType] else {
            // Default to a conservative estimate if object type is unknown
            return 10.0
        }
        
        // Calculate distance using the formula:
        // distance = (known_width_of_object * focal_length) / perceived_width_in_pixels
        let perceivedWidth = object.boundingBox.width * imageSize.width
        if perceivedWidth > 0 {
            let distance = (knownWidth * focalLength) / Double(perceivedWidth)
            
            // Apply ground plane correction based on y-position
            let groundPlaneCorrection = estimateGroundPlaneCorrection(for: object)
            
            // Combine the two estimates with weighted average
            // Size-based estimate is more reliable for closer objects
            let combinedDistance = distance * 0.7 + groundPlaneCorrection * 0.3
            
            return max(1.0, combinedDistance) // Ensure minimum distance of 1 meter
        }
        
        // Fallback to ground plane estimation if width is invalid
        return estimateGroundPlaneCorrection(for: object)
    }
    
    // Estimate distance based on ground plane assumption
    private func estimateGroundPlaneCorrection(for object: DetectedObject) -> Double {
        // Objects higher in the frame are typically further away
        // This is a simplified model assuming flat ground
        
        // Get the bottom center of the bounding box (where object touches ground)
        let bottomCenterY = (object.boundingBox.maxY * imageSize.height)
        
        // Map y-coordinate to distance
        // Objects at the bottom of the frame are closest
        // Objects at the horizon are furthest
        let horizonY = imageSize.height * 0.5 // Approximate horizon position
        let maxDistance = 100.0 // Maximum distance estimate in meters
        
        if bottomCenterY >= imageSize.height {
            return 1.0 // Object is at the very bottom of the frame
        } else if bottomCenterY <= horizonY {
            return maxDistance // Object is at or above the horizon
        } else {
            // Linear mapping from y-coordinate to distance
            let distanceRatio = (imageSize.height - bottomCenterY) / (imageSize.height - horizonY)
            return 1.0 + (maxDistance - 1.0) * Double(distanceRatio)
        }
    }
    
    // Extract base object type from label
    private func getBaseObjectType(from label: String) -> String {
        let lowercasedLabel = label.lowercased()
        
        for objectType in knownObjectDimensions.keys {
            if lowercasedLabel.contains(objectType) {
                return objectType
            }
        }
        
        // Default to person if unknown
        return "person"
    }
    
    // Assess collision risk based on distance, approach speed, and object type
    private func assessCollisionRisk(distance: Double, approachSpeed: Double, currentSpeed: Double, objectType: String = "") -> CollisionRisk {
        // If not moving or moving away, no collision risk
        if currentSpeed <= 0 || approachSpeed <= 0 {
            return .none
        }
        
        // Calculate time to collision (TTC)
        let ttc = distance / approachSpeed
        
        // Get the appropriate thresholds based on object type
        let baseObjectType = getBaseObjectType(from: objectType)
        let thresholds = objectSpecificThresholds[baseObjectType] ?? collisionRiskThresholds
        
        // Determine risk level based on distance and TTC
        // Use optional binding to safely unwrap threshold values
        if let imminentThreshold = thresholds[.imminent],
           (distance <= imminentThreshold.distance || ttc <= imminentThreshold.ttc) {
            return .imminent
        } else if let highThreshold = thresholds[.high],
                  (distance <= highThreshold.distance || ttc <= highThreshold.ttc) {
            return .high
        } else if let mediumThreshold = thresholds[.medium],
                  (distance <= mediumThreshold.distance || ttc <= mediumThreshold.ttc) {
            return .medium
        } else if let lowThreshold = thresholds[.low],
                  (distance <= lowThreshold.distance || ttc <= lowThreshold.ttc) {
            return .low
        }
        
        return .none
    }
    
    // Update collision warning based on closest object
    private func updateCollisionWarning(currentSpeed: Double) {
        var closestDistance = Double.infinity
        var highestRisk = CollisionRisk.none
        
        // Find closest object and assess risk
        for object in trackedObjects {
            if let distance = object.estimatedDistance {
                closestDistance = min(closestDistance, distance)
                let risk = assessCollisionRisk(distance: distance,
                                             approachSpeed: object.estimatedApproachSpeed ?? currentSpeed,
                                             currentSpeed: currentSpeed,
                                             objectType: object.detectedObject.label)
                
                // Update highest risk if current risk is higher
                if risk.rawValue > highestRisk.rawValue {
                    highestRisk = risk
                }
            }
        }
        
        // Update published properties
        DispatchQueue.main.async {
            self.closestObjectDistance = closestDistance
            self.collisionWarning = highestRisk
        }
    }
    
    // Helper to convert risk level to numeric value for comparison
    private func riskLevel(_ risk: CollisionRisk) -> Int {
        switch risk {
        case .none: return 0
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .imminent: return 4
        }
    }
    
    // Get the highest risk object for UI highlighting
    func getHighestRiskObject() -> TrackedObject? {
        var highestRisk: TrackedObject? = nil
        var maxRiskLevel = -1
        
        for object in trackedObjects {
            let risk = riskLevel(object.collisionRisk)
            if risk > maxRiskLevel {
                maxRiskLevel = risk
                highestRisk = object
            }
        }
        
        return highestRisk
    }
    
    // Define our own enum for matrix types since AVCaptureDevice.HomographicMatrixType may not be available
    private enum MatrixType {
        case intrinsic
        case extrinsic
    }
    
    // Helper function to get homographic matrix if available
    private func CMGetHomographicMatrix(for type: MatrixType, from device: AVCaptureDevice) -> simd_float3x3? {
        // In iOS 16+, we could use device.homographicMatrix(for:) but since it's not available,
        // we'll use a fallback approach to estimate the intrinsic matrix
        
        // Create an estimated intrinsic matrix based on device properties
        if type == .intrinsic {
            let width = Float(imageSize.width)
            let height = Float(imageSize.height)
            
            // Estimate focal length based on field of view
            let fov = Float(device.activeFormat.videoFieldOfView)
            let focalLengthEstimate = width / (2.0 * tanf(fov * .pi / 360.0))
            
            // Create intrinsic matrix [fx 0 cx; 0 fy cy; 0 0 1]
            let fx = focalLengthEstimate
            let fy = focalLengthEstimate
            let cx = width / 2.0
            let cy = height / 2.0
            
            return simd_float3x3([
                simd_float3(fx, 0, 0),
                simd_float3(0, fy, 0),
                simd_float3(cx, cy, 1)
            ])
        }
        
        // For extrinsic or other matrix types, return nil
        return nil
    }
}
