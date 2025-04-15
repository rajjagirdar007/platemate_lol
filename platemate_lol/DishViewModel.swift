//
//  DishViewModel.swift
//  platemate_lol
//
//  Created by Raj Jagirdar on 4/14/25.
//

import SwiftUI
import CoreData
import Combine

class DishViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var dishes: [Dish] = []
    @Published var recentDishes: [Dish] = []
    @Published var favoriteRestaurants: [Restaurant] = []
    @Published var selectedTheme: PlateCardTheme = .classic
    @Published var textCustomization = TextCustomization()
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let context = CoreDataManager.shared.persistentContainer.viewContext
    @AppStorage("totalDishesShared") private var totalDishesShared: Int = 0
    @AppStorage("preferredCardTheme") private var preferredCardTheme: String = PlateCardTheme.classic.rawValue
    
    // MARK: - Initialization
    init() {
        fetchDishes()
        fetchRecentDishes()
        fetchFavoriteRestaurants()
        loadPreferredTheme()
    }
    
    // MARK: - Core Data Operations
    func fetchDishes() {
        let request: NSFetchRequest<Dish> = Dish.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        
        do {
            dishes = try context.fetch(request)
        } catch {
            print("Error fetching dishes: \(error)")
        }
    }
    
    func fetchRecentDishes(limit: Int = 5) {
        let request: NSFetchRequest<Dish> = Dish.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        request.fetchLimit = limit
        
        do {
            recentDishes = try context.fetch(request)
        } catch {
            print("Error fetching recent dishes: \(error)")
        }
    }
    
    func fetchFavoriteRestaurants(limit: Int = 5) {
        let request: NSFetchRequest<Restaurant> = Restaurant.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "visitCount", ascending: false),
            NSSortDescriptor(key: "name", ascending: true)
        ]
        request.fetchLimit = limit
        
        do {
            favoriteRestaurants = try context.fetch(request)
        } catch {
            print("Error fetching favorite restaurants: \(error)")
        }
    }
    
    // MARK: - Core Data Operations (Updated)
    func addDish(name: String, restaurant: Restaurant, notes: String, imageData: Data?, tasteRating: Double, presentationRating: Double, valueRating: Double) {
        let newDish = Dish(context: context)
        
        newDish.id = UUID()
        newDish.name = name
        newDish.restaurant = restaurant
        newDish.notes = notes
        newDish.imageData = imageData
        newDish.tasteRating = tasteRating
        newDish.presentationRating = presentationRating
        newDish.valueRating = valueRating
        newDish.averageRating = (tasteRating + presentationRating + valueRating) / 3.0
        newDish.dateAdded = Date()
        
        // Critical fix: Update restaurant relationship counters
        restaurant.visitCount += 1
        
        saveContext()
        
        // Refresh the lists
        loadMemoryLaneData()
        fetchDishes()
        fetchRecentDishes()
        fetchFavoriteRestaurants()
    }
    
    func deleteDish(_ dish: Dish) {
        context.delete(dish)
        saveContext()
        
        // Refresh the lists
        fetchDishes()
        fetchRecentDishes()
        fetchFavoriteRestaurants()
    }
    
    func updateDish(_ dish: Dish, name: String, notes: String, tasteRating: Double, presentationRating: Double, valueRating: Double) {
        dish.name = name
        dish.notes = notes
        dish.tasteRating = tasteRating
        dish.presentationRating = presentationRating
        dish.valueRating = valueRating
        dish.averageRating = (tasteRating + presentationRating + valueRating) / 3.0
        
        saveContext()
        
        // Refresh the lists
        fetchDishes()
        fetchRecentDishes()
    }
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    // Get all restaurants for autocomplete functionality
    func getAllRestaurants() -> [String] {
        let request: NSFetchRequest<Restaurant> = Restaurant.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "visitCount", ascending: false)]
        
        do {
            let restaurants = try context.fetch(request)
            return restaurants.compactMap { $0.name }
        } catch {
            print("Error fetching restaurants: \(error)")
            return []
        }
    }
    
    // MARK: - PlateCard Features
    
    // Theme Management
    private func loadPreferredTheme() {
        if let theme = PlateCardTheme.allCases.first(where: { $0.rawValue == preferredCardTheme }) {
            selectedTheme = theme
        }
    }
    
    func savePreferredTheme(_ theme: PlateCardTheme) {
        preferredCardTheme = theme.rawValue
        selectedTheme = theme
    }
    
    // Sharing Analytics
    func trackSharedDish(_ dish: Dish) {
        totalDishesShared += 1
    }
    
    var shareConversionRate: Double {
        guard !dishes.isEmpty else { return 0 }
        return Double(totalDishesShared) / Double(dishes.count)
    }
    
    // Throwback Feature
    func getThrowbackDishes(daysAgo: Int = 365) -> [Dish] {
        let calendar = Calendar.current
        let today = Date()
        
        return dishes.filter { dish in
            guard let date = dish.dateAdded else { return false }
            let components = calendar.dateComponents([.day], from: date, to: today)
            if let days = components.day {
                return days % daysAgo < 7 && days >= daysAgo - 7
            }
            return false
        }
    }
    
    // Top-rated dishes for featuring
    func getHighlyRatedDishes(minRating: Double = 4.0, limit: Int = 5) -> [Dish] {
        let highlyRated = dishes.filter { $0.averageRating >= minRating }
        return Array(highlyRated.prefix(limit))
    }
    
    @Published var throwbackDishes: [Dish] = []
    @Published var groupedDishes: [String: [Dish]] = [:]
    @Published var sortedGroupKeys: [String] = []
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    func loadMemoryLaneData() {
        throwbackDishes = getThrowbackDishes()
        groupedDishes = Dictionary(grouping: dishes) { dish in
            Self.dateFormatter.string(from: dish.dateAdded ?? Date())
        }
        sortedGroupKeys = groupedDishes.keys.sorted(by: sortKeysDescending)
    }
    
    private func sortKeysDescending(_ key1: String, _ key2: String) -> Bool {
        guard let date1 = Self.dateFormatter.date(from: key1),
              let date2 = Self.dateFormatter.date(from: key2) else { return false }
        return date1 > date2
    }
    
    
}


