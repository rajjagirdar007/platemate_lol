import SwiftUI

enum PlateCardTheme: String, CaseIterable, Identifiable {
    case classic
    case modern
    case minimal
    case vibrant
    case elegant
    
    var id: String { self.rawValue }
    
    
    var colors: (primary: Color, secondary: Color, background: Color, accent: Color) {
        switch self {
        case .classic:
            return (.black, .gray, .white, .blue)
        case .modern:
            return (.indigo, .gray, Color(.systemBackground), .blue)
        case .minimal:
            return (.black, .gray, Color(.tertiarySystemBackground), .black)
        case .vibrant:
            return (.black, .white, Color.orange, .red)
        case .elegant:
            return (.purple, .gray, Color(.secondarySystemBackground), .purple)
        }
    }
    
    // Background gradient colors
    var backgroundGradient: (start: Color, end: Color) {
        switch self {
        case .classic:
            return (Color(white: 0.98), Color.white)
        case .modern:
            return (Color(.systemBackground), Color(.systemBackground).opacity(0.95))
        case .minimal:
            return (Color(.tertiarySystemBackground).opacity(0.97), Color(.tertiarySystemBackground))
        case .vibrant:
            return (Color.orange.opacity(0.95), Color.orange.opacity(0.9))
        case .elegant:
            return (Color(.secondarySystemBackground).opacity(0.98), Color(.secondarySystemBackground))
        }
    }
    
    // Refined corner radius
    var cornerRadius: CGFloat {
        switch self {
        case .classic: return 12
        case .modern: return 16
        case .minimal: return 8  // Updated from 0 for consistency
        case .vibrant: return 16
        case .elegant: return 12 // Updated from 8 for consistency
        }
    }
    
    // Enhanced typography with SF Rounded
    var font: Font {
        switch self {
        case .classic, .vibrant:
            return .system(.headline, design: .rounded)
        case .modern:
            return .system(.headline, design: .rounded).weight(.medium)
        case .minimal:
            return .system(.headline, design: .rounded).weight(.light)
        case .elegant:
            return .system(.headline, design: .rounded).weight(.semibold)
        }
    }
    
    // Shadow configuration for depth
    var shadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat, opacity: Double) {
        switch self {
        case .classic:
            return (Color.black, 4, 0, 2, 0.07)
        case .modern:
            return (Color.black, 6, 0, 3, 0.08)
        case .minimal:
            return (Color.black, 3, 0, 1, 0.05)
        case .vibrant:
            return (Color.black, 5, 0, 2, 0.1)
        case .elegant:
            return (Color.purple, 4, 0, 2, 0.08)
        }
    }
    
    // Inner border for depth
    var innerBorder: (color: Color, width: CGFloat) {
        switch self {
        case .classic:
            return (Color.white.opacity(0.3), 0.5)
        case .modern:
            return (Color.white.opacity(0.4), 0.5)
        case .minimal:
            return (Color.white.opacity(0.2), 0.3)
        case .vibrant:
            return (Color.white.opacity(0.5), 0.7)
        case .elegant:
            return (Color.white.opacity(0.3), 0.5)
        }
    }
    
    // Animation configuration
    var animation: Animation {
        switch self {
        case .classic, .minimal:
            return .spring(response: 0.4, dampingFraction: 0.75)
        case .modern, .vibrant:
            return .spring(response: 0.45, dampingFraction: 0.8)
        case .elegant:
            return .spring(response: 0.5, dampingFraction: 0.7)
        }
    }
    
    // Content spacing
    var spacing: CGFloat {
        switch self {
        case .classic: return 12
        case .modern: return 16
        case .minimal: return 10
        case .vibrant: return 14
        case .elegant: return 12
        }
    }
}

// Example of implementation with a PlateCard view
struct PlateCard: View {
    var theme: PlateCardTheme
    var title: String
    var subtitle: String
    var content: String
    
    @State private var isPressed: Bool = false
    @State private var appeared: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            // Header section
            VStack(alignment: .leading, spacing: theme.spacing / 2) {
                Text(title)
                    .font(theme.font)
                    .foregroundColor(theme.colors.primary)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(theme.colors.secondary)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
            }
            .padding(.bottom, 4)
            
            // Content section
            Text(content)
                .font(.system(.body, design: .rounded))
                .foregroundColor(theme.colors.primary.opacity(0.9))
                .lineSpacing(4)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 6)
        }
        .padding(.all, 20)
        .background(
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [theme.backgroundGradient.start, theme.backgroundGradient.end]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Inner border
                RoundedRectangle(cornerRadius: theme.cornerRadius - 0.5)
                    .strokeBorder(theme.innerBorder.color, lineWidth: theme.innerBorder.width)
                    .blur(radius: 0.5)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(theme.colors.accent.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(
            color: theme.shadow.color.opacity(theme.shadow.opacity),
            radius: theme.shadow.radius,
            x: theme.shadow.x,
            y: theme.shadow.y
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(theme.animation, value: isPressed)
        .onTapGesture {
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            withAnimation(theme.animation) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isPressed = false
                }
            }
        }
        .onAppear {
            withAnimation(theme.animation.delay(0.1)) {
                appeared = true
            }
        }
    }
}

// Preview to see how it looks
struct PlateCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ForEach(PlateCardTheme.allCases) { theme in
                PlateCard(
                    theme: theme,
                    title: "Card Title",
                    subtitle: "Subtitle information",
                    content: "This is the main content of the card that demonstrates the Jony Ive inspired design aesthetic with refined details."
                )
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
