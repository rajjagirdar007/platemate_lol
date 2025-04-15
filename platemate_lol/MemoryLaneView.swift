//
//  MemoryLaneView.swift
//  platemate_lol
//
//  Created by Raj Jagirdar on 4/14/25.
//


import SwiftUI

//
//  MemoryLaneView.swift
//  platemate_lol
//
//  Created by Raj Jagirdar on 4/14/25.
//

import SwiftUI

// MARK: - Main View
struct MemoryLaneView: View {
    @EnvironmentObject var dishViewModel: DishViewModel
    @State private var randomDish: Dish?
    @State private var isShowingRandomDish = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {

                    
                    MemoryTimelineSection(viewModel: dishViewModel)
                    
                    TasteRouletteSection(
                        randomDish: $randomDish,
                        isShowingRandomDish: $isShowingRandomDish,
                        viewModel: dishViewModel
                    )
                    
                    ThrowbackPlatesSection(viewModel: dishViewModel)
                }
                .onAppear {
                    dishViewModel.loadMemoryLaneData() // Add this line
                }
                .padding(.vertical)
            }
            .navigationTitle("Memories")
            .onAppear {
                dishViewModel.loadMemoryLaneData() // Add this line
            }
            .sheet(isPresented: $isShowingRandomDish) {
                if let dish = randomDish {
                    NavigationView {
                        DishDetailView(dish: dish).environmentObject(dishViewModel)
                            .navigationTitle("Your Recommendation")
                            .navigationBarItems(trailing: Button("Done") {
                                isShowingRandomDish = false
                            })
                    }
                }
            }
        }
    }
}

// MARK: - Subviews

// Taste Roulette Section
struct TasteRouletteSection: View {
    @Binding var randomDish: Dish?
    @Binding var isShowingRandomDish: Bool
    let viewModel: DishViewModel
    
    var body: some View {
        Section(header: SectionHeader(title: "Taste Roulette")) {
            Button(action: handleShake) {
                ShakeButtonContent()
            }
        }
    }
    
    private func handleShake() {
        //randomDish = viewModel.getRandomHighlyRatedDish()
        isShowingRandomDish = randomDish != nil
    }
}

// Throwback Plates Section
struct ThrowbackPlatesSection: View {
    @ObservedObject var viewModel: DishViewModel
    
    var body: some View {
        if !viewModel.throwbackDishes.isEmpty {
            Section(header: SectionHeader(title: "Throwback Plates")) {
                Text("Remember these? One year ago today...")
                    .sectionSubtitle()
                
                HorizontalDishScrollView(dishes: viewModel.throwbackDishes)
                    .onAppear {
                                           viewModel.loadMemoryLaneData() // Add this line
                                       }
            }
        }
    }
}

// Memory Timeline Section
struct MemoryTimelineSection: View {
    @ObservedObject var viewModel: DishViewModel
    
    var body: some View {
 
            
            LazyVStack(alignment: .leading, spacing: 15) {
                ForEach(viewModel.sortedGroupKeys, id: \.self) { key in
                    MonthSection(key: key, dishes: viewModel.groupedDishes[key] ?? [])
                }
            }
        
    }
}

// MARK: - Reusable Components

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.title)
            .padding(.horizontal)
    }
}

struct ShakeButtonContent: View {
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: "dice")
                    .font(.system(size: 50))
                Text("Shake for a surprise dish recommendation!")
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct HorizontalDishScrollView: View {
    let dishes: [Dish]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 15) {
                ForEach(dishes) { dish in
                    NavigationLink(destination: DishDetailView(dish: dish)) {
                        ThrowbackCard(dish: dish)
                            .frame(width: 250, height: 300)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct MonthSection: View {
    let key: String
    let dishes: [Dish]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(key)
                .font(.headline)
                .padding(.horizontal)
            
            HorizontalDishScrollView(dishes: dishes)
        }
    }
}

// MARK: - View Extensions

extension Text {
    func sectionSubtitle() -> some View {
        self
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.horizontal)
    }
}

// MARK: - ViewModel Updates (Add these to your DishViewModel)


// MARK: - ThrowbackCard remains the same but consider moving image loading to ViewModel
import SwiftUI

struct ThrowbackCard: View {
    let dish: Dish
    @Environment(\.colorScheme) private var colorScheme
    
