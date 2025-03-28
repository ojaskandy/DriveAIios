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
            return AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.videoPreviewLayer.connection?.videoOrientation = .portrait
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Update frame and orientation when needed
        DispatchQueue.main.async {
            uiView.videoPreviewLayer.frame = uiView.bounds
            uiView.videoPreviewLayer.connection?.videoOrientation = .portrait
        }
    }
}