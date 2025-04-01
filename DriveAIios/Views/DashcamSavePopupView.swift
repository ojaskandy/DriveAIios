//
//  DashcamSavePopupView.swift
//  DriveAIios
//
//  Created by Ojas Kandhare on 4/1/25.
//

import SwiftUI
import MessageUI

struct DashcamSavePopupView: View {
    @Binding var isShowingPopup: Bool
    let tripDataService: TripDataService
    @State private var showShareSheet = false
    @State private var videoPath: String?
    @State private var showContactPicker = false
    
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
                Text("Dashcam Footage")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                // Description
                Text("Would you like to save the last 5 minutes of dashcam footage?")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Buttons
                VStack(spacing: 15) {
                    // Save button
                    Button(action: {
                        saveFootage()
                    }) {
                        HStack {
                            Image(systemName: "film")
                            Text("Save Footage")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                    
                    // Discard button
                    Button(action: {
                        discardFootage()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Discard Footage")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(15)
                    }
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
            
            // Contact picker sheet
            if showContactPicker {
                ContactPickerView(isShowing: $showContactPicker, videoPath: videoPath)
                    .transition(.move(edge: .bottom))
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let path = videoPath {
                ShareSheet(items: [URL(fileURLWithPath: path)])
            }
        }
    }
    
    private func saveFootage() {
        // Save extended dashcam footage (5 minutes)
        if let path = tripDataService.saveExtendedDashcamFootage() {
            videoPath = path
            
            // Show system share sheet
            showShareSheet = true
        }
    }
    
    private func discardFootage() {
        // Just save trip details without video
        // The trip is already saved in TripDataService.endCurrentTrip()
        withAnimation {
            isShowingPopup = false
        }
    }
}

// Contact picker view
struct ContactPickerView: View {
    @Binding var isShowing: Bool
    var videoPath: String?
    @State private var selectedContact: String?
    @State private var contacts = ["John Smith", "Jane Doe", "Alex Johnson", "Emergency Contact"]
    @State private var showMessageComposer = false
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Button(action: {
                    withAnimation {
                        isShowing = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .padding()
                }
                
                Spacer()
                
                Text("Send to Contact")
                    .font(.headline)
                
                Spacer()
                
                // Empty view for balance
                Image(systemName: "xmark")
                    .font(.headline)
                    .padding()
                    .opacity(0)
            }
            
            // Contact list
            List {
                ForEach(contacts, id: \.self) { contact in
                    Button(action: {
                        selectedContact = contact
                        showMessageComposer = true
                    }) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            Text(contact)
                                .font(.body)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            
            // Cancel button
            Button(action: {
                withAnimation {
                    isShowing = false
                }
            }) {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(15)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 20)
        .sheet(isPresented: $showMessageComposer) {
            if let contact = selectedContact {
                MessageComposerView(recipient: contact, videoPath: videoPath)
            }
        }
    }
}

// Message composer view
struct MessageComposerView: View {
    let recipient: String
    let videoPath: String?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                // Message form
                Form {
                    Section(header: Text("To")) {
                        Text(recipient)
                    }
                    
                    Section(header: Text("Message")) {
                        Text("I wanted to share this dashcam footage with you.")
                    }
                    
                    if let path = videoPath {
                        Section(header: Text("Attachment")) {
                            HStack {
                                Image(systemName: "film")
                                    .foregroundColor(.blue)
                                Text(path.components(separatedBy: "/").last ?? "Video")
                                Spacer()
                                Text("5.2 MB")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                // Send button
                Button(action: {
                    // In a real app, this would actually send the message
                    // For this example, we'll just dismiss the view
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Send")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle("New Message")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// Share sheet for sharing content
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to update
    }
}

struct DashcamSavePopupView_Previews: PreviewProvider {
    static var previews: some View {
        DashcamSavePopupView(
            isShowingPopup: .constant(true),
            tripDataService: TripDataService()
        )
    }
}
