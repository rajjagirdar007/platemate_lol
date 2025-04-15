import SwiftUI



struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Common Utility Functions
func ratingColor(for rating: Double) -> Color {
    switch rating {
    case 0..<2.5:
        return Color(red: 0.85, green: 0.25, blue: 0.2) // Refined red
    case 2.5..<3.8:
        return Color(red: 0.95, green: 0.6, blue: 0.1)  // Rich amber
    default:
        return Color(red: 0.2, green: 0.75, blue: 0.3)  // Vibrant green
    }
}

// MARK: - Reusable Components
struct SectionHeaderDD: View {
    let title: String
    let icon: String
    let iconColor: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : Color(UIColor.darkText))
        }
    }
}

struct EnhancedRatingDetail: View {
    let label: String
    let value: Double
    let icon: String
    let color: Color
    let delay: Double
    let appeared: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Adjusted HStack to ensure label displays fully
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color.opacity(0.8))
                
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8) // Allows text to scale down slightly if needed
            }
            .frame(maxWidth: .infinity) // Allow HStack to use available width
            .opacity(appeared ? 1.0 : 0)
            .offset(y: appeared ? 0 : 5)
            .animation(
                Animation.spring(response: 0.5, dampingFraction: 0.7).delay(delay),
                value: appeared
            )
            
            Text(String(format: "%.1f", value))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(ratingColor(for: value))
                .opacity(appeared ? 1.0 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(
                    Animation.spring(response: 0.5, dampingFraction: 0.7).delay(delay + 0.1),
                    value: appeared
                )
            
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= Int(value) ? "star.fill" :
                            (value > Double(star - 1) && value < Double(star) ? "star.leadinghalf.fill" : "star"))
                        .font(.system(size: 10))
                        .foregroundColor(ratingColor(for: value))
                }
            }
            .opacity(appeared ? 1.0 : 0)
            .offset(y: appeared ? 0 : 5)
            .animation(
                Animation.spring(response: 0.5, dampingFraction: 0.7).delay(delay + 0.15),
                value: appeared
            )
        }
        .frame(width: 100) // Increased from 90 to 100 to provide more space
    }
    
    // You need to implement this function in your code
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




struct ShareButtonNavigation: View {
    @Binding var isShowingShareSheet: Bool
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = true
            }
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isShowingShareSheet = true
                isHovered = false
            }
        }) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.accentColor)
                .padding(8)
                .background(Circle().fill(Color.accentColor.opacity(0.1)))
                .scaleEffect(isHovered ? 0.92 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
    }
}

// MARK: - Main View
struct DishDetailView: View {
    let dish: Dish
    @EnvironmentObject var viewModel: DishViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    // Animation states combined to reduce property count
    @State private var animationStates = AnimationStates()
    
    struct AnimationStates {
        var isShowingShareSheet = false
        var imageLoaded = false
        var contentAppeared = false
        var ratingsAppeared = false
        var shareButtonHovered = false
    }
    
    var backgroundStyle: some ShapeStyle {
        colorScheme == .dark ?
            Color(UIColor.systemBackground) :
            Color(UIColor.systemGroupedBackground)
    }
    
