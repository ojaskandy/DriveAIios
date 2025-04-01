//
//  AnalyticsView.swift
//  DriveAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import SwiftUI
import Charts
import MessageUI

struct AnalyticsView: View {
    @ObservedObject var tripDataService: TripDataService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    overallStatistics
                    safetyScoreChart
                    incidentBreakdown
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .withHelpButton()
        }
    }
    
    private var overallStatistics: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overall Statistics")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatBox(
                    icon: "map",
                    value: String(format: "%.1f", tripDataService.getTotalDistance() / 1609.34),
                    unit: "mi",
                    title: "Total Distance"
                )
                
                StatBox(
                    icon: "speedometer",
                    value: String(format: "%.1f", tripDataService.getAverageSpeedForLastNTrips(tripDataService.trips.count) * 2.237),
                    unit: "mph",
                    title: "Average Speed"
                )
                
                StatBox(
                    icon: "exclamationmark.triangle",
                    value: String(format: "%d", tripDataService.getTotalIncidents()),
                    unit: "",
                    title: "Total Incidents"
                )
                
                if let commonIncident = tripDataService.getMostCommonIncidentType() {
                    StatBox(
                        icon: "exclamationmark.triangle.fill",
                        value: commonIncident.rawValue.capitalized,
                        unit: "",
                        title: "Common Incident"
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var safetyScoreChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Safety Score Trend")
                .font(.title2)
                .fontWeight(.bold)
            
            Chart(tripDataService.trips) { trip in
                LineMark(
                    x: .value("Date", trip.startTime),
                    y: .value("Score", trip.safetyScore)
                )
                .foregroundStyle(Color.blue)
                
                PointMark(
                    x: .value("Date", trip.startTime),
                    y: .value("Score", trip.safetyScore)
                )
                .foregroundStyle(Color.blue)
            }
            .frame(height: 200)
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(position: .bottom) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var incidentBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Incident Breakdown")
                .font(.title2)
                .fontWeight(.bold)
            
            let incidents = tripDataService.trips.flatMap { $0.incidents }
            let incidentTypes = Dictionary(grouping: incidents, by: { $0.type })
                .mapValues { $0.count }
            
            Chart(Array(incidentTypes), id: \.key) { type, count in
                BarMark(
                    x: .value("Count", count),
                    y: .value("Type", type.rawValue.capitalized)
                )
                .foregroundStyle(incidentColor(for: type))
            }
            .frame(height: 150)
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func incidentColor(for type: IncidentType) -> Color {
        switch type {
        case .speedingViolation: return .red
        case .suddenBraking: return .orange
        case .suddenAcceleration: return .yellow
        case .trafficLightDetection: return .blue
        case .trafficViolation: return .purple
        case .crash: return .red
        }
    }
}
