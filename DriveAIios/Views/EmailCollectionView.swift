//
//  EmailCollectionView.swift
//  CruiseAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import SwiftUI
import MessageUI
import Foundation

struct EmailCollectionView: View {
    @Binding var isShowingEmailCollection: Bool
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var isEmailValid = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSubmitting = false
    
    // Email validation regex
    private let emailPredicate = NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.5)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    // CruiseAI logo image
                    Image("CruiseAILogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                    
                    Text("Welcome to CruiseAI")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Please provide your email to get started")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                    // Email input
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email Address")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("your.email@example.com", text: $email)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.black) // Ensure text is visible against white background
                                .cornerRadius(10)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            .onChange(of: email) { newValue in
                                isEmailValid = emailPredicate.evaluate(with: newValue)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number (Optional)")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("(123) 456-7890", text: $phoneNumber)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.black) // Ensure text is visible against white background
                                .cornerRadius(10)
                                .keyboardType(.phonePad)
                        }
                    
                    // Submit button
                    Button(action: submitInformation) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        } else {
                            Text("Get Started")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isEmailValid ? Color.green : Color.gray)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(!isEmailValid || isSubmitting)
                    
                    // Skip button (only enabled if email is valid)
                    Button(action: {
                        if isEmailValid {
                            isShowingEmailCollection = false
                        }
                    }) {
                        Text("Skip for now")
                            .font(.subheadline)
                            .foregroundColor(isEmailValid ? .white.opacity(0.8) : .white.opacity(0.3))
                            .underline(isEmailValid)
                    }
                    .disabled(!isEmailValid)
                    .padding(.top, 10)
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Privacy note
                Text("Your information will only be used to send you updates about CruiseAI. We will never share your information with third parties.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
            }
            .padding(.top, 50)
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .withHelpButton()
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Thank You"),
                message: Text(alertMessage),
                dismissButton: .default(Text("Continue")) {
                    isShowingEmailCollection = false
                }
            )
        }
    }
    
    private func submitInformation() {
        guard isEmailValid else { return }
        
        isSubmitting = true
        
        // Use the UserCommunicationService to send the information
        UserCommunicationService.shared.sendUserInformation(
            email: email,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber
        )
        
        // Save to UserPreferences
        UserPreferencesService.shared.saveUserEmail(
            email,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber
        )
        
        // Show success message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alertMessage = "Thank you for providing your information. You're all set to start using CruiseAI!"
            showingAlert = true
            isSubmitting = false
            
            // Automatically show How It Works after email collection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: NSNotification.Name("ShowHowItWorks"), object: nil)
            }
        }
    }
}

struct EmailCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        EmailCollectionView(isShowingEmailCollection: .constant(true))
    }
}
