//
//  SplashScreenView.swift
//  CruiseAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var carPosition = -UIScreen.main.bounds.width / 2
    @State private var isAnimationComplete = false
    @Binding var isShowingSplash: Bool
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.5)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // CruiseAI Logo and Text
                Text("CruiseAI")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                
                Spacer()
                
                // Car animation
                ZStack {
                    // Road
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(height: 10)
                    
                    // Car
                    Image(systemName: "car.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .offset(x: carPosition)
                        .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                }
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            // Animate the car moving from left to right
            withAnimation(.easeInOut(duration: 2.0)) {
                carPosition = UIScreen.main.bounds.width / 2 + 50
            }
            
            // After animation completes, move to main app
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    isAnimationComplete = true
                    isShowingSplash = false
                }
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView(isShowingSplash: .constant(true))
    }
}
