//
//  FirstTimeSetupView.swift
//  CruiseAIios
//
//  Created by Ojas Kandhare on 3/31/25.
//

import SwiftUI

struct FirstTimeSetupView: View {
    @Binding var isShowingSetup: Bool
    @StateObject private var userPreferences = UserPreferencesService.shared
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            // Setup card
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    Text("Setup Your CruiseAI")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.top, 20)
                    
                    // Phone mount illustration
                    Image(systemName: "iphone")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 150, height: 150)
                        )
                    
                    // Mount instructions
                    instructionSection(
                        title: "Mount Your Phone Properly",
                        instructions: [
                            "Attach your phone to a car mount on your dashboard or windshield",
                            "Position the phone so the camera has a clear view of the road ahead",
                            "Ensure the mount is stable and won't move while driving",
                            "The camera should be unobstructed by the dashboard or hood"
                        ],
                        icon: "car.fill"
                    )
                    
                    // Camera positioning
                    instructionSection(
                        title: "Camera Positioning",
                        instructions: [
                            "The camera should be pointed straight ahead at the road",
                            "Avoid direct sunlight on the camera lens",
                            "Make sure the camera view isn't blocked by stickers or dirt",
                            "Test the camera view before driving"
                        ],
                        icon: "camera.fill"
                    )
                    
                    // Warning section
                    VStack(spacing: 15) {
                        Text("IMPORTANT SAFETY WARNING")
                            .font(.title2)
                            .foregroundColor(.red)
                            .bold()
                        
                        Text("If this app causes ANY distraction or disruption while driving, EXIT IMMEDIATELY and email support@driveai.com")
                            .font(.headline)
                            .foregroundColor(.white)
                            .bold()
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                            .shadow(color: .red.opacity(0.5), radius: 5, x: 0, y: 2)
                        
                        Text("This app is specifically designed to help drivers who have previously been in accidents. It provides extra awareness of surroundings but is NOT a replacement for attentive driving.")
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .bold()
                            .multilineTextAlignment(.center)
                            .padding(.top, 5)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red, lineWidth: 2)
                    )
                    
                    // Continue button
                    Button(action: {
                        userPreferences.markFirstTimeSetupAsSeen()
                        withAnimation {
                            isShowingSetup = false
                        }
                    }) {
                        Text("I Understand - Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 30)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding(.horizontal, 20)
                .padding(.vertical, 40)
            }
        }
    }
    
    private func instructionSection(title: String, instructions: [String], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            ForEach(instructions, id: \.self) { instruction in
                HStack(alignment: .top) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .padding(.top, 2)
                    
                    Text(instruction)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct FirstTimeSetupView_Previews: PreviewProvider {
    static var previews: some View {
        FirstTimeSetupView(isShowingSetup: .constant(true))
    }
}
