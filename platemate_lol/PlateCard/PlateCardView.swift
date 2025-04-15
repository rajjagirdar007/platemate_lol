import SwiftUI
import UIKit

struct PlateCardView: View {
    let dish: Dish
    var theme: PlateCardTheme
    var textCustomization: TextCustomization
    @ObservedObject var viewModel: DishViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    // Animation states
    @State private var isSharePresented: Bool = false
    @State private var cardAppeared = false
    @State private var shareButtonAppeared = false
    @State private var shareButtonHovered = false
    
    var body: some View {
        ZStack {
            // Main card content
            cardContent
                .cornerRadius(22)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.12),
                    radius: 16, x: 0, y: 8
                )
                .padding()
                .scaleEffect(cardAppeared ? 1.0 : 0.95)
                .opacity(cardAppeared ? 1.0 : 0)
            
            // Enhanced share button
            VStack {
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        shareButtonHovered = true
                    }
                    
                    // Add haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isSharePresented = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            shareButtonHovered = false
                        }
                    }
                } label: {
                    ZStack {
                        // Multi-layered background for depth
                        Circle()
                            .fill(Color.white)
                            .shadow(
                                color: Color.black.opacity(0.18),
                                radius: 12, x: 0, y: 6
                            )
                            .frame(width: 56, height: 56)
                        
                        // Subtle gradient overlay
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white,
                                        Color.white.opacity(0.9)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                        
                        // Icon with custom styling
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(theme.colors.primary.opacity(0.8))
                    }
                    .scaleEffect(shareButtonHovered ? 0.95 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: shareButtonHovered)
                }
                .offset(y: 28)
                .opacity(shareButtonAppeared ? 1.0 : 0)
                .offset(y: shareButtonAppeared ? 0 : 20)
            }
        }
        .sheet(isPresented: $isSharePresented) {
            ShareOptionsView(
                getImage: { ViewSnapshot.capture(of: cardContent) },
                viewModel: viewModel,
                dish: dish
            )
        }
        .onAppear {
            // Staggered animations for card appearance
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                cardAppeared = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    shareButtonAppeared = true
                }
            }
        }
    }
    
    private var cardContent: some View {
        VStack(spacing: 0) {
            // Enhanced header with refined typography
            VStack(spacing: 8) {
                Text("PLATEMATE")
                    .font(.system(size: 12 * textCustomization.fontSize, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.colors.secondary)
                    .tracking(2)
                
                Text(dish.name ?? "Unknown Dish")
                    .font(.system(size: 24 * textCustomization.fontSize, weight: .bold, design: .rounded))
                    .foregroundColor(theme.colors.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                HStack(spacing: 5) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 13 * textCustomization.fontSize))
                        .foregroundColor(theme.colors.secondary)
                    
                    Text(dish.restaurant?.name ?? "Unknown Restaurant")
                        .font(.system(size: 16 * textCustomization.fontSize, weight: .medium, design: .rounded))
                        .foregroundColor(theme.colors.secondary)
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    
                    // Subtle gradient overlay for depth
                    LinearGradient(
                        gradient: Gradient(colors: [
                            theme.colors.primary.opacity(0.9),
                            theme.colors.secondary
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
            
            // Enhanced image presentation
            Group {
                if let imageData = dish.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 240)
                        .clipped()
                        .overlay(
                            // Subtle gradient overlay for better visual integration
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0),
                                    Color.black.opacity(0.2)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                } else {
                    ZStack {
                        // Enhanced placeholder with subtle pattern
                        theme.colors.background.opacity(0.6)
                        
                        // Grid pattern overlay
                        GridPattern(lineWidth: 0.5, spacing: 15)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                            .frame(width: 500, height: 500)
                        
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 38, weight: .light))
                                .foregroundColor(Color.gray.opacity(0.7))
                            
                            Text("No Image Available")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Color.gray.opacity(0.7))
                        }
                    }
                    .frame(height: 240)
                }
            }
            
            // Enhanced ratings section with refined styling
            HStack(spacing: 16) {
                EnhancedRatingPill(label: "TASTE", value: dish.tasteRating, theme: theme, textSize: textCustomization.fontSize, iconName: "hand.thumbsup.fill")
                
                EnhancedRatingPill(label: "LOOK", value: dish.presentationRating, theme: theme, textSize: textCustomization.fontSize, iconName: "photo.fill")
                
                EnhancedRatingPill(label: "VALUE", value: dish.valueRating, theme: theme, textSize: textCustomization.fontSize, iconName: "dollarsign.circle.fill")
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .background(
                ZStack {
                    theme.colors.background
                    
                    // Subtle pattern overlay for texture
                    if colorScheme == .light {
                        DiagonalPattern(spacing: 8, lineWidth: 0.5)
                            .stroke(Color.gray.opacity(0.05), lineWidth: 0.5)
                    }
                }
            )
            
            // Enhanced overall rating display
            VStack(spacing: 6) {
                Text("OVERALL")
                    .font(.system(size: 14 * textCustomization.fontSize, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.colors.secondary)
                    .tracking(1)
                
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", dish.overallRating))
                        .font(.system(size: 24 * textCustomization.fontSize, weight: .bold, design: .rounded))
                        .foregroundColor(ratingColor(for: dish.overallRating))
                    
                    Text("/ 5.0")
                        .font(.system(size: 18 * textCustomization.fontSize, weight: .medium, design: .rounded))
                        .foregroundColor(theme.colors.secondary)
                }
                
                // Star rating visualization
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= Int(dish.overallRating) ? "star.fill" :
                                (dish.overallRating > Double(index - 1) && dish.overallRating < Double(index) ? "star.leadinghalf.fill" : "star"))
                            .font(.system(size: 16 * textCustomization.fontSize, weight: .medium))
                            .foregroundColor(ratingColor(for: dish.overallRating))
                    }
                }
                .padding(.top, 2)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(theme.colors.background)
            
            // Notes section with refined styling
            if let notes = dish.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "text.quote")
                            .font(.system(size: 14 * textCustomization.fontSize, weight: .medium))
                            .foregroundColor(theme.colors.secondary.opacity(0.8))
                        
                        Text("NOTES")
                            .font(.system(size: 14 * textCustomization.fontSize, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.colors.secondary.opacity(0.8))
                            .tracking(1)
                    }
                    
                    Text(notes)
                        .font(.system(size: 16 * textCustomization.fontSize, weight: .regular, design: .rounded))
                        .foregroundColor(theme.colors.primary)
                        .lineSpacing(4)
                        .padding(.horizontal, 2)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    theme.colors.background.opacity(0.8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 1)
                                .fill(theme.colors.secondary.opacity(0.1))
                                .frame(width: 3)
                                .padding(.vertical, 10),
                            alignment: .leading
                        )
                )
            }
            
            // Enhanced footer with refined styling
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "number.square.fill")
                        .font(.system(size: 11 * textCustomization.fontSize))
                        .foregroundColor(theme.colors.secondary.opacity(0.7))
                    
                    Text("#PlateMateApp")
                        .font(.system(size: 12 * textCustomization.fontSize, weight: .medium, design: .rounded))
                        .foregroundColor(theme.colors.secondary.opacity(0.7))
                }
                
                Spacer()
                
                if let date = dish.dateAdded {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11 * textCustomization.fontSize))
                            .foregroundColor(theme.colors.secondary.opacity(0.7))
                        
                        Text(date, style: .date)
                            .font(.system(size: 12 * textCustomization.fontSize, weight: .medium, design: .rounded))
                            .foregroundColor(theme.colors.secondary.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    theme.colors.background
                    
                    // Subtle gradient overlay
                    LinearGradient(
                        gradient: Gradient(colors: [
                            theme.colors.background,
                            theme.colors.background.opacity(0.9)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
        }
    }
    
    // Enhanced rating color function
    private func ratingColor(for rating: Double) -> Color {
        switch rating {
        case 0..<2.5:
            return Color(red: 0.85, green: 0.25, blue: 0.2) // Refined red
        case 2.5..<3.8:
            return Color(red: 0.95, green: 0.6, blue: 0.1)  // Rich amber
        default:
            return Color(red: 0.2, green: 0.75, blue: 0.3)  // Vibrant green
        }
    }
}

// Enhanced rating pill with icon and refined styling
struct EnhancedRatingPill: View {
    let label: String
    let value: Double
    let theme: PlateCardTheme
    let textSize: CGFloat
    let iconName: String
    
    var body: some View {
        VStack(spacing: 6) {
            // Label with icon
            HStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 10 * textSize))
                    .foregroundColor(theme.colors.secondary)
                
                Text(label)
                    .font(.system(size: 12 * textSize, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.colors.secondary)
                    .tracking(1)
            }
            
            // Rating value with enhanced styling
            ZStack {
                // Pill background with gradient
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                ratingColor(for: value).opacity(0.85),
                                ratingColor(for: value)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 32)
                    .shadow(color: ratingColor(for: value).opacity(0.2), radius: 2, x: 0, y: 1)
                
                // Rating text with subtle shadow
                Text(String(format: "%.1f", value))
                    .font(.system(size: 16 * textSize, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 0.5)
            }
            .frame(width: 65)
        }
        .frame(maxWidth: .infinity)
    }
    
    // Rating color function matching the main view
    private func ratingColor(for rating: Double) -> Color {
        switch rating {
        case 0..<2.5:
            return Color(red: 0.85, green: 0.25, blue: 0.2) // Refined red
        case 2.5..<3.8:
            return Color(red: 0.95, green: 0.6, blue: 0.1)  // Rich amber
        default:
            return Color(red: 0.2, green: 0.75, blue: 0.3)  // Vibrant green
        }
    }
}


// Diagonal pattern for subtle texture
struct DiagonalPattern: Shape {
    var spacing: CGFloat
    var lineWidth: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let diameter = rect.width + rect.height
        
        stride(from: 0, to: diameter, by: spacing).forEach { position in
            path.move(to: CGPoint(x: position, y: 0))
            path.addLine(to: CGPoint(x: 0, y: position))
        }
        
        stride(from: 0, to: diameter, by: spacing).forEach { position in
            path.move(to: CGPoint(x: rect.width - position, y: rect.height))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - position))
        }
        
        return path
    }
}