    var body: some View {
        ScrollView {
            ZStack(alignment: .top) {
                Color.clear // Background spacer to ensure proper scrolling
                
                VStack(spacing: 0) {
                    imageHeaderSection
                    Spacer(minLength: 20) // Ensure proper spacing
                }
                
                VStack {
                    Spacer().frame(height: 400) // Push content down below image
                    mainContentSection
                }
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarItems(
            trailing: ShareButtonNavigation(isShowingShareSheet: $animationStates.isShowingShareSheet)
        )
        .sheet(isPresented: $animationStates.isShowingShareSheet) {
            PlateCardGenerator(dish: dish, viewModel: viewModel)
        }
        .onAppear(perform: setupAnimations)
    }
    
    // MARK: - Content Sections
    
    private var imageHeaderSection: some View {
        ZStack(alignment: .top) {
            dishImageView
        }
        .frame(height: 380)
    }
    
    private var dishImageView: some View {
        Group {
            if let imageData = dish.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 320)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.3),
                                Color.black.opacity(0.1),
                                Color.black.opacity(0)
                            ]),
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .scaleEffect(animationStates.imageLoaded ? 1.0 : 1.05)
                    .opacity(animationStates.imageLoaded ? 1.0 : 0)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.8)) {
                            animationStates.imageLoaded = true
                        }
                    }
            } else {
                imagePlaceholder
            }
        }
    }
    
    private var imagePlaceholder: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.gray.opacity(0.3),
                    Color.gray.opacity(0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 320)
            
            GridPattern(lineWidth: 0.5, spacing: 20)
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                .frame(width: 500, height: 500)
            
            VStack(spacing: 10) {
                Image(systemName: "photo")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.gray.opacity(0.7))
                
                Text("No Image Available")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
        .frame(height: 320)
    }
    
    private var dishInfoOverlay: some View {
        VStack {
            Spacer()
            
            // Title card overlapping the image
            dishTitleCard
                .padding(.vertical, 20)
                .padding(.horizontal, 25)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color(UIColor.systemGray6).opacity(0.9) : Color.white.opacity(0.95))
                        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .offset(y: 60)
                .opacity(animationStates.contentAppeared ? 1.0 : 0)
                .offset(y: animationStates.contentAppeared ? 0 : 20)
        }
        .frame(height: 320)
    }
    
    private var dishTitleCard: some View {
        VStack(spacing: 8) {
            Text(dish.name ?? "Unknown Dish")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : Color(UIColor.darkText))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 6) {
                Image(systemName: "house.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(dish.restaurant?.name ?? "Unknown Restaurant")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            if let date = dish.dateAdded {
                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.7))
                    
                    Text(date, style: .date)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .padding(.top, 2)
            }
        }
    }
    
    private var mainContentSection: some View {
        VStack(spacing: 0) {
            // Spacing for title card overlap
            Spacer().frame(height: 20)
            
            SectionHeaderDD(title: dish.name ?? "Unknown Dish", icon: "fork.knife", iconColor: .blue)
            
            // Ratings section
            ratingsSection
                .padding(.horizontal, 20)
        }
        .background(backgroundStyle)
        .cornerRadius(30, corners: [.topLeft, .topRight])
        .offset(y: -30)
    }
    
    private var ratingsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            SectionHeaderDD(title: "Ratings", icon: "star.fill", iconColor: .yellow)
                .padding(.top, 20)
                .opacity(animationStates.ratingsAppeared ? 1.0 : 0)
                .offset(y: animationStates.ratingsAppeared ? 0 : 10)
            
            // Rating details row
            ratingDetailsRow
            
            // Overall rating card
            overallRatingCard
            
            // Notes section (conditional)
            notesSection
            
            // Share button
            shareButton
            
            // PlateCard preview
            //plateCardPreview
        }
    }
    
    private var ratingDetailsRow: some View {
        HStack(spacing: 12) {
            Spacer()
            
            EnhancedRatingDetail(
                label: "Taste",
                value: dish.tasteRating,
                icon: "hand.thumbsup.fill",
                color: .blue,
                delay: 0.1,
                appeared: animationStates.ratingsAppeared
            )
            
            EnhancedRatingDetail(
                label: "Presentation",
                value: dish.presentationRating,
                icon: "photo.fill",
                color: .purple,
                delay: 0.2,
                appeared: animationStates.ratingsAppeared
            )
            
            EnhancedRatingDetail(
                label: "Value",
                value: dish.valueRating,
                icon: "dollarsign.circle.fill",
                color: .green,
                delay: 0.3,
                appeared: animationStates.ratingsAppeared
            )
            
            Spacer()
        }
        .padding(.vertical, 10)
    }
    
    private var overallRatingCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Overall Rating")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : Color(UIColor.darkText))
                
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= Int(dish.overallRating) ? "star.fill" :
                                (dish.overallRating > Double(index - 1) && dish.overallRating < Double(index) ? "star.leadinghalf.fill" : "star"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ratingColor(for: dish.overallRating))
                    }
                }
            }
            
            Spacer()
            
            Text(String(format: "%.1f", dish.overallRating) + " / 5.0")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(ratingColor(for: dish.overallRating))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(ratingColor(for: dish.overallRating).opacity(0.15))
                        .overlay(
                            Capsule()
                                .strokeBorder(ratingColor(for: dish.overallRating).opacity(0.2), lineWidth: 0.5)
                        )
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(UIColor.systemGray6).opacity(0.5) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .padding(.vertical, 8)
        .opacity(animationStates.ratingsAppeared ? 1.0 : 0)
        .offset(y: animationStates.ratingsAppeared ? 0 : 15)
        .animation(
            Animation.spring(response: 0.5, dampingFraction: 0.7).delay(0.4),
            value: animationStates.ratingsAppeared
        )
    }
    
    @ViewBuilder
    private var notesSection: some View {
        if let notes = dish.notes, !notes.isEmpty {
            Divider()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0),
                            Color.gray.opacity(0.2),
                            Color.gray.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.vertical, 10)
                .opacity(animationStates.ratingsAppeared ? 1.0 : 0)
                .animation(
                    Animation.easeIn.delay(0.5),
                    value: animationStates.ratingsAppeared
                )
            
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderDD(title: "Notes", icon: "text.quote", iconColor: .blue)
                
                Text(notes)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : Color(UIColor.darkText).opacity(0.9))
                    .lineSpacing(4)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(UIColor.systemGray5).opacity(0.5) : Color(UIColor.systemGray6).opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.gray.opacity(0.1), lineWidth: 0.5)
                            )
                    )
            }
            .opacity(animationStates.ratingsAppeared ? 1.0 : 0)
            .offset(y: animationStates.ratingsAppeared ? 0 : 15)
            .animation(
                Animation.spring(response: 0.5, dampingFraction: 0.7).delay(0.5),
                value: animationStates.ratingsAppeared
            )
        }
    }
    
    private var shareButton: some View {
        Button(action: handleShareButtonPressed) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Share PlateCard")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    // Base gradient
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.accentColor.opacity(0.85),
                                    Color.accentColor
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Top highlight for a glass-like effect
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .white.opacity(0.3),
                                    .white.opacity(0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .blendMode(.overlay)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(
                color: Color.accentColor.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(animationStates.shareButtonHovered ? 0.97 : 1.0)
        }
        .padding(.top, 10)
        .padding(.bottom, 16)
        .opacity(animationStates.ratingsAppeared ? 1.0 : 0)
        .offset(y: animationStates.ratingsAppeared ? 0 : 15)
        .animation(
            Animation.spring(response: 0.5, dampingFraction: 0.7).delay(0.6),
            value: animationStates.ratingsAppeared
        )
    }
    
    private var plateCardPreview: some View {
        VStack(alignment: .center, spacing: 16) {
            SectionHeaderDD(title: "PlateCard Preview", icon: "square.stack", iconColor: .purple)
                .frame(maxWidth: .infinity, alignment: .center)
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(UIColor.systemGray6).opacity(0.7) : Color.white)
                    .overlay(
                        DiagonalPattern(spacing: 12, lineWidth: 0.5)
                            .stroke(Color.gray.opacity(0.05), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
                
                PlateCardView(
                    dish: dish,
                    theme: viewModel.selectedTheme,
                    textCustomization: viewModel.textCustomization,
                    viewModel: viewModel
                )
                .scaleEffect(0.5)
                .frame(width: UIScreen.main.bounds.width * 0.8, height: 270)
            }
            .frame(height: 270)
            .padding(.bottom, 16)
        }
        .padding(.top, 10)
        .opacity(animationStates.ratingsAppeared ? 1.0 : 0)
        .offset(y: animationStates.ratingsAppeared ? 0 : 20)
        .animation(
            Animation.spring(response: 0.5, dampingFraction: 0.7).delay(0.7),
            value: animationStates.ratingsAppeared
        )
    }
    
    // MARK: - Helper Functions
    
    private func handleShareButtonPressed() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            animationStates.shareButtonHovered = true
        }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            animationStates.isShowingShareSheet = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                animationStates.shareButtonHovered = false
            }
        }
    }
    
    private func setupAnimations() {
        // Staggered animations for content appearance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animationStates.contentAppeared = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                animationStates.ratingsAppeared = true
            }
        }
    }
}
