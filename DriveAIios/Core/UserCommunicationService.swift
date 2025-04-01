//
//  UserCommunicationService.swift
//  DriveAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import Foundation

class UserCommunicationService {
    // Singleton instance
    static let shared = UserCommunicationService()
    
    private init() {}
    
    // Method to send user information to backend (simulated)
    func sendUserInformation(email: String, phoneNumber: String? = nil) {
        // In a real app, this would send the information to a backend server
        // For now, we'll just log it
        print("📧 User information collected - Email: \(email), Phone: \(phoneNumber ?? "Not provided")")
        
        // Simulate network request
        // In a real app, you would use URLSession or a networking library
    }
    
    // Method to send feedback or support requests
    func sendSupportRequest(email: String, message: String) {
        // In a real app, this would send a support request to a backend server
        // For now, we'll just log it
        print("🆘 Support request received - Email: \(email), Message: \(message)")
        
        // Simulate network request
    }
}
