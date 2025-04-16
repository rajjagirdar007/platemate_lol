//
//  DiscoveryView.swift
//  platemate_lol
//
//  Created by Raj Jagirdar on 4/14/25.
//

import SwiftUI
import Combine

// MARK: - Main View
struct DiscoveryView: View {
    @EnvironmentObject var dishViewModel: DishViewModel
    @StateObject var viewState = DiscoveryViewState()
    @State private var selectedDish: Dish?
    
//    init(dishViewModel: DishViewModel) {
//        _viewState = StateObject(wrappedValue: DiscoveryViewState(dishViewModel: dishViewModel))
//    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Elegant gradient background that covers the entire screen.
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemGroupedBackground), Color(.secondarySystemGroupedBackground)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                Group {
                    if dishViewModel.dishes.isEmpty {
                        EmptyDiscoveryView()
                    } else {
                        DiscoveryListView(
                            viewState: viewState,
                            selectedDish: $selectedDish,
                            dishes: dishViewModel.dishes
                        )
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { SortingMenu(viewState: viewState) }
            .searchable(text: $viewState.searchText, prompt: "Search dishes or restaurants")
            .sheet(item: $selectedDish) { dish in
                PlateCardGenerator(dish: dish, viewModel: dishViewModel)
            }
        }
        .onAppear {
            dishViewModel.fetchDishes()
            viewState.dishViewModel = dishViewModel
            viewState.updateFilters()
        }
    }
}

// MARK: - Subviews

struct EmptyDiscoveryView: View {
    var body: some View {
        ContentUnavailableView(
            "No Dishes Yet",
            systemImage: "fork.knife",
            description: Text("Add your first dish to start discovering plates")
        )
        .padding()
    }
}
// Modernized list view
struct DiscoveryListView: View {
    @ObservedObject var viewState: DiscoveryViewState
    @Binding var selectedDish: Dish?
    let dishes: [Dish]
    @State private var animateList = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if !viewState.throwbacks.isEmpty {
                    ThrowbackSection(
                        dishes: viewState.throwbacks,
                        selectedDish: $selectedDish
                    )
                    .padding(.bottom, 12)
                }
                
                ForEach(Array(viewState.filteredDishes.enumerated()), id: \.element.id) { index, dish in
                    DishRow(dish: dish)
                        .opacity(animateList ? 1 : 0)
                        .offset(y: animateList ? 0 : 20)
                        .animation(
                            Animation.spring(response: 0.4, dampingFraction: 0.8)
                                .delay(Double(index) * 0.05),
                            value: animateList
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            HapticFeedback.light()
                            selectedDish = dish
                        }
                        .contextMenu {
                            Button(action: {
                                selectedDish = dish
                                // Share logic
                            }) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            
                            Button(action: {
                                // Favorite logic
                            }) {
                                Label("Add to Favorites", systemImage: "heart")
                            }
                        }
                }
            }
            .padding(.vertical, 8)
        }
        .onAppear {
            withAnimation {
                animateList = true
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .edgesIgnoringSafeArea(.bottom)
    }
}

// Extension for system colors with Jony Ive aesthetic
extension Color {
    static let ivorite = Color(UIColor.systemBackground)
    static let ivoriteHighlight = Color(UIColor.secondarySystemBackground)
    static let ivoriteShadow = Color.black.opacity(0.08)
}
// MARK: - Components

struct ThrowbackSection: View {
    let dishes: [Dish]
    @Binding var selectedDish: Dish?
    
    var body: some View {
        Group {
            if !dishes.isEmpty {
                Section(header: Text("Throwback Plates")
                            .font(.headline)
                            .padding(.leading, 10)) {
                    ForEach(dishes) { dish in
                        DishRow(dish: dish)
                            .throwbackStyle()
                            .onTapGesture { selectedDish = dish }
                    }
                }
            }
        }
    }
}

struct SortingMenu: View {
    @ObservedObject var viewState: DiscoveryViewState
    
