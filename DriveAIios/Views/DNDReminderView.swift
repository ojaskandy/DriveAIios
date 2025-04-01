//
//  DNDReminderView.swift
//  DriveAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import SwiftUI

struct DNDReminderView: View {
    @Binding var isShowingReminder: Bool
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            // Reminder card
            VStack(spacing: 20) {
                // Icon
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                
                // Title
                Text("Please Disable Do Not Disturb")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                // Description
                Text("For the best experience with audio alerts and conditioning, please disable Do Not Disturb mode on your device.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Button
                Button(action: {
                    withAnimation {
                        isShowingReminder = false
                    }
                }) {
                    Text("Got it")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            }
            .padding(25)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal, 30)
        }
        .onAppear {
            // Auto-dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isShowingReminder = false
                }
            }
        }
    }
}

struct DNDReminderView_Previews: PreviewProvider {
    static var previews: some View {
        DNDReminderView(isShowingReminder: .constant(true))
    }
}
