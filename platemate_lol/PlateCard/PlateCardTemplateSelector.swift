import SwiftUI

struct PlateCardTemplateSelector: View {
    @Binding var selectedTheme: PlateCardTheme
    let dish: Dish
    @Environment(\.colorScheme) private var colorScheme
    
    // Animation states
    @State private var hoveredTheme: PlateCardTheme? = nil
    @State private var hasAppeared = false
    @State private var selectionMade = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Enhanced section header
            HStack(spacing: 12) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "square.on.square")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.purple)
                }
                
                Text("Select Template")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : Color(UIColor.darkText))
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 10)
            
            // Enhanced template scroll view
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(PlateCardTheme.allCases.enumerated()), id: \.element) { index, theme in
                        enhancedTemplatePreview(for: theme, index: index)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    // Record previous selection for animation
                                    selectionMade = selectedTheme != theme
                                    selectedTheme = theme
                                    
                                    // Add haptic feedback
                                    let generator = UISelectionFeedbackGenerator()
                                    generator.selectionChanged()
                                }
                            }

                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .animation(
                Animation.spring(response: 0.5, dampingFraction: 0.8).delay(0.1),
                value: hasAppeared
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                hasAppeared = true
            }
        }
    }
    
    private func enhancedTemplatePreview(for theme: PlateCardTheme, index: Int) -> some View {
        VStack(spacing: 12) {
            // Theme name with refined typography
            Text(theme.rawValue.capitalized)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(selectedTheme == theme ? .accentColor : .secondary)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)
                .animation(
                    Animation.spring(response: 0.5, dampingFraction: 0.8).delay(0.1 + Double(index) * 0.05),
                    value: hasAppeared
                )
            
            // Enhanced template preview card
            ZStack {
                // Layer 1: Background with enhanced design
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(theme.colors.background)
                    .frame(width: 130, height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                            .strokeBorder(
                                selectedTheme == theme ?
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.accentColor.opacity(0.7),
                                        Color.accentColor
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                    LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.clear,
                                        Color.accentColor
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                    .shadow(
                        color: selectedTheme == theme ?
                            Color.accentColor.opacity(0.3) : Color.black.opacity(0.1),
                        radius: selectedTheme == theme ? 8 : 5,
                        x: 0,
                        y: selectedTheme == theme ? 4 : 3
                    )
                    .scaleEffect(selectedTheme == theme ? 1.05 : (hoveredTheme == theme ? 1.02 : 1.0))
                
                // Layer 2: Content with enhanced styling
                VStack(spacing: 12) {
                    // Header area
                    Text("PLATEMATE")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .foregroundColor(theme.colors.secondary)
                        .padding(.top, 12)
                    
                    // Image placeholder with refined styling
                    if let imageData = dish.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        theme.colors.secondary.opacity(0.2),
                                        theme.colors.secondary.opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundColor(theme.colors.secondary.opacity(0.7))
                            )
                    }
                    
                    // Dish name with theme styling
                    Text(dish.name?.prefix(10) ?? "Dish")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(theme.colors.primary)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                    
                    // Rating pills with enhanced styling
                    HStack(spacing: 6) {
                        ForEach(["T", "L", "V"], id: \.self) { label in
                            ZStack {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                theme.colors.accent.opacity(0.8),
                                                theme.colors.accent
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 22, height: 22)
                                    .shadow(color: theme.colors.accent.opacity(0.3), radius: 1, x: 0, y: 1)
                                
                                Text(label)
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.bottom, 12)
                }
                .frame(width: 130, height: 200)
                
                // Layer 3: Selection indicator with animation
                if selectedTheme == theme && selectionMade {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 5, x: 0, y: 3)
                        .position(x: 105, y: 25)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 15)
            .animation(
                Animation.spring(response: 0.5, dampingFraction: 0.8).delay(0.15 + Double(index) * 0.05),
                value: hasAppeared
            )
        }
        .padding(.bottom, 10)
    }
}

// Extension for hover effect support
extension View {
    func onHover(_ perform: @escaping (Bool) -> Void) -> some View {
        #if os(iOS)
        // iOS doesn't support hover, so return the view unchanged
        return self
        #else
        return onHover(perform: perform)
        #endif
    }
}
