//
//  FSDVisualizationView.swift
//  CruiseAIios
//
//  Created by Ojas Kandhare on 3/31/25.
//

import SwiftUI
import CoreLocation
import MapKit

struct FSDVisualizationView: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject var cameraService: CameraService
    @ObservedObject var distanceEstimationService: DistanceEstimationService
    @State private var scrollOffset: CGFloat = 0
    
    // Constants for visualization
    private let roadWidth: CGFloat = 200
    private let laneWidth: CGFloat = 60
    private let carWidth: CGFloat = 40
    private let carLength: CGFloat = 80
    
    // Colors
    private let backgroundColor = Color.black
    private let roadColor = Color(.sRGB, red: 0.1, green: 0.1, blue: 0.15, opacity: 1)
    private let laneColor = Color.white.opacity(0.5)
    private let carColor = Color.blue.opacity(0.8)
    private let uiBackgroundColor = Color(.sRGB, red: 0.1, green: 0.1, blue: 0.12, opacity: 0.85)
    
    var body: some View {
        ScrollView {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    backgroundColor
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Top status bar
                        statusBar
                            .background(uiBackgroundColor)
                            .cornerRadius(15)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        // Main visualization area
                        ZStack {
                            // Road visualization
                            roadVisualization(in: geometry)
                            
                            // Street signs and navigation overlays
                            streetSignsOverlay(in: geometry)
                            
                            // Detected objects
                            ForEach(distanceEstimationService.trackedObjects, id: \.id) { object in
                                drawObject(object, in: geometry)
                            }
                            
                            // Vehicle visualization
                            vehicleVisualization(in: geometry)
                            
                            // Collision warning
                            if distanceEstimationService.collisionWarning == .imminent {
                                brakeWarning(in: geometry)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.size.height * 0.85)
                        
                        // Bottom controls
                        bottomControls
                            .background(uiBackgroundColor)
                            .cornerRadius(15)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }
                }
            }
        }
        .background(backgroundColor)
    }
    
    // Status bar with speed and safety info
    private var statusBar: some View {
        HStack(spacing: 20) {
            // Speed indicator
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "%.0f", (locationService.currentLocation?.speed ?? 0) * 2.237))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                Text("MPH")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Safety status
            VStack(alignment: .trailing, spacing: 4) {
                let risk = distanceEstimationService.collisionWarning
                HStack(spacing: 8) {
                    Circle()
                        .fill(riskColor(for: risk))
                        .frame(width: 12, height: 12)
                    Text(risk.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                
                if distanceEstimationService.closestObjectDistance < Double.infinity {
                    Text("\(String(format: "%.1f", distanceEstimationService.closestObjectDistance))m ahead")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
    }
    
    // Road visualization with lanes and markings
    private func roadVisualization(in geometry: GeometryProxy) -> some View {
        ZStack {
            // Road surface
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                
                path.move(to: CGPoint(x: width * 0.3, y: height))
                path.addLine(to: CGPoint(x: width * 0.7, y: height))
                path.addLine(to: CGPoint(x: width * 0.6, y: height * 0.2))
                path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.2))
                path.closeSubpath()
            }
            .fill(roadColor)
            
            // Lane markings
            ForEach(-1...1, id: \.self) { lane in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let laneOffset = CGFloat(lane) * (width * 0.1)
                    
                    for i in 0...10 {
                        let y = height * (0.3 + CGFloat(i) * 0.07)
                        let xOffset = laneOffset * (1 - CGFloat(i) * 0.08)
                        path.move(to: CGPoint(x: width/2 + xOffset - 2, y: y))
                        path.addLine(to: CGPoint(x: width/2 + xOffset + 2, y: y))
                    }
                }
                .stroke(laneColor, lineWidth: 2)
            }
        }
    }
    
    // Street signs and navigation overlay
    private func streetSignsOverlay(in geometry: GeometryProxy) -> some View {
        ZStack {
            // Example street sign (customize based on actual data)
            ForEach(mockStreetSigns, id: \.id) { sign in
                streetSignView(sign, in: geometry)
            }
        }
    }
    
    // Vehicle visualization
    private func vehicleVisualization(in geometry: GeometryProxy) -> some View {
        ZStack {
            // Vehicle body
            RoundedRectangle(cornerRadius: 12)
                .fill(carColor)
                .frame(width: carWidth, height: carLength)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            
            // Wheels
            ForEach([-1, 1], id: \.self) { xOffset in
                ForEach([-1, 1], id: \.self) { yOffset in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black)
                        .frame(width: 8, height: 12)
                        .offset(x: CGFloat(xOffset) * (carWidth/2 - 4),
                                y: CGFloat(yOffset) * (carLength/3))
                }
            }
        }
        .position(x: geometry.size.width/2, y: geometry.size.height * 0.85)
    }
    
    // Bottom controls
    private var bottomControls: some View {
        HStack(spacing: 20) {
            Button(action: {
                // Toggle autopilot
            }) {
                Image(systemName: "car.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(action: {
                // Toggle camera view
            }) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
        .padding()
    }
    
    // Helper functions
    private func riskColor(for risk: CollisionRisk) -> Color {
        switch risk {
        case .none: return .green
        case .low: return .yellow
        case .medium: return .orange
        case .high, .imminent: return .red
        }
    }
    
    private func brakeWarning(in geometry: GeometryProxy) -> some View {
        Text("BRAKE!")
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(.white)
            .padding()
            .background(Color.red)
            .cornerRadius(10)
            .position(x: geometry.size.width/2, y: geometry.size.height * 0.3)
    }
    
    // Draw a detected object
    private func drawObject(_ object: TrackedObject, in geometry: GeometryProxy) -> some View {
        let objectType = getBaseObjectType(from: object.detectedObject.label)
        
        // Safely unwrap the distance, or use a default value
        guard let distance = object.estimatedDistance else {
            return AnyView(EmptyView()) // Return empty view if no distance available
        }
        
        // Calculate position based on distance
        // Objects further away are higher up in the view
        let maxDistance: Double = 100.0 // Maximum visible distance in meters
        let minY = geometry.size.height * 0.2 // Top of the road
        let maxY = geometry.size.height * 0.7 // Just in front of the car
        
        // Calculate y position based on distance
        let yPosition = maxY - CGFloat(min(distance, maxDistance) / maxDistance) * (maxY - minY)
        
        // Calculate x position based on object's horizontal position in camera frame
        let centerX = geometry.size.width / 2
        let boundingBoxCenterX = object.detectedObject.boundingBox.midX
        // Map from 0-1 to road width
        let xOffset = (boundingBoxCenterX - 0.5) * roadWidth
        let xPosition = centerX + xOffset
        
        // Determine object size based on distance
        let baseSize: CGFloat = 30
        let size = max(baseSize * CGFloat(10 / max(distance, 10)), 10)
        
        // Determine color based on collision risk
        let color: Color = riskColor(for: object.collisionRisk)
        
        return AnyView(
            ZStack {
                // Object shape based on type
                Group {
                    if objectType == "person" {
                        PersonShape()
                            .fill(color)
                            .frame(width: size, height: size * 1.5)
                    } else if objectType == "car" || objectType == "truck" || objectType == "bus" {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(color)
                            .frame(width: size * 1.2, height: size * 0.8)
                    } else if objectType == "bicycle" || objectType == "motorcycle" {
                        BicycleShape()
                            .fill(color)
                            .frame(width: size, height: size)
                    } else if objectType == "traffic light" {
                        TrafficLightShape()
                            .fill(color)
                            .frame(width: size * 0.6, height: size)
                    } else if objectType == "stop sign" {
                        StopSignShape()
                            .fill(color)
                            .frame(width: size, height: size)
                    } else {
                        Circle()
                            .fill(color)
                            .frame(width: size, height: size)
                    }
                }
                .overlay(
                    VStack(spacing: 2) {
                        Text(objectType.capitalized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Text(String(format: "%.1f m", distance))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(color)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(color, lineWidth: 1)
                    )
                    .offset(y: -size - 24)
                )
            }
            .position(x: xPosition, y: yPosition)
        )
    }
    
    // Helper to get base object type from label
    private func getBaseObjectType(from label: String) -> String {
        let lowercasedLabel = label.lowercased()
        
        if lowercasedLabel.contains("person") {
            return "person"
        } else if lowercasedLabel.contains("car") {
            return "car"
        } else if lowercasedLabel.contains("truck") {
            return "truck"
        } else if lowercasedLabel.contains("bus") {
            return "bus"
        } else if lowercasedLabel.contains("bicycle") {
            return "bicycle"
        } else if lowercasedLabel.contains("motorcycle") {
            return "motorcycle"
        } else if lowercasedLabel.contains("traffic light") {
            return "traffic light"
        } else if lowercasedLabel.contains("stop sign") {
            return "stop sign"
        }
        
        return "unknown"
    }
}

// Mock street sign data - replace with real data
struct StreetSign: Identifiable {
    let id = UUID()
    let type: String
    let distance: Double
    let position: CGPoint
}

let mockStreetSigns = [
    StreetSign(type: "STOP", distance: 50, position: CGPoint(x: 0.7, y: 0.4)),
    StreetSign(type: "SPEED\n35", distance: 100, position: CGPoint(x: 0.3, y: 0.3))
]

// Street sign view
private func streetSignView(_ sign: StreetSign, in geometry: GeometryProxy) -> some View {
    VStack(spacing: 4) {
        Image(systemName: sign.type == "STOP" ? "octagon.fill" : "circle.fill")
            .foregroundColor(sign.type == "STOP" ? .red : .white)
            .font(.system(size: 24))
        
        Text(sign.type)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
        
        Text(String(format: "%.0fm", sign.distance))
            .font(.system(size: 10))
            .foregroundColor(.gray)
    }
    .padding(8)
    .background(Color.black.opacity(0.7))
    .cornerRadius(8)
    .position(
        x: geometry.size.width * sign.position.x,
        y: geometry.size.height * sign.position.y
    )
}

// Custom shapes for different object types

struct PersonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Head
        let headRadius = rect.width * 0.3
        let headCenter = CGPoint(x: rect.midX, y: rect.minY + headRadius)
        path.addArc(center: headCenter, radius: headRadius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        
        // Body
        let bodyTop = headCenter.y + headRadius
        let bodyBottom = rect.maxY - rect.height * 0.2
        path.move(to: CGPoint(x: rect.midX, y: bodyTop))
        path.addLine(to: CGPoint(x: rect.midX, y: bodyBottom))
        
        // Arms
        let armsY = bodyTop + (bodyBottom - bodyTop) * 0.3
        path.move(to: CGPoint(x: rect.midX - rect.width * 0.4, y: armsY))
        path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.4, y: armsY))
        
        // Legs
        path.move(to: CGPoint(x: rect.midX, y: bodyBottom))
        path.addLine(to: CGPoint(x: rect.midX - rect.width * 0.3, y: rect.maxY))
        
        path.move(to: CGPoint(x: rect.midX, y: bodyBottom))
        path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.3, y: rect.maxY))
        
        return path
    }
}

