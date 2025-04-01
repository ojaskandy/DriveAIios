//
//  ShareTripPopupView.swift
//  CruiseAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import SwiftUI

struct ShareTripPopupView: View {
    @Binding var isShowingPopup: Bool
    let tripSummary: TripSummary
    @Binding var selectedTab: Int
    let tripId: UUID?
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isShowingPopup = false
                    }
                }
            
            // Popup card
            VStack(spacing: 25) {
                // Header
                Text("Trip Completed!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                // Trip summary
                VStack(spacing: 15) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Distance")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f mi", tripSummary.distance / 1609.34))
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Avg. Speed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f mph", tripSummary.averageSpeed * 2.237))
                                .font(.headline)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Max Speed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f mph", tripSummary.maxSpeed * 2.237))
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Duration")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if let start = tripSummary.startTime, let end = tripSummary.endTime {
                                Text(formatDuration(from: start, to: end))
                                    .font(.headline)
                            } else {
                                Text("--")
                                    .font(.headline)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(15)
                
                // Share button
                Button(action: {
                    shareTrip()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Trip")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 5)
                }
                
                // View Details button
                Button(action: {
                    withAnimation {
                        isShowingPopup = false
                        
                        // Navigate to the History tab (index 3)
                        selectedTab = 3
                        
                        // Post notification with trip ID to show details
                        if let id = tripId {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ShowTripDetails"),
                                object: nil,
                                userInfo: ["tripId": id]
                            )
                        }
                    }
                }) {
                    Text("View Details")
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                // Close button
                Button(action: {
                    withAnimation {
                        isShowingPopup = false
                    }
                }) {
                    Text("Close")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 5)
            }
            .padding(30)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(.horizontal, 30)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    private func formatDuration(from start: Date, to end: Date) -> String {
        let duration = end.timeIntervalSince(start)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func shareTrip() {
        // Format trip data for sharing
        let tripText = """
        My CruiseAI Trip:
        
        Distance: \(String(format: "%.1f mi", tripSummary.distance / 1609.34))
        Average Speed: \(String(format: "%.1f mph", tripSummary.averageSpeed * 2.237))
        Max Speed: \(String(format: "%.1f mph", tripSummary.maxSpeed * 2.237))
        """
        
        // Create activity view controller
        let activityVC = UIActivityViewController(activityItems: [tripText], applicationActivities: nil)
        
        // Present the controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
        
        // Close popup after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isShowingPopup = false
        }
    }
}

struct ShareTripPopupView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleTrip = TripSummary(
            distance: 5000,
            averageSpeed: 15,
            maxSpeed: 25,
            startTime: Date().addingTimeInterval(-1800),
            endTime: Date()
        )
        
        ShareTripPopupView(
            isShowingPopup: .constant(true),
            tripSummary: sampleTrip,
            selectedTab: .constant(0),
            tripId: UUID()
        )
    }
}
