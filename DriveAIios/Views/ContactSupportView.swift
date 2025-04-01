//
//  ContactSupportView.swift
//  CruiseAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import SwiftUI
import MessageUI

struct ContactSupportView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isShowingMailView = false
    @State private var mailResult: Result<MFMailComposeResult, NSError>? = nil
    @State private var alertMessage = ""
    @State private var showingAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text("Contact Support")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 5)
                
                Text("We're here to help! Please reach out with any questions, feedback, or issues you're experiencing with CruiseAI.")
                    .foregroundColor(.secondary)
                
                // Contact information
                contactInfoSection
                
                // Email button
                emailButton
                
                // FAQ section
                faqSection
            }
            .padding()
        }
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Email Result"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $isShowingMailView) {
            MailView(result: $mailResult, supportEmail: "ojaskandy@gmail.com")
        }
        .onChange(of: mailResult) { result in
            if let result = result {
                switch result {
                case .success(let mailComposeResult):
                    switch mailComposeResult {
                    case .cancelled:
                        alertMessage = "Email cancelled"
                    case .saved:
                        alertMessage = "Email saved as draft"
                    case .sent:
                        alertMessage = "Email sent successfully!"
                    case .failed:
                        alertMessage = "Email failed to send"
                    @unknown default:
                        alertMessage = "Unknown result"
                    }
                case .failure(let error):
                    alertMessage = "Failed to send email: \(error.localizedDescription)"
                }
                showingAlert = true
            }
        }
    }
    
    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Contact Information")
                .font(.headline)
            
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.blue)
                    .frame(width: 25)
                Text("ojaskandy@gmail.com")
            }
            
            Divider()
                .padding(.vertical, 5)
            
            Text("Response Time")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("We typically respond to all inquiries within 24-48 hours during business days.")
                .foregroundColor(.secondary)
                .font(.subheadline)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var emailButton: some View {
        Button(action: {
            if MFMailComposeViewController.canSendMail() {
                isShowingMailView = true
            } else {
                // Copy email to clipboard if mail isn't available
                UIPasteboard.general.string = "ojaskandy@gmail.com"
                alertMessage = "Email copied to clipboard. Mail is not available on this device."
                showingAlert = true
            }
        }) {
            HStack {
                Image(systemName: "envelope")
                Text("Send Email")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Frequently Asked Questions")
                .font(.headline)
                .padding(.top, 10)
            
            faqItem(
                question: "How do I start using CruiseAI?",
                answer: "Enable location and camera permissions, then tap 'Start a Drive' on the home screen to begin monitoring your driving."
            )
            
            faqItem(
                question: "Is my data secure?",
                answer: "Yes, all your driving data is stored locally on your device and is not shared with third parties unless you explicitly choose to share it."
            )
            
            faqItem(
                question: "How accurate is the detection system?",
                answer: "CruiseAI uses advanced AI models to detect road hazards with high accuracy, but it should be used as an assistant rather than a replacement for attentive driving."
            )
            
            faqItem(
                question: "Can I use CruiseAI in the background?",
                answer: "CruiseAI needs to be in the foreground with the screen on to properly monitor your driving. We recommend mounting your device on your dashboard."
            )
        }
    }
    
    private func faqItem(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(answer)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.vertical, 5)
        }
    }
}

// Mail view using UIViewControllerRepresentable
struct MailView: UIViewControllerRepresentable {
    @Binding var result: Result<MFMailComposeResult, NSError>?
    var supportEmail: String
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var result: Result<MFMailComposeResult, NSError>?
        
        init(result: Binding<Result<MFMailComposeResult, NSError>?>) {
            _result = result
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                self.result = .failure(error as NSError)
            } else {
                self.result = .success(result)
            }
            controller.dismiss(animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(result: $result)
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let viewController = MFMailComposeViewController()
        viewController.mailComposeDelegate = context.coordinator
        viewController.setToRecipients([supportEmail])
        viewController.setSubject("CruiseAI Support Request")
        viewController.setMessageBody("Please describe your issue or question below:\n\n", isHTML: false)
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
}

// Helper view for showing a help button in the navigation bar
struct HelpButton: View {
    var body: some View {
        NavigationLink(destination: ContactSupportView()) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 20))
                .foregroundColor(.blue)
        }
    }
}

struct PreviewProvider_ContactSupportView: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContactSupportView()
        }
    }
}