    var body: some View {
        Menu {
            Picker("Sort by", selection: $viewState.sortOption) {
                ForEach(SortOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            
            Divider()
            
            RatingFilterMenu(viewState: viewState)
        } label: {
            Image(systemName: "slider.horizontal.3")
                .imageScale(.large)
                .padding(8)
                .background(Color(.systemGray5))
                .clipShape(Circle())
        }
    }
}

struct RatingFilterMenu: View {
    @ObservedObject var viewState: DiscoveryViewState
    
    var body: some View {
        Group {
            Text("Filter by Rating")
            Button("All") { viewState.filterRating = 0.0 }
            Button("4+ Stars") { viewState.filterRating = 4.0 }
            Button("3+ Stars") { viewState.filterRating = 3.0 }
            Button("2+ Stars") { viewState.filterRating = 2.0 }

        }
    }
}

struct ShareButton: View {
    let dish: Dish
    @Binding var selectedDish: Dish?
    
    var body: some View {
        Button {
            selectedDish = dish
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .tint(.blue)
    }
}

// MARK: - View Extensions

extension View {
    /// A refined throwback style with a subtle gradient overlay and card background.
    func throwbackStyle() -> some View {
        self
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.yellow.opacity(0.15), Color.clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .padding(.horizontal)
    }
    
    /// Card style modifier for list rows.
    func cardStyle() -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .padding(.horizontal)
    }
}

// MARK: - View State

class DiscoveryViewState: ObservableObject {
    @Published var searchText = ""
    @Published var sortOption: SortOption = .newest
    @Published var filterRating: Double = 0.0
    weak var dishViewModel: DishViewModel?

    @Published var throwbacks: [Dish] = []
    @Published var filteredDishes: [Dish] = []
    
    // Reference to the DishViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    // Initialize with reference to DishViewModel
    init() {
        throwbacks = []
        filteredDishes = []
    }
    
    private func setupBindings() {
        $searchText
            .combineLatest($sortOption, $filterRating)
            .debounce(for: .seconds(0.2), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateFilters()
            }
            .store(in: &cancellables)
    }
    
    // Set DishViewModel when view appears
    func setDishViewModel(_ viewModel: DishViewModel) {
        self.dishViewModel = viewModel
        self.throwbacks = viewModel.getThrowbackDishes()
        self.filteredDishes = viewModel.dishes
        setupBindings()
    }
    
    
    func updateFilters() {
        guard let dishViewModel = getDishViewModel() else { return }
        
        // First, filter by rating if needed
        let ratingFiltered = filterRating > 0
            ? dishViewModel.dishes.filter { $0.averageRating >= filterRating }
            : dishViewModel.dishes
        
        // Then filter by search text if provided
        let searchFiltered = !searchText.isEmpty
            ? ratingFiltered.filter { dish in
                let dishName = dish.name?.lowercased() ?? ""
                let restaurantName = dish.restaurant?.name?.lowercased() ?? ""
                return dishName.contains(searchText.lowercased()) ||
                       restaurantName.contains(searchText.lowercased())
            }
            : ratingFiltered
        
        // Finally, sort the results based on the selected option
        filteredDishes = sortDishes(searchFiltered, by: sortOption)
        
        // Update throwback dishes
        throwbacks = dishViewModel.getThrowbackDishes()
    }
    
    // Helper to get the DishViewModel
    private func getDishViewModel() -> DishViewModel? {
        return dishViewModel
    }
    
    // Helper to sort dishes based on the selected option
    private func sortDishes(_ dishes: [Dish], by option: SortOption) -> [Dish] {
        switch option {
        case .newest:
            return dishes.sorted { ($0.dateAdded ?? Date.distantPast) > ($1.dateAdded ?? Date.distantPast) }
        case .oldest:
            return dishes.sorted { ($0.dateAdded ?? Date.distantPast) < ($1.dateAdded ?? Date.distantPast) }
        case .highestRated:
            return dishes.sorted { $0.averageRating > $1.averageRating }
        case .trending:
            let recencyWeight = 0.7
            let ratingWeight = 0.3
            return dishes.sorted {
                let date1 = $0.dateAdded ?? Date.distantPast
                let date2 = $1.dateAdded ?? Date.distantPast
                let daysSince1 = Calendar.current.dateComponents([.day], from: date1, to: Date()).day ?? 0
                let daysSince2 = Calendar.current.dateComponents([.day], from: date2, to: Date()).day ?? 0
                
                let score1 = (recencyWeight * (1.0 / Double(max(daysSince1, 1)))) +
                             (ratingWeight * $0.averageRating)
                let score2 = (recencyWeight * (1.0 / Double(max(daysSince2, 1)))) +
                             (ratingWeight * $1.averageRating)
                
                return score1 > score2
            }
        }
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case newest = "Newest"
    case oldest = "Oldest"
    case highestRated = "Highest Rated"
    case trending = "Trending"
    
    var id: String { self.rawValue }
}

// MARK: - DishRow and Subviews
struct DishRow: View {
    let dish: Dish
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Enhanced image view with subtle shadow
            DishImageView(dish: dish)
            
            // Expanded info with better typography and spacing
            DishInfoView(dish: dish)
            
            Spacer()
            
            // Redesigned rating component with animation
            RatingBadge(rating: dish.averageRating)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ?
                      Color(UIColor.systemGray6).opacity(0.8) :
                      Color.white)
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 8, x: 0, y: 4
                )
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

private struct DishImageView: View {
    let dish: Dish
    @State private var isLoaded = false
    
    var body: some View {
        ZStack {
            if let imageData = dish.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .opacity(isLoaded ? 1.0 : 0.0)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isLoaded = true
                        }
                    }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(.gray)
                    )
            }
        }
    }
}

private struct DishInfoView: View {
    let dish: Dish
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(dish.name ?? "Unknown Dish")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .lineLimit(1)
            
            HStack(spacing: 4) {
                Image(systemName: "house.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text(dish.restaurant?.name ?? "Unknown Restaurant")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            if let date = dish.dateAdded {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.7))
                    
                    Text(date, style: .date)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .padding(.top, 2)
            }
        }
        .padding(.leading, 2)
    }
}

private struct RatingBadge: View {
    let rating: Double
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Layered circles for depth
            Circle()
                .fill(ratingColor.opacity(0.12))
                .frame(width: 54, height: 54)
            
            Circle()
                .fill(ratingColor.opacity(0.2))
                .frame(width: 50, height: 50)
                .scaleEffect(isAnimating ? 1.05 : 1.0)
            
            // Main circle with glass effect
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            ratingColor.opacity(0.85),
                            ratingColor.opacity(0.95)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5)
                )
                .frame(width: 46, height: 46)
                .shadow(color: ratingColor.opacity(0.3), radius: 3, x: 0, y: 2)
            
            // Rating content
            VStack(spacing: 1) {
                Text(String(format: "%.1f", rating))
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Star with glow effect
                Image(systemName: "star.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.8), radius: 1, x: 0, y: 0)
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    private var ratingColor: Color {
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