// MARK: - Supporting Types

// Text customization model
struct TextCustomization: Codable {
    var fontSize: CGFloat = 1.0
    var fontWeight: Font.Weight = .regular
    
    init() {}
    
    enum CodingKeys: String, CodingKey {
        case fontSize, fontWeight
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fontSize = try container.decode(CGFloat.self, forKey: .fontSize)
        
        // Handle font weight encoding/decoding
        let weightRawValue = try container.decode(Int.self, forKey: .fontWeight)
        switch weightRawValue {
        case 1: fontWeight = .ultraLight
        case 2: fontWeight = .thin
        case 3: fontWeight = .light
        case 4: fontWeight = .regular
        case 5: fontWeight = .medium
        case 6: fontWeight = .semibold
        case 7: fontWeight = .bold
        case 8: fontWeight = .heavy
        case 9: fontWeight = .black
        default: fontWeight = .regular
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fontSize, forKey: .fontSize)
        
        // Handle font weight encoding
        var weightRawValue: Int
        switch fontWeight {
        case .ultraLight: weightRawValue = 1
        case .thin: weightRawValue = 2
        case .light: weightRawValue = 3
        case .regular: weightRawValue = 4
        case .medium: weightRawValue = 5
        case .semibold: weightRawValue = 6
        case .bold: weightRawValue = 7
        case .heavy: weightRawValue = 8
        case .black: weightRawValue = 9
        default: weightRawValue = 4
        }
        try container.encode(weightRawValue, forKey: .fontWeight)
    }
}

// Extension for Dish with helper properties
extension Dish {
    var overallRating: Double {
        return averageRating
    }
    
    var ratingColor: Color {
        switch averageRating {
        case 0..<2.5:
            return .red
        case 2.5..<3.8:
            return .orange
        default:
            return .green
        }
    }
}

