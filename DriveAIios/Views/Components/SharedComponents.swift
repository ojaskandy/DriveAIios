import SwiftUI

public struct FeatureCard: View {
    let title: String
    let icon: String
    let description: String
    let isGlowing: Bool
    let action: () -> Void
    
    @State private var glowOpacity: Double = 0.5
    
    public init(title: String, icon: String, description: String, isGlowing: Bool = false, action: @escaping () -> Void = {}) {
        self.title = title
        self.icon = icon
        self.description = description
        self.isGlowing = isGlowing
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            VStack(spacing: 15) {
                ZStack {
                    if isGlowing {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 70, height: 70)
                            .opacity(glowOpacity)
                            .blur(radius: 10)
                            .onAppear {
                                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                    glowOpacity = 0.2
                                }
                            }
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

public struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    public init(icon: String, title: String, message: String) {
        self.icon = icon
        self.title = title
        self.message = message
    }
    
    public var body: some View {
        VStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.systemBackground))
        .cornerRadius(15)
    }
}

public struct StatBox: View {
    let icon: String
    let value: String
    let unit: String
    let title: String
    
    public init(icon: String, value: String, unit: String, title: String) {
        self.icon = icon
        self.value = value
        self.unit = unit
        self.title = title
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                Text(unit)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
} 