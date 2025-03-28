//
//  TripHistoryView.swift
//  DriveAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import SwiftUI
import MapKit

struct TripHistoryView: View {
    @ObservedObject var tripDataService: TripDataService
    
    var body: some View {
        NavigationView {
            List(tripDataService.trips) { trip in
                NavigationLink(destination: TripDetailView(trip: trip)) {
                    TripRowView(trip: trip)
                }
            }
            .navigationTitle("Trip History")
            .listStyle(InsetGroupedListStyle())
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

struct TripDetailView: View {
    let trip: Trip
    @State private var region: MKCoordinateRegion
    
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
                Map(coordinateRegion: $region)
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding(.horizontal)
                
                VStack(spacing: 20) {
                    tripStatistics
                    incidentsList
                }
                .padding()
            }
        }
        .navigationTitle(trip.startTime.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var tripStatistics: some View {
        VStack(spacing: 12) {
            Text("Trip Statistics")
                .font(.title2)
                .fontWeight(.bold)
            
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
        case .laneDeparture: return "arrow.left.and.right"
        case .trafficViolation: return "xmark.circle"
        }
    }
    
    private var incidentColor: Color {
        switch incident.type {
        case .speedingViolation: return .red
        case .suddenBraking: return .orange
        case .suddenAcceleration: return .yellow
        case .laneDeparture: return .blue
        case .trafficViolation: return .purple
        }
    }
}