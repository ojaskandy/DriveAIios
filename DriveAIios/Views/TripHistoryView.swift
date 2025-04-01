//
//  TripHistoryView.swift
//  DriveAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import SwiftUI
import MapKit
import CoreLocation
import MessageUI

struct TripHistoryView: View {
    @ObservedObject var tripDataService: TripDataService
    @State private var selectedTripId: UUID?
    @State private var showTripDetails = false
    
    var body: some View {
        NavigationView {
            List(tripDataService.trips) { trip in
                NavigationLink(
                    destination: TripDetailView(trip: trip),
                    tag: trip.id,
                    selection: $selectedTripId
                ) {
                    TripRowView(trip: trip)
                }
            }
            .navigationTitle("Trip History")
            .listStyle(InsetGroupedListStyle())
            .withHelpButton()
            .onAppear {
                // Listen for notifications to show trip details
                NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("ShowTripDetails"),
                    object: nil,
                    queue: .main
                ) { notification in
                    if let userInfo = notification.userInfo,
                       let tripId = userInfo["tripId"] as? UUID {
                        // Set the selected trip ID to trigger the navigation
                        selectedTripId = tripId
                    }
                }
            }
        }
    }
}

struct TripRowView: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trip.startTime, style: .date)
                    .font(.headline)
                Spacer()
                Text(String(format: "%.1f mi", trip.distance / 1609.34))
                    .font(.subheadline)
            }
            
            HStack {
                Label(
                    String(format: "%.1f mph", trip.averageSpeed * 2.237),
                    systemImage: "speedometer"
                )
                Spacer()
                Label(
                    "Score: \(trip.safetyScore)",
                    systemImage: "checkmark.shield"
                )
                .foregroundColor(safetyScoreColor)
            }
            .font(.caption)
            
            // Show indicators for dashcam footage and crash detection
            if trip.dashcamFootagePath != nil || trip.hasCrashDetected {
                HStack(spacing: 12) {
                    if trip.dashcamFootagePath != nil {
                        Label("Dashcam", systemImage: "video.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    if trip.hasCrashDetected {
                        Label("Crash Detected", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var safetyScoreColor: Color {
        switch trip.safetyScore {
        case 90...100: return .green
        case 70..<90: return .yellow
        default: return .red
        }
    }
}

// Custom MapView to show route polyline
struct RouteMapView: UIViewRepresentable {
    let trip: Trip
    @Binding var region: MKCoordinateRegion
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.showsUserLocation = false
        
        // Add route polyline
        if trip.route.count > 1 {
            let coordinates = trip.route.map { 
                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            }
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(polyline)
            
            // Add start and end annotations
            if let firstLocation = trip.route.first, let lastLocation = trip.route.last {
                let startAnnotation = MKPointAnnotation()
                startAnnotation.coordinate = CLLocationCoordinate2D(
                    latitude: firstLocation.latitude, 
                    longitude: firstLocation.longitude
                )
                startAnnotation.title = "Start"
                
                let endAnnotation = MKPointAnnotation()
                endAnnotation.coordinate = CLLocationCoordinate2D(
                    latitude: lastLocation.latitude, 
                    longitude: lastLocation.longitude
                )
                endAnnotation.title = "End"
                
                mapView.addAnnotations([startAnnotation, endAnnotation])
            }
            
            // Fit map to show the entire route
            mapView.setVisibleMapRect(
                polyline.boundingMapRect,
                edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20),
                animated: false
            )
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.region = region
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RouteMapView
        
        init(_ parent: RouteMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !annotation.isKind(of: MKUserLocation.self) else { return nil }
            
            let identifier = "TripPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            if let markerView = annotationView as? MKMarkerAnnotationView {
                if annotation.title == "Start" {
                    markerView.markerTintColor = .green
                    markerView.glyphImage = UIImage(systemName: "flag.fill")
                } else if annotation.title == "End" {
                    markerView.markerTintColor = .red
                    markerView.glyphImage = UIImage(systemName: "flag.checkered")
                }
            }
            
            return annotationView
        }
    }
}

struct TripDetailView: View {
    let trip: Trip
    @State private var region: MKCoordinateRegion
    @State private var isPlayingDashcam = false
    @State private var isPlayingCrashFootage = false
    
    init(trip: Trip) {
        self.trip = trip
        let firstLocation = trip.route.first
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: firstLocation?.latitude ?? 0,
                longitude: firstLocation?.longitude ?? 0
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Use custom map view to show route
                RouteMapView(trip: trip, region: $region)
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .overlay(alignment: .bottomTrailing) {
                        Button(action: centerMapOnTripStart) {
                            Image(systemName: "location.fill")
                                .font(.title2)
                                .padding(10)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .padding()
                    }
                
                VStack(spacing: 20) {
                    tripStatistics
                    
                    // Dashcam footage section
                    if trip.dashcamFootagePath != nil {
                        dashcamFootageSection
                    }
                    
                    // Crash detection section
                    if trip.hasCrashDetected {
                        crashDetectionSection
                    }
                    
                    incidentsList
                }
                .padding()
                
                // Share button
                Button(action: shareTrip) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Trip Details")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle(trip.startTime.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
        .withHelpButton()
    }
    
    // Share trip details
    private func shareTrip() {
        // Format trip details as text
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let startTimeStr = formatter.string(from: trip.startTime)
        
        // Calculate trip duration
        let tripDuration = trip.endTime.timeIntervalSince(trip.startTime)
        let hours = Int(tripDuration) / 3600
        let minutes = (Int(tripDuration) % 3600) / 60
        let durationStr = "\(hours)h \(minutes)m"
        
        let shareText = """
        Trip Summary:
        Date: \(startTimeStr)
        Duration: \(durationStr)
        Distance: \(String(format: "%.1f miles", trip.distance / 1609.34))
        Average Speed: \(String(format: "%.1f mph", trip.averageSpeed * 2.237))
        Max Speed: \(String(format: "%.1f mph", trip.maxSpeed * 2.237))
        Safety Score: \(trip.safetyScore)/100
        Incidents: \(trip.incidents.count)
        
        Shared from CruiseAI
        """
        
        // Create activity view controller
        let activityViewController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        // Present the view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    private var tripStatistics: some View {
        VStack(spacing: 12) {
            Text("Trip Statistics")
                .font(.title2)
                .fontWeight(.bold)
            
            // Trip time information
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "clock")
                        Text("Start: \(trip.startTime.formatted(date: .omitted, time: .shortened))")
                    }
                    HStack {
                        Image(systemName: "clock.fill")
                        Text("End: \(trip.endTime.formatted(date: .omitted, time: .shortened))")
                    }
                }
                
                Spacer()
                
                // Trip duration
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Duration")
                        .font(.headline)
                    
                    let duration = trip.endTime.timeIntervalSince(trip.startTime)
                    let hours = Int(duration) / 3600
                    let minutes = (Int(duration) % 3600) / 60
                    Text("\(hours)h \(minutes)m")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Main statistics
            HStack(spacing: 20) {
                StatisticView(
                    title: "Distance",
                    value: String(format: "%.1f mi", trip.distance / 1609.34),
                    icon: "map"
                )
                
                StatisticView(
                    title: "Avg Speed",
                    value: String(format: "%.1f mph", trip.averageSpeed * 2.237),
                    icon: "speedometer"
                )
                
                StatisticView(
                    title: "Safety",
                    value: "\(trip.safetyScore)",
                    icon: "checkmark.shield"
                )
            }
        }
    }
    
    private var dashcamFootageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dashcam Footage")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack {
                // Video player placeholder
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                        .aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(12)
                    
                    if isPlayingDashcam {
                        // Simulated video player
                        VStack {
                            Text("Playing Dashcam Footage")
                                .foregroundColor(.white)
                                .padding()
                            
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        }
                    } else {
                        // Play button overlay
                        Button(action: {
                            isPlayingDashcam.toggle()
                        }) {
                            Image(systemName: "play.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .padding(20)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                    }
                }
                
                // Video details
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.dashcamFootagePath ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("5 minutes • 720p")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Download button
                    Button(action: {
                        // In a real app, this would download the footage
                    }) {
                        Image(systemName: "arrow.down.circle")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
    
    private var crashDetectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Crash Detection")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            VStack(spacing: 12) {
                // Crash details
                HStack(alignment: .top) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                        .padding(.trailing, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Crash Detected")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        if let timestamp = trip.crashTimestamp {
                            Text("Time: \(timestamp.formatted(date: .abbreviated, time: .standard))")
                                .font(.subheadline)
                        }
                        
                        Text("Sudden deceleration detected. Emergency services were notified.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                
                // Crash footage section
                if trip.crashFootagePath != nil {
                    VStack {
                        // Video player placeholder
                        ZStack {
                            Rectangle()
                                .fill(Color.black)
                                .aspectRatio(16/9, contentMode: .fit)
                                .cornerRadius(12)
                            
                            if isPlayingCrashFootage {
                                // Simulated video player
                                VStack {
                                    Text("Playing Crash Footage")
                                        .foregroundColor(.white)
                                        .padding()
                                    
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.5)
                                }
                            } else {
                                // Play button overlay
                                Button(action: {
                                    isPlayingCrashFootage.toggle()
                                }) {
                                    Image(systemName: "play.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.white)
                                        .padding(20)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                }
                            }
                        }
                        
                        // Video details
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(trip.crashFootagePath ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("4 minutes • 720p")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Download button
                            Button(action: {
                                // In a real app, this would download the footage
                            }) {
                                Image(systemName: "arrow.down.circle")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
    
    private var incidentsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Incidents")
                .font(.title2)
                .fontWeight(.bold)
            
            if trip.incidents.isEmpty {
                Text("No incidents recorded")
                    .foregroundColor(.secondary)
            } else {
                ForEach(trip.incidents) { incident in
                    IncidentRow(incident: incident)
                }
            }
        }
    }
    
    private func centerMapOnTripStart() {
        if let firstLocation = trip.route.first {
            withAnimation {
                region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: firstLocation.latitude,
                        longitude: firstLocation.longitude
                    ),
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
        }
    }
}

struct StatisticView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct IncidentRow: View {
    let incident: Incident
    
    var body: some View {
        HStack {
            Image(systemName: incidentIcon)
                .foregroundColor(incidentColor)
            VStack(alignment: .leading) {
                Text(incident.type.rawValue.capitalized)
                    .font(.headline)
                Text(incident.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
    
    private var incidentIcon: String {
        switch incident.type {
        case .speedingViolation: return "exclamationmark.triangle"
        case .suddenBraking: return "exclamationmark.circle"
        case .suddenAcceleration: return "arrow.up.circle"
        case .trafficLightDetection: return "exclamationmark.triangle.fill"
        case .trafficViolation: return "xmark.circle"
        case .crash: return "car.fill"
        }
    }
    
    private var incidentColor: Color {
        switch incident.type {
        case .speedingViolation: return .red
        case .suddenBraking: return .orange
        case .suddenAcceleration: return .yellow
        case .trafficLightDetection: return .blue
        case .trafficViolation: return .purple
        case .crash: return .red
        }
    }
}
