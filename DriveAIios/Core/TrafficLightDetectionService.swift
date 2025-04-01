//
//  TrafficLightDetectionService.swift
//  DriveAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import Foundation
import Vision
import CoreML
import UIKit
import AVFoundation
import Combine

enum TrafficLightDetectionError: Error {
    case modelLoadFailed
    case predictionFailed
    case imageConversionFailed
}

struct DetectedObject: Identifiable {
    let id: UUID
    let label: String
    let confidence: Float
    let boundingBox: CGRect
    let timestamp: Date
}

class TrafficLightDetectionService: ObservableObject {
    @Published var detectedObjects: [DetectedObject] = []
    @Published var debugImage: UIImage?
    
    private var lastDetectionTime = Date()
    private let detectionInterval: TimeInterval = 0.1 // 100ms between detections
    private let objectTimeout: TimeInterval = 0.5 // Remove objects after 0.5s of not being detected
    
    // YOLO model for object detection
    private var visionModel: VNCoreMLModel?
    
    init() {
        setupModel()
    }
    
    private func setupModel() {
        do {
            let config = MLModelConfiguration()
            let model = try YOLOv3TinyFP16(configuration: config)
            visionModel = try VNCoreMLModel(for: model.model)
        } catch {
            print("Failed to create Vision model: \(error)")
        }
    }
    
    // Store the current pixel buffer for drawing
    private var currentPixelBuffer: CVPixelBuffer?
    
    func processFrame(_ pixelBuffer: CVPixelBuffer) {
        // Check if enough time has passed since last detection
        let currentTime = Date()
        guard currentTime.timeIntervalSince(lastDetectionTime) >= detectionInterval else { return }
        lastDetectionTime = currentTime
        
        // Store the pixel buffer for drawing
        currentPixelBuffer = pixelBuffer
        
        // Create and configure the request
        guard let model = visionModel else { return }
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            self?.handleDetectionResults(request: request, error: error)
        }
        request.imageCropAndScaleOption = .scaleFit
        
        // Perform the detection
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        try? handler.perform([request])
        
        // Remove stale objects
        removeStaleObjects()
    }
    
    private func handleDetectionResults(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNRecognizedObjectObservation] else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Process new detections
            var newDetections: [DetectedObject] = []
            
            for observation in results {
                guard let label = observation.labels.first?.identifier,
                      observation.confidence > 0.5 else { continue }
                
                let object = DetectedObject(
                    id: UUID(),
                    label: label,
                    confidence: observation.confidence,
                    boundingBox: observation.boundingBox,
                    timestamp: Date()
                )
                newDetections.append(object)
                
                // Play sound based on object type
                if label.lowercased().contains("traffic light") {
                    SoundManager.shared.playSound(named: "traffic_light")
                } else if label.lowercased().contains("stop sign") {
                    SoundManager.shared.playSound(named: "stop_sign")
                } else if label.lowercased().contains("person") {
                    SoundManager.shared.playSound(named: "person")
                }
            }
            
            self.detectedObjects = newDetections
            
            // Create debug image with bounding boxes and confidence levels
            if !newDetections.isEmpty, let pixelBuffer = self.currentPixelBuffer {
                self.createDebugImage(pixelBuffer: pixelBuffer, detections: newDetections)
            } else {
                self.debugImage = nil
            }
        }
    }
    
    private func createDebugImage(pixelBuffer: CVPixelBuffer, detections: [DetectedObject]) {
        // Create a CIImage from the pixel buffer
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Create a context to render the image
        let context = CIContext()
        
        // Convert CIImage to CGImage
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        // Create a UIImage from the CGImage
        let uiImage = UIImage(cgImage: cgImage)
        
        // Create a graphics context to draw on
        UIGraphicsBeginImageContextWithOptions(uiImage.size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        // Draw the original image
        uiImage.draw(at: .zero)
        
        // Get the current graphics context
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Set up drawing attributes
        context.setLineWidth(3.0)
        
        // Draw bounding boxes and labels for each detection
        for detection in detections {
            // Convert normalized coordinates to image coordinates
            let rect = CGRect(
                x: detection.boundingBox.origin.x * uiImage.size.width,
                y: (1 - detection.boundingBox.origin.y - detection.boundingBox.height) * uiImage.size.height,
                width: detection.boundingBox.width * uiImage.size.width,
                height: detection.boundingBox.height * uiImage.size.height
            )
            
            // Choose color based on object type
            if detection.label.lowercased().contains("traffic light") {
                context.setStrokeColor(UIColor.red.cgColor)
            } else if detection.label.lowercased().contains("stop sign") {
                context.setStrokeColor(UIColor.orange.cgColor)
            } else if detection.label.lowercased().contains("person") {
                context.setStrokeColor(UIColor.yellow.cgColor)
            } else {
                context.setStrokeColor(UIColor.green.cgColor)
            }
            
            // Draw the bounding box
            context.stroke(rect)
            
            // Create label text with confidence level
            let confidencePercentage = Int(detection.confidence * 100)
            let labelText = "\(detection.label) (\(confidencePercentage)%)"
            
            // Set up text attributes
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.white
            ]
            
            // Create a background for the text
            let textSize = (labelText as NSString).size(withAttributes: textAttributes)
            let textRect = CGRect(
                x: rect.origin.x,
                y: rect.origin.y - textSize.height - 5,
                width: textSize.width + 10,
                height: textSize.height + 5
            )
            
            // Draw text background
            context.setFillColor(UIColor.black.withAlphaComponent(0.7).cgColor)
            context.fill(textRect)
            
            // Draw the text
            (labelText as NSString).draw(
                at: CGPoint(x: rect.origin.x + 5, y: rect.origin.y - textSize.height - 2.5),
                withAttributes: textAttributes
            )
        }
        
        // Get the resulting image
        guard let resultImage = UIGraphicsGetImageFromCurrentImageContext() else { return }
        
        // Update the debug image
        self.debugImage = resultImage
    }
    
    private func removeStaleObjects() {
        let currentTime = Date()
        detectedObjects.removeAll { object in
            currentTime.timeIntervalSince(object.timestamp) > objectTimeout
        }
    }
}
