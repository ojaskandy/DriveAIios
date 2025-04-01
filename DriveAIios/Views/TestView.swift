import SwiftUI
import AVFoundation

struct TestView: View {
    @ObservedObject var cameraService: CameraService
    @ObservedObject var distanceEstimationService: DistanceEstimationService
    @State private var showSettings = false
    @State private var showHelp = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera preview
                if cameraService.isSessionRunning {
                    CameraPreview(session: cameraService.session)
                        .ignoresSafeArea()
                } else {
                    Color.black
                        .ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Starting camera...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                
                // Object detection overlay
                ForEach(distanceEstimationService.trackedObjects, id: \.id) { object in
                    if let distance = object.estimatedDistance {
                        ObjectDetectionBox(
                            object: object,
                            distance: distance,
                            screenSize: geometry.size
                        )
                    }
                }
                
                // Status overlays
                VStack {
                    // Top status bar
                    statusBar
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(.systemBackground).opacity(0.85))
                                .shadow(color: .black.opacity(0.2), radius: 10)
                        )
                        .padding()
                    
                    Spacer()
                    
                    // Bottom controls
                    bottomControls
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(.systemBackground).opacity(0.85))
                                .shadow(color: .black.opacity(0.2), radius: 10)
                        )
                        .padding()
                }
            }
        }
        .background(Color.black)
        .sheet(isPresented: $showSettings) {
            NavigationView {
                SettingsView(locationService: LocationService(), cameraService: cameraService)
            }
        }
        .sheet(isPresented: $showHelp) {
            NavigationView {
                HowItWorksView()
            }
        }
    }
    
    private var statusBar: some View {
        HStack(spacing: 20) {
            // Object count with icon
            HStack(spacing: 8) {
                Image(systemName: "cube.fill")
                    .foregroundColor(.blue)
                Text("\(distanceEstimationService.trackedObjects.count)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text("Objects")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 20)
            
            // Closest object distance
            if distanceEstimationService.closestObjectDistance < Double.infinity {
                HStack(spacing: 8) {
                    Image(systemName: "ruler.fill")
                        .foregroundColor(.orange)
                    Text(String(format: "%.1f m", distanceEstimationService.closestObjectDistance))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("Closest")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Settings button
            Button(action: { showSettings = true }) {
                Image(systemName: "gear")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
            }
        }
        .padding()
    }
    
    private var bottomControls: some View {
        HStack(spacing: 20) {
            // Help button
            Button(action: { showHelp = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle.fill")
                    Text("Help")
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(20)
            }
            
            Spacer()
            
            // Camera controls
            HStack(spacing: 16) {
                Button(action: {
                    if cameraService.isSessionRunning {
                        cameraService.stopSession()
                    } else {
                        cameraService.startSession()
                    }
                }) {
                    Image(systemName: cameraService.isSessionRunning ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(cameraService.isSessionRunning ? .red : .green)
                }
            }
        }
        .padding()
    }
}

struct ObjectDetectionBox: View {
    let object: TrackedObject
    let distance: Double
    let screenSize: CGSize
    
    private var boxColor: Color {
        switch object.collisionRisk {
        case .none: return .green
        case .low: return .yellow
        case .medium: return .orange
        case .high, .imminent: return .red
        }
    }
    
    var body: some View {
        let box = object.detectedObject.boundingBox
        let rect = CGRect(
            x: box.minX * screenSize.width,
            y: box.minY * screenSize.height,
            width: box.width * screenSize.width,
            height: box.height * screenSize.height
        )
        
        ZStack(alignment: .topLeading) {
            // Bounding box
            RoundedRectangle(cornerRadius: 4)
                .stroke(boxColor, lineWidth: 2)
                .frame(width: rect.width, height: rect.height)
            
            // Minimal label
            Text("\(object.detectedObject.label) \(Int(object.detectedObject.confidence * 100))%")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(boxColor.opacity(0.75))
                .cornerRadius(2)
                .offset(y: -16)
        }
        .position(
            x: rect.midX,
            y: rect.midY
        )
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.contentsGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        // Add constraints to ensure proper sizing
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
            
            // Update video orientation based on device orientation
            if let connection = previewLayer.connection {
                let orientation = UIDevice.current.orientation
                let videoOrientation: AVCaptureVideoOrientation
                
                switch orientation {
                case .portrait: videoOrientation = .portrait
                case .landscapeLeft: videoOrientation = .landscapeRight
                case .landscapeRight: videoOrientation = .landscapeLeft
                case .portraitUpsideDown: videoOrientation = .portraitUpsideDown
                default: videoOrientation = .portrait
                }
                
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = videoOrientation
                }
            }
        }
    }
}

#Preview {
    TestView(
        cameraService: CameraService(),
        distanceEstimationService: DistanceEstimationService()
    )
} 