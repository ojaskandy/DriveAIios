//
//  CameraService.swift
//  DriveAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import AVFoundation
import SwiftUI
import Combine
import Vision
import CoreML

class CameraService: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var isSessionRunning = false
    @Published var error: CameraError?
    @Published var isTrafficLightDetectionEnabled = true
    
    let session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    // Traffic light detection service
    let trafficLightDetectionService = TrafficLightDetectionService()
    
    // Frame processing settings
    private var lastProcessingTime = Date()
    private let processingInterval: TimeInterval = 0.05 // Process frames every 50ms for more responsive detection
    
    override init() {
        super.init()
    }
    
    func initializeSession() {
        // Request camera permission explicitly first
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self = self else { return }
            
            if granted {
                print("✅ Camera access granted")
                self.sessionQueue.async {
                    self.setupSession()
                }
            } else {
                print("❌ Camera access denied")
                DispatchQueue.main.async {
                    self.error = .cameraUnavailable
                }
            }
        }
    }
    
    // Check camera authorization status and initialize if already authorized
    func checkAuthorizationAndSetup() {
        // Check if we've already set up the session
        if session.isRunning {
            return
        }
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Already authorized, setup session
            print("✅ Camera already authorized")
            sessionQueue.async { [weak self] in
                self?.setupSession()
            }
        case .notDetermined:
            // Request authorization
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self = self else { return }
                
                if granted {
                    print("✅ Camera access granted")
                    self.sessionQueue.async {
                        self.setupSession()
                    }
                } else {
                    print("❌ Camera access denied")
                    DispatchQueue.main.async {
                        self.error = .cameraUnavailable
                    }
                }
            }
        case .denied, .restricted:
            // Camera access denied or restricted
            DispatchQueue.main.async { [weak self] in
                self?.error = .cameraUnavailable
            }
        @unknown default:
            break
        }
    }
    
    private func setupSession() {
        guard !self.session.isRunning else { return }
        
        self.session.beginConfiguration()
        self.session.sessionPreset = .medium // Lower resolution for better performance
        
        // Setup camera input - try to get the back camera first
        // First try to get the back camera
        if let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            setupCameraDevice(backCamera)
            print("✅ Using back camera")
        } 
        // If back camera is not available, try the front camera
        else if let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            setupCameraDevice(frontCamera)
            print("⚠️ Back camera unavailable, using front camera")
        }
        // If no camera is available, report an error
        else {
            DispatchQueue.main.async {
                self.error = .cameraUnavailable
                print("❌ No camera available")
            }
            return
        }
    }
    
    private func setupCameraDevice(_ videoDevice: AVCaptureDevice) {
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if self.session.canAddInput(videoDeviceInput) {
                self.session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                // Configure camera settings
                configureCamera(videoDevice)
            }
        } catch {
            DispatchQueue.main.async {
                self.error = .cannotAddInput
            }
            return
        }
        
        // Setup video output
        if self.session.canAddOutput(self.videoDataOutput) {
            self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32BGRA)]
            self.videoDataOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            self.session.addOutput(self.videoDataOutput)
            
            // Set video orientation
            if let connection = self.videoDataOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
                
                // Enable video stabilization if available
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
        } else {
            DispatchQueue.main.async {
                self.error = .cannotAddOutput
            }
            return
        }
        
        self.session.commitConfiguration()
        
        // Start running session AFTER configuration is fully committed
        startSession()
    }
    
    // Configure optimal camera settings
    private func configureCamera(_ device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            
            // Set frame rate range optimal for processing
            // Higher frame rate for smoother camera feed
            device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 60)
            device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 60)
            
            // Set focus mode to continuous auto focus
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            
            // Set exposure mode to continuous auto exposure
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error configuring camera: \(error)")
        }
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Only start if not already running
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = self.session.isRunning
                    print("✅ Camera session started: \(self.isSessionRunning)")
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Only stop if currently running
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = self.session.isRunning
                    print("✅ Camera session stopped")
                }
            }
        }
    }
    
    // Pause the camera session without fully stopping it
    // This is useful when navigating between tabs
    func pauseSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Only pause if currently running
            if self.session.isRunning {
                // Instead of stopping the session, we'll just pause the delegate
                self.videoDataOutput.setSampleBufferDelegate(nil, queue: nil)
                DispatchQueue.main.async {
                    print("⏸️ Camera session paused")
                }
            }
        }
    }
    
    // Resume the camera session after pausing
    func resumeSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Make sure the session is running
            if !self.session.isRunning {
                self.session.startRunning()
            }
            
            // Restore the sample buffer delegate
            self.videoDataOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
                print("▶️ Camera session resumed")
            }
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isTrafficLightDetectionEnabled else { return }
        
        // Process frames at a reasonable interval to avoid overloading
        let currentTime = Date()
        guard currentTime.timeIntervalSince(lastProcessingTime) >= processingInterval else { return }
        lastProcessingTime = currentTime
        
        // Extract CVPixelBuffer from CMSampleBuffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("❌ Failed to get pixel buffer from sample buffer")
            return
        }
        
        // Process the frame for traffic light detection
        trafficLightDetectionService.processFrame(pixelBuffer)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Handle dropped frames if needed
        print("⚠️ Frame dropped")
    }
}

enum CameraError: Error {
    case cameraUnavailable
    case cannotAddInput
    case cannotAddOutput
}
