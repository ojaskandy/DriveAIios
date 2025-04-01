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

struct DetectedObject {
    let boundingBox: CGRect
    let confidence: Float
    let label: String
    var estimatedDistance: Double? // Optional distance information
}

class TrafficLightDetectionService: ObservableObject {
    @Published var detectedTrafficLights: [DetectedObject] = []
    @Published var isProcessing = false
    @Published var debugImage: UIImage?
    @Published var error: TrafficLightDetectionError?
    
    // CoreML model for object detection
    private var detectionModel: VNCoreMLModel?
    private var lastDetectionTime = Date()
    private let detectionCooldown: TimeInterval = 0.03 // 30ms cooldown between detections for better performance
    
    // Queue for processing frames
    private let processingQueue = DispatchQueue(label: "traffic.light.detection.queue", qos: .userInteractive)
    
    // Confidence threshold for detections
    private let confidenceThreshold: Float = 0.3 // Lower threshold to detect more objects
    
    init() {
        setupModel()
    }
    
    private func setupModel() {
        // Load the YOLOv3TinyFP16 model
        do {
            // First try to find the compiled model
            if let modelURL = Bundle.main.url(forResource: "YOLOv3TinyFP16", withExtension: "mlmodelc") {
                detectionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
                print("✅ Traffic light detection model loaded successfully from compiled model")
            } 
            // If compiled model not found, try the uncompiled model
            else if let modelURL = Bundle.main.url(forResource: "YOLOv3TinyFP16", withExtension: "mlmodel") {
                detectionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
                print("✅ Traffic light detection model loaded successfully from uncompiled model")
            }
            // If model not found in bundle, try the project directory
            else {
                let fileManager = FileManager.default
                let projectDirectory = fileManager.currentDirectoryPath
                let modelPath = "\(projectDirectory)/YOLOv3TinyFP16.mlmodel"
                
                if fileManager.fileExists(atPath: modelPath) {
                    let modelURL = URL(fileURLWithPath: modelPath)
                    detectionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
                    print("✅ Traffic light detection model loaded successfully from project directory")
                } else {
                    print("❌ YOLOv3TinyFP16 model not found in any location")
                    error = .modelLoadFailed
                }
            }
        } catch {
            print("❌ Failed to load YOLOv3TinyFP16 model: \(error)")
            self.error = .modelLoadFailed
        }
    }
    
    // Process a frame from the camera
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        // Skip processing if we're already processing a frame or if the model isn't loaded
        guard !isProcessing, detectionModel != nil else { return }
        
        // Check cooldown to avoid processing too many frames
        let now = Date()
        guard now.timeIntervalSince(lastDetectionTime) >= detectionCooldown else { return }
        
        isProcessing = true
        lastDetectionTime = now
        
