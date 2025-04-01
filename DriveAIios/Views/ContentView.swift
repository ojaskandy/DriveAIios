import SwiftUI

struct ContentView: View {
    @StateObject private var locationService = LocationService()
    @StateObject private var cameraService = CameraService()
    @StateObject private var distanceEstimationService = DistanceEstimationService()
    
    var body: some View {
        TabView {
            FSDVisualizationView(
                locationService: locationService,
                cameraService: cameraService,
                distanceEstimationService: distanceEstimationService
            )
            .tabItem {
                Label("FSD", systemImage: "car.fill")
            }
            
            TestView(
                cameraService: cameraService,
                distanceEstimationService: distanceEstimationService
            )
            .tabItem {
                Label("Test", systemImage: "camera.fill")
            }
        }
        .onAppear {
            // Initialize camera once when app starts
            cameraService.checkAuthorizationAndSetup()
        }
        // Handle app lifecycle
        .onChange(of: UIApplication.shared.applicationState) { state in
            switch state {
            case .active:
                // Resume camera when app becomes active
                if !cameraService.isSessionRunning {
                    cameraService.startSession()
                }
            case .background:
                // Stop camera when app goes to background
                cameraService.stopSession()
            default:
                break
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 