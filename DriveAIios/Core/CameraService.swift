//
//  CameraService.swift
//  DriveAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import AVFoundation
import SwiftUI
import Combine

class CameraService: NSObject, ObservableObject {
    @Published var isSessionRunning = false
    @Published var error: CameraError?
    
    let session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
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
    
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            
            // Setup camera input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                           for: .video,
                                                           position: .back) else {
                DispatchQueue.main.async {
                    self.error = .cameraUnavailable
                }
                return
            }
            
            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                if self.session.canAddInput(videoDeviceInput) {
                    self.session.addInput(videoDeviceInput)
                    self.videoDeviceInput = videoDeviceInput
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
            } else {
                DispatchQueue.main.async {
                    self.error = .cannotAddOutput
                }
                return
            }
            
            self.session.commitConfiguration()
            
            // Start running session after configuration is committed with a slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = self.session.isRunning
                }
            }
        }
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.stopRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
            }
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
        // Process frame here
    }
}

enum CameraError: Error {
    case cameraUnavailable
    case cannotAddInput
    case cannotAddOutput
}
