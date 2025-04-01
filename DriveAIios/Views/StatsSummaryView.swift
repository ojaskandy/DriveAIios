//
//  StatsSummaryView.swift
//  DriveAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import SwiftUI

struct StatsSummaryView: View {
    @ObservedObject var tripDataService: TripDataService
    
    private var totalDistance: Double {
        tripDataService.trips.reduce(0) { (result: Double, trip: Trip) -> Double in
            return result + trip.distance
        }
    }
    
    private var averageSpeed: Double {
        let speeds = tripDataService.trips.map { $0.averageSpeed }
        return speeds.isEmpty ? 0 : speeds.reduce(0) { (result: Double, speed: Double) -> Double in
            return result + speed
        } / Double(speeds.count)
    }
    
    private var averageSafetyScore: Double {
        let scores = tripDataService.trips.map { $0.safetyScore }
        return scores.isEmpty ? 0 : scores.reduce(0) { (result: Double, score: Int) -> Double in
            return result + Double(score)
        } / Double(scores.count)
    }
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Trip Statistics")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                StatBox(
                    icon: "speedometer",
                    value: String(format: "%.1f", averageSpeed),
                    unit: "mph",
                    title: "Avg Speed"
                )
                
                StatBox(
                    icon: "map",
                    value: String(format: "%.1f", totalDistance),
                    unit: "mi",
                    title: "Total Distance"
                )
                
                StatBox(
                    icon: "shield.checkered",
                    value: String(format: "%.0f", averageSafetyScore),
                    unit: "%",
                    title: "Safety Score"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

#Preview {
    StatsSummaryView(tripDataService: TripDataService())
}
