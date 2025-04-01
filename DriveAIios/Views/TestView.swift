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
            
            // Label background
            VStack(alignment: .leading, spacing: 4) {
                // Object type and confidence
                Text("\(object.detectedObject.label) (\(Int(object.detectedObject.confidence * 100))%)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                
                // Distance and speed
                if let speed = object.estimatedApproachSpeed {
                    Text(String(format: "%.1f m • %.1f m/s", distance, speed))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Text(String(format: "%.1f m", distance))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(boxColor.opacity(0.75))
            .cornerRadius(4)
            .offset(y: -30)
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
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.frame
        }
    }
}

#Preview {
    TestView(
        cameraService: CameraService(),
        distanceEstimationService: DistanceEstimationService()
    )
} 