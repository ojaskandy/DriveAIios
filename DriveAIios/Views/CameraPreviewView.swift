//
//  CameraPreviewView.swift
//  DriveAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    class PreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            guard let layer = layer as? AVCaptureVideoPreviewLayer else {
                fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
            }
            return layer
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            videoPreviewLayer.frame = bounds
            updateVideoOrientation()
        }
        
        private func updateVideoOrientation() {
            guard let connection = videoPreviewLayer.connection else { return }
            
            let orientation = UIDevice.current.orientation
            let videoOrientation: AVCaptureVideoOrientation
            
            switch orientation {
            case .portrait: videoOrientation = .portrait
            case .landscapeLeft: videoOrientation = .landscapeRight
            case .landscapeRight: videoOrientation = .landscapeLeft
            case .portraitUpsideDown: videoOrientation = .portraitUpsideDown
            default: videoOrientation = .portrait
            }
            
            if connection.isVideoOrientationSupported &&
                connection.videoOrientation != videoOrientation {
                connection.videoOrientation = videoOrientation
            }
        }
        
        // Add notification observer for device orientation changes
        func setupOrientationObserver(session: AVCaptureSession) {
            NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main) { [weak self] (_: Notification) in
                    self?.updateVideoOrientation()
                }
        }
    }
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        // Ensure the preview layer is properly configured
        if let connection = view.videoPreviewLayer.connection {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
        
        // Setup orientation observer
        view.setupOrientationObserver(session: session)
        
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Frame and orientation updates are handled in PreviewView.layoutSubviews()
    }
}