struct BicycleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Wheels
        let wheelRadius = rect.width * 0.3
        let leftWheelCenter = CGPoint(x: rect.minX + wheelRadius, y: rect.maxY - wheelRadius)
        let rightWheelCenter = CGPoint(x: rect.maxX - wheelRadius, y: rect.maxY - wheelRadius)
        
        path.addArc(center: leftWheelCenter, radius: wheelRadius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        path.addArc(center: rightWheelCenter, radius: wheelRadius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        
        // Frame
        path.move(to: leftWheelCenter)
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.3))
        path.addLine(to: rightWheelCenter)
        
        // Handlebars
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.3))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        
        return path
    }
}

struct TrafficLightShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Traffic light body
        let bodyWidth = rect.width * 0.8
        let bodyHeight = rect.height * 0.9
        let bodyRect = CGRect(
            x: rect.midX - bodyWidth / 2,
            y: rect.minY,
            width: bodyWidth,
            height: bodyHeight
        )
        
        path.addRoundedRect(in: bodyRect, cornerSize: CGSize(width: bodyWidth * 0.2, height: bodyWidth * 0.2))
        
        // Lights
        let lightRadius = bodyWidth * 0.3
        let lightCenterX = rect.midX
        
        // Red light
        let redLightCenterY = bodyRect.minY + bodyHeight * 0.2
        path.addArc(center: CGPoint(x: lightCenterX, y: redLightCenterY), radius: lightRadius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        
        // Yellow light
        let yellowLightCenterY = bodyRect.minY + bodyHeight * 0.5
        path.addArc(center: CGPoint(x: lightCenterX, y: yellowLightCenterY), radius: lightRadius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        
        // Green light
        let greenLightCenterY = bodyRect.minY + bodyHeight * 0.8
        path.addArc(center: CGPoint(x: lightCenterX, y: greenLightCenterY), radius: lightRadius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        
        return path
    }
}

struct StopSignShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Create an octagon
        let sideLength = min(rect.width, rect.height) * 0.4
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        for i in 0..<8 {
            let angle = CGFloat(i) * .pi / 4
            let x = center.x + sideLength * cos(angle)
            let y = center.y + sideLength * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        
        return path
    }
}

struct FSDVisualizationView_Previews: PreviewProvider {
    static var previews: some View {
        FSDVisualizationView(
            locationService: LocationService(),
            cameraService: CameraService(),
            distanceEstimationService: DistanceEstimationService()
        )
    }
}
