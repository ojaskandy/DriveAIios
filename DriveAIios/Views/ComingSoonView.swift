//
//  ComingSoonView.swift
//  CruiseAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import SwiftUI
import MessageUI

struct ComingSoonView: View {
    @Environment(\.presentationMode) var presentationMode
    
    private let upcomingFeatures = [
        FeatureItem(
            title: "Smart Routing",
            description: "AI-powered route suggestions based on real-time traffic and safety data",
            icon: "map.fill"
        ),
        FeatureItem(
            title: "Voice Commands",
            description: "Hands-free control of all app features while driving",
            icon: "waveform.circle.fill"
        ),
        FeatureItem(
            title: "Weather Integration",
            description: "Adaptive safety recommendations based on weather conditions",
            icon: "cloud.sun.fill"
        ),
        FeatureItem(
            title: "Social Features",
            description: "Share your safe driving achievements with friends",
            icon: "person.2.fill"
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Coming Soon")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Exciting new features on the horizon")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top)
                
                // Feature list
                VStack(spacing: 20) {
                    ForEach(upcomingFeatures) { feature in
                        FeatureCard(
                            title: feature.title,
                            icon: feature.icon,
                            description: feature.description,
                            isGlowing: false
                        ) {
                            // Feature card tap action
                        }
                    }
                }
                
                // Newsletter signup
                VStack(alignment: .leading, spacing: 15) {
                    Text("Want early access?")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Join our beta program to be the first to try these features.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        // Beta program signup action
                    }) {
                        Text("Join Beta Program")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
            }
            .padding()
        }
        .navigationBarTitle("Coming Soon", displayMode: .inline)
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

// Feature item model
struct FeatureItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
}

struct PreviewProvider_ComingSoonView: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ComingSoonView()
        }
    }
}