    // Animation states
    @State private var isLoaded = false
    @State private var showShimmer = true
    @State private var shimmerOffset: CGFloat = -0.25
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image section with enhanced styling
            imageSection
            
            // Info section with refined typography
            infoSection
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(UIColor.systemGray6).opacity(0.8) : Color.white)
                .shadow(
                    color: Color.black.opacity(0.12),
                    radius: 12, x: 0, y: 5
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5)
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 2, x: 0, y: 1
                )
        )
        .scaleEffect(isLoaded ? 1.0 : 0.96)
        .opacity(isLoaded ? 1.0 : 0)
        .onAppear {
            // Animate shimmer first
            withAnimation(Animation.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.25
            }
            
            // Then animate the card in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                isLoaded = true
            }
            
            // Then remove shimmer effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showShimmer = false
                }
            }
        }
    }
    
    // Enhanced image section
    private var imageSection: some View {
        ZStack {
            if let imageData = dish.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.3),
                                Color.black.opacity(0)
                            ]),
                            startPoint: .bottom,
                            endPoint: .center
                        )
                    )
                    // Memory badge overlay
                    .overlay(
                        HStack {
                            ZStack {
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 80, height: 26)
                                    .blur(radius: 0.5)
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text("Memory")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.leading, 12)
                            .padding(.top, 12)
                            
                            Spacer()
                        },
                        alignment: .topLeading
                    )
            } else {
                ZStack {
                    // Beautiful placeholder gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.3),
                            Color.gray.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Grid pattern overlay
                    ZStack {
                        GridPattern(lineWidth: 0.5, spacing: 15)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                            .frame(width: 500, height: 500)
                    }
                    
                    // Icon overlay
                    Image(systemName: "photo")
                        .font(.system(size: 30, weight: .light))
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
            }
            
            // Shimmer effect that animates across the image
            if showShimmer {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.0),
                        Color.white.opacity(0.2),
                        Color.white.opacity(0.0),
                    ]),
                    startPoint: .init(x: shimmerOffset - 0.5, y: 0.5),
                    endPoint: .init(x: shimmerOffset, y: 0.5)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .mask(
                    Rectangle()
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                )
                .blendMode(.overlay)
            }
        }
        .frame(maxWidth: .infinity)
        .clipShape(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .corners([.topLeft, .topRight])
        )
    }
    
    // Enhanced info section
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Dish name with refined typography
            Text(dish.name ?? "Unknown Dish")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : Color(UIColor.darkText))
                .lineLimit(1)
            
            // Restaurant with icon
            HStack(spacing: 4) {
                Image(systemName: "house.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text(dish.restaurant?.name ?? "Unknown Restaurant")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Rating and date with enhanced styling
            HStack(alignment: .center) {
                // Enhanced rating display
                let avgRating = (dish.tasteRating + dish.presentationRating + dish.valueRating) / 3
                
                ZStack {
                    // Pill background with gradient
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    ratingColor(for: avgRating).opacity(0.8),
                                    ratingColor(for: avgRating)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 50, height: 24)
                        .shadow(color: ratingColor(for: avgRating).opacity(0.2), radius: 2, x: 0, y: 1)
                    
                    // Rating text with star
                    HStack(spacing: 2) {
                        Text(String(format: "%.1f", avgRating))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Image(systemName: "star.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                // Date with refined styling
                if let date = dish.dateAdded {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.7))
                        
                        Text(date, style: .date)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        Capsule()
                            .fill(colorScheme == .dark ?
                                  Color(UIColor.systemGray5).opacity(0.5) :
                                  Color(UIColor.systemGray6).opacity(0.5))
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
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

// Grid pattern for placeholder background
struct GridPattern: Shape {
    var lineWidth: CGFloat
    var spacing: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Horizontal lines
        stride(from: 0, to: rect.height, by: spacing).forEach { y in
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        
        // Vertical lines
        stride(from: 0, to: rect.width, by: spacing).forEach { x in
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }
        
        return path
    }
}

// Extension to round specific corners
extension RoundedRectangle {
    func corners(_ corners: UIRectCorner) -> some Shape {
        let cornerSize = CGSize(width: self.cornerSize.width, height: self.cornerSize.height)
        return ClippedCorners(corners: corners, radius: cornerSize.width)
    }
}

struct ClippedCorners: Shape {
    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Helper for rounded corners on specific sides
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
