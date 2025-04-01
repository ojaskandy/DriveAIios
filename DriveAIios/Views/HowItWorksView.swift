//
//  HowItWorksView.swift
//  CruiseAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import SwiftUI
import MessageUI

struct HowItWorksView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // List of features explaining how CruiseAI works
    private let features = [
        FeatureExplanation(
            title: "AI-Powered Recognition",
            description: "CruiseAI conditions new drivers to recognize important road elements like traffic lights, stop signs, and pedestrians.",
            icon: "brain.head.profile"
        ),
        FeatureExplanation(
            title: "Speed Monitoring",
            description: "Get real-time alerts when you exceed the speed limit to help maintain safe driving habits.",
            icon: "speedometer"
        ),
        FeatureExplanation(
            title: "Trip Details",
            description: "View comprehensive trip information and easily share your routes with friends and family.",
            icon: "map.fill"
        ),
        FeatureExplanation(
            title: "Drive History",
            description: "Access an archive of your past drives to track your progress and improvement over time.",
            icon: "clock.fill"
        ),
        FeatureExplanation(
            title: "Drive Score",
            description: "Receive a personalized driving score based on your habits to help you become a safer driver.",
            icon: "chart.bar.fill"
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("How It Works")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("CruiseAI is an intelligent AI-powered tool that transforms your smartphone into a driving assistant.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top)
                
                // Important note about DND
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        
                        Text("Important Note")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Text("Please disable Do Not Disturb (DND) mode to allow for sound immersion and conditioning. This ensures you'll receive all audio alerts while driving.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(15)
                
                // Feature list
                VStack(spacing: 20) {
                    Text("Current Features")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach(features) { feature in
                        FeatureExplanationCard(feature: feature)
                    }
                }
                
                // Getting started
                VStack(alignment: .leading, spacing: 15) {
                    Text("Getting Started")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        StepView(number: 1, text: "Mount your phone securely on your dashboard or windshield")
                        StepView(number: 2, text: "Ensure your phone has a clear view of the road ahead")
                        StepView(number: 3, text: "Press the glowing 'Start Drive' button to begin monitoring")
                        StepView(number: 4, text: "Drive safely and listen for audio alerts")
                        StepView(number: 5, text: "Press 'Stop Drive' when you've reached your destination")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
            }
            .padding()
        }
        .navigationBarTitle("How It Works", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        })
        .withHelpButton()
    }
}

// Feature explanation model
struct FeatureExplanation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
}

// Feature explanation card view
struct FeatureExplanationCard: View {
    let feature: FeatureExplanation
    
    var body: some View {
        HStack(spacing: 15) {
            // Icon
            Image(systemName: feature.icon)
                .font(.system(size: 30))
                .foregroundColor(.blue)
                .frame(width: 60, height: 60)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            // Text content
            VStack(alignment: .leading, spacing: 5) {
                Text(feature.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Step view for getting started section
struct StepView: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Step number
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(Color.blue)
                .clipShape(Circle())
            
            // Step description
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct HowItWorksView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HowItWorksView()
        }
    }
}