        processingQueue.async {
            
            // Convert CMSampleBuffer to CVPixelBuffer
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.error = .imageConversionFailed
                }
                return
            }
            
            // Create a request for object detection
            self.detectObjects(in: pixelBuffer)
        }
    }
    
    private func detectObjects(in pixelBuffer: CVPixelBuffer) {
        guard let model = detectionModel else {
            DispatchQueue.main.async {
                self.isProcessing = false
                self.error = .modelLoadFailed
            }
            return
        }
        
        // Create a Vision request with the model
        let request = VNCoreMLRequest(model: model) { request, error in
            
            if let error = error {
                print("❌ Object detection failed: \(error)")
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.error = .predictionFailed
                }
                return
            }
            
            // Process the results
            self.processResults(request, pixelBuffer: pixelBuffer)
        }
        
        // Configure the request
        request.imageCropAndScaleOption = .scaleFill
        
        // Create a handler and perform the request
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("❌ Failed to perform object detection: \(error)")
            DispatchQueue.main.async {
                self.isProcessing = false
                self.error = .predictionFailed
            }
        }
    }
    
    // List of objects we want to detect
    private let targetObjects = [
        "traffic light", "stop sign", "person", "parking meter",
        "car", "bicycle", "motorcycle", "bus", "train", "truck", "boat"
    ]
    
    private func processResults(_ request: VNRequest, pixelBuffer: CVPixelBuffer) {
        // Get the detection results
        guard let results = request.results as? [VNRecognizedObjectObservation] else {
            DispatchQueue.main.async {
                self.isProcessing = false
            }
            return
        }
        
        // Filter for our target objects with confidence above threshold
        let detectedObjects = results.compactMap { observation -> DetectedObject? in
            // Find the highest confidence label that matches our target objects
            let targetLabel = observation.labels.first { label in
                targetObjects.contains { target in
                    label.identifier.lowercased().contains(target) && 
                    label.confidence >= confidenceThreshold
                }
            }
            
            // Only return objects with sufficient confidence
            guard let label = targetLabel, label.confidence > 0 else {
                return nil
            }
            
            return DetectedObject(
                boundingBox: observation.boundingBox,
                confidence: label.confidence,
                label: label.identifier,
                estimatedDistance: nil
            )
        }
        
        // Log detected objects for debugging
        if !detectedObjects.isEmpty {
            print("Detected \(detectedObjects.count) objects:")
            for object in detectedObjects {
                print("- \(object.label) with confidence \(object.confidence)")
            }
        }
        
        // Create debug visualization
        createDebugVisualization(trafficLights: detectedObjects, pixelBuffer: pixelBuffer)
        
        // Update the UI on the main thread
        DispatchQueue.main.async {
            self.detectedTrafficLights = detectedObjects
            self.isProcessing = false
        }
    }
    
    // Create a debug visualization of the detected objects
    private func createDebugVisualization(trafficLights: [DetectedObject], pixelBuffer: CVPixelBuffer) {
        // Only create visualization if there are objects to show
        guard !trafficLights.isEmpty else {
            // Clear previous debug image if no objects detected
            DispatchQueue.main.async {
                self.debugImage = nil
            }
            return
        }
        
        // Create a transparent overlay for the camera feed
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        let image = UIImage(cgImage: cgImage)
        
        // Create a transparent canvas to draw on
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        
        // Draw a transparent background
        UIColor.clear.setFill()
        UIRectFill(CGRect(origin: .zero, size: image.size))
        
        let context2D = UIGraphicsGetCurrentContext()
        context2D?.setLineWidth(5.0) // Thicker lines for better visibility
        
        // Transform Vision coordinates to image coordinates
        let imageSize = image.size
        
        for trafficLight in trafficLights {
            // Vision's coordinate system has (0,0) at the bottom left
            // UIKit's coordinate system has (0,0) at the top left
            // So we need to flip the y-coordinate
            let boundingBox = trafficLight.boundingBox
            let x = boundingBox.minX * imageSize.width
            let y = (1 - boundingBox.maxY) * imageSize.height
            let width = boundingBox.width * imageSize.width
            let height = boundingBox.height * imageSize.height
            
            let rect = CGRect(x: x, y: y, width: width, height: height)
            
            // Use different colors based on object type
            var boxColor: UIColor
            let label = trafficLight.label.lowercased()
            
            if label.contains("traffic light") {
                boxColor = UIColor.red
            } else if label.contains("stop sign") {
                boxColor = UIColor.orange
            } else if label.contains("person") {
                boxColor = UIColor.yellow
            } else if label.contains("parking meter") {
                boxColor = UIColor.green
            } else if label.contains("car") || label.contains("truck") || label.contains("bus") {
                boxColor = UIColor.blue
            } else if label.contains("bicycle") || label.contains("motorcycle") {
                boxColor = UIColor.purple
            } else if label.contains("train") {
                boxColor = UIColor.brown
            } else if label.contains("boat") {
                boxColor = UIColor.cyan
            } else {
                boxColor = UIColor.magenta
            }
            
            // Draw the bounding box
            context2D?.setStrokeColor(boxColor.cgColor)
            context2D?.setFillColor(boxColor.withAlphaComponent(0.3).cgColor)
            context2D?.addRect(rect)
            context2D?.drawPath(using: .fillStroke)
            
            // Draw label with confidence and distance (if available)
            let confidenceText = String(format: "%.1f%%", trafficLight.confidence * 100)
            var text = "\(trafficLight.label): \(confidenceText)"
            
            // Add distance information if available - make it more prominent
            if let distance = trafficLight.estimatedDistance {
                text += "\nDISTANCE: \(String(format: "%.1f METERS", distance))"
            } else {
                text += "\nCalculating distance..."
            }
            
            // Use larger font for better visibility
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18), // Even larger font
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -3.0 // Thicker stroke for better visibility
            ]
            
            // Calculate text size with potential multiline text
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
            let attributesWithParagraph = attributes.merging([.paragraphStyle: paragraphStyle]) { (_, new) in new }
            
            let textSize = (text as NSString).boundingRect(
                with: CGSize(width: width * 1.5, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributesWithParagraph,
                context: nil
            ).size
            
            // Create a background for the text
            let textRect = CGRect(
                x: x,
                y: y - textSize.height - 5,
                width: textSize.width + 10,
                height: textSize.height + 5
            )
            
            // Draw text background with higher opacity for better readability
            context2D?.setFillColor(boxColor.withAlphaComponent(0.8).cgColor)
            context2D?.fill(textRect)
            
            // Draw multiline text
            (text as NSString).draw(
                with: CGRect(
                    x: x + 5,
                    y: y - textSize.height - 2.5,
                    width: textSize.width,
                    height: textSize.height
                ),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributesWithParagraph,
                context: nil
            )
        }
        
        if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
            DispatchQueue.main.async {
                self.debugImage = newImage
            }
        }
        
        UIGraphicsEndImageContext()
    }
}
