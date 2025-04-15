//
//  DishLogView.swift
//  platemate_lol
//

import SwiftUI
import PhotosUI
import CoreData
//
//  DishLogView.swift
//  platemate_lol
//

import SwiftUI
import PhotosUI
import CoreData

struct DishLogView: View {
    @EnvironmentObject var dishViewModel: DishViewModel
    @StateObject private var viewModel = DishLogViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient for a refined look
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemGroupedBackground), Color(.secondarySystemGroupedBackground)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Progress indicator
                        if !viewModel.isQuickMode {
                            ProgressView(value: viewModel.completionProgress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: Color.accentColor))
                                .padding(.horizontal)
                        }
                        
                        // Mode selector with smooth spring animation and capsule backgrounds
                        LogModeSelector(isQuickMode: $viewModel.isQuickMode, updateProgress: viewModel.updateCompletionProgress)
                        
                        // Image selection section with a refined card look
                        DishImageSection(
                            selectedImage: $viewModel.selectedImage,
                            isShowingImagePicker: $viewModel.isShowingImagePicker,
                            isShowingFilterSheet: $viewModel.isShowingFilterSheet,
                            imageScale: $viewModel.imageScale,
                            imageOpacity: $viewModel.imageOpacity
                        )
                        
                        // Essential details section styled like a modern card
                        DishDetailsSection(
                            viewModel: viewModel,
                            dishName: $viewModel.dishName,
                            restaurantName: $viewModel.restaurantName,
                            notes: $viewModel.notes,
                            isQuickMode: $viewModel.isQuickMode,
                            activeField: $viewModel.activeField,
                            showRestaurantSuggestions: $viewModel.showRestaurantSuggestions,
                            restaurantSuggestions: $viewModel.restaurantSuggestions,
                            updateProgress: viewModel.updateCompletionProgress,
                            fetchSuggestions: viewModel.fetchRestaurantSuggestions
                        )
                        
                        // Ratings section with refined typography and spacing
                        RatingsSection(
                            isQuickMode: viewModel.isQuickMode,
                            tasteRating: $viewModel.tasteRating,
                            presentationRating: $viewModel.presentationRating,
                            valueRating: $viewModel.valueRating,
                            updateProgress: viewModel.updateCompletionProgress
                        )
                        
                        // Save button with modern styling and accessible tap area
                        SaveButton(
                            dishName: viewModel.dishName,
                            restaurantName: viewModel.restaurantName,
                            selectedImage: viewModel.selectedImage,
                            saveDish: {
                                viewModel.saveDish(dishViewModel: dishViewModel)
                            }
                        )
                    }
                    .padding(.top)
                }
                .navigationTitle("Log a Dish")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            withAnimation { viewModel.resetForm() }
                        }) {
                            Text("Reset")
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    }
                }
                // Custom image picker and filter sheets with smooth transitions
                .sheet(isPresented: $viewModel.isShowingImagePicker) {
                    ImagePicker(image: $viewModel.selectedImage, isShowingFilterSheet: $viewModel.isShowingFilterSheet)
                        .onDisappear {
                            viewModel.updateCompletionProgress()
                            if viewModel.selectedImage != nil {
                                // Apply animation when image appears
                                viewModel.imageScale = 0.9
                                viewModel.imageOpacity = 0
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    viewModel.imageScale = 1.0
                                    viewModel.imageOpacity = 1.0
                                }
                            }
                        }
                }
                .sheet(isPresented: $viewModel.isShowingFilterSheet) {
                    ImageFilterSheet(
                        inputImage: $viewModel.selectedImage,
                        outputImage: $viewModel.selectedImage
                    )
                }
                .onChange(of: viewModel.selectedImage) { _ in
                    viewModel.updateCompletionProgress()
                }
                .onAppear {
                    viewModel.updateCompletionProgress()
                }
            }
        }
    }
}

//
//  DishLogViewModel.swift
//  platemate_lol
//

import SwiftUI
import CoreData

class DishLogViewModel: ObservableObject {
    // User input fields
    @Published var dishName = ""
    @Published var restaurantName = ""
    @Published var notes = ""
    @Published var tasteRating: Double = 3.0
    @Published var presentationRating: Double = 3.0
    @Published var valueRating: Double = 3.0
    @Published var selectedImage: UIImage?
    
    // UI state
    @Published var isShowingImagePicker = false
    @Published var isShowingFilterSheet = false
    @Published var isQuickMode = false
    @Published var completionProgress: Float = 0.0
    @Published var restaurantSuggestions: [String] = []
    @Published var showRestaurantSuggestions = false
    @Published var activeField: EntryField? = nil
    
    // Animation properties
    @Published var imageScale: CGFloat = 1.0
    @Published var imageOpacity: Double = 0.0
    
    enum EntryField {
        case dishName, restaurantName, notes
    }
    
    func updateCompletionProgress() {
        var totalFields = isQuickMode ? 3 : 5  // Photo, name, restaurant in quick mode; + notes and extra ratings in full mode
        var completedFields = 0
        
        if selectedImage != nil { completedFields += 1 }
        if !dishName.isEmpty { completedFields += 1 }
        if !restaurantName.isEmpty { completedFields += 1 }
        
        if !isQuickMode {
            if !notes.isEmpty { completedFields += 1 }
            if tasteRating != 3.0 || presentationRating != 3.0 || valueRating != 3.0 {
                completedFields += 1  // Count ratings as one field
            }
        }
        
        withAnimation(.spring()) {
            completionProgress = Float(completedFields) / Float(totalFields)
        }
    }
    
    func fetchRestaurantSuggestions() {
        guard !restaurantName.isEmpty else {
            restaurantSuggestions = []
            return
        }
        
        // Fetch restaurant suggestions from CoreData based on what the user is typing
        let context = CoreDataManager.shared.persistentContainer.viewContext
        let request: NSFetchRequest<Restaurant> = Restaurant.fetchRequest()
        request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", restaurantName)
        request.sortDescriptors = [NSSortDescriptor(key: "visitCount", ascending: false)]
        request.fetchLimit = 5
        
        do {
            let restaurants = try context.fetch(request)
            restaurantSuggestions = restaurants.map { $0.name ?? "" }
        } catch {
            print("Error fetching restaurant suggestions: \(error)")
            restaurantSuggestions = []
        }
    }
    
    func saveDish(dishViewModel: DishViewModel) {
        let context = CoreDataManager.shared.persistentContainer.viewContext
        
        // Check if restaurant exists, create if not
        let request: NSFetchRequest<Restaurant> = Restaurant.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", restaurantName)
        
        do {
            let restaurants = try context.fetch(request)
            let restaurant: Restaurant
            
            if let existingRestaurant = restaurants.first {
                restaurant = existingRestaurant
                restaurant.visitCount += 1
            } else {
                restaurant = Restaurant(context: context)
                restaurant.id = UUID()
                restaurant.name = restaurantName
                restaurant.location = "" // Could add location field later
                restaurant.visitCount = 1
            }
            
            // In quick mode, set default values for optional fields
            if isQuickMode {
                presentationRating = tasteRating
                valueRating = tasteRating
            }
            
            // Save dish
            dishViewModel.addDish(
                name: dishName,
                restaurant: restaurant,
                notes: notes,
                imageData: selectedImage?.jpegData(compressionQuality: 0.8),
                tasteRating: tasteRating,
                presentationRating: presentationRating,
                valueRating: valueRating
            )
            
            // Show success feedback (assuming we transition to a different view after save)
            resetForm()
            
        } catch {
            print("Error saving dish: \(error)")
        }
    }
    
    func resetForm() {
        // Reset form with animation
        withAnimation {
            dishName = ""
            restaurantName = ""
            notes = ""
            tasteRating = 3.0
            presentationRating = 3.0
            valueRating = 3.0
            selectedImage = nil
            completionProgress = 0.0
            isQuickMode = false
        }
    }
}

//
//  LogModeSelector.swift
//  platemate_lol
//

import SwiftUI
//
//  LogModeSelector.swift
//  platemate_lol
//

import SwiftUI
import SwiftUI

struct LogModeSelector: View {
    @Binding var isQuickMode: Bool
    @Environment(\.colorScheme) private var colorScheme
    var updateProgress: () -> Void
    
    // Animation states
    @State private var hasAppeared = false
    @State private var isButtonPressed = false
    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                // Full Log Button
                ModeButton(
                    title: "Full Log",
                    icon: "square.text.square.fill",
                    isSelected: !isQuickMode,
                    position: .leading
                ) {
                    if isQuickMode {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isQuickMode = false
                            updateProgress()
                        }
                        HapticFeedback.selection()
                    }
                }
                
                // Quick Log Button
                ModeButton(
                    title: "Quick Log",
                    icon: "bolt.fill",
                    isSelected: isQuickMode,
                    position: .trailing
                ) {
                    if !isQuickMode {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isQuickMode = true
                            updateProgress()
                        }
                        HapticFeedback.selection()
                    }
                }
            }
            .background(
                Capsule()
                    .fill(
                        colorScheme == .dark ?
                        Color(UIColor.systemGray6).opacity(0.7) :
                        Color(UIColor.systemGray6).opacity(0.5)
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            .padding(.horizontal, 20)
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 10)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: hasAppeared)
        }
        .frame(height: 54)
        .onAppear {
            // Animate appearance
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    hasAppeared = true
                }
            }
        }
    }
}

// Button positions for appropriate styling
enum ButtonPosition {
    case leading
    case trailing
}

// Custom mode button with refined styling
struct ModeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let position: ButtonPosition
    let action: () -> Void
    
    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: {
            isPressed = true
            
            // Add slight delay for animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                action()
                
                // Reset pressed state after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isPressed = false
                }
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white.opacity(0.8) : .primary.opacity(0.7)))
                    .opacity(isSelected ? 1 : 0.7)
                
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white.opacity(0.8) : .primary.opacity(0.7)))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    if isSelected {
                        // Beautiful gradient background
                        Capsule()
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
                            .shadow(color: Color.accentColor.opacity(0.25), radius: 3, x: 0, y: 2)
                            
                        // Subtle highlight overlay for glass effect
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        .white.opacity(0.4),
                                        .white.opacity(0)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .center
                                )
                            )
                            .blendMode(.overlay)
                    }
                }
            )
            .clipShape(
                position == .leading ?
                    CustomCornerShape(corners: [.topLeft, .bottomLeft], radius: 25) :
                    CustomCornerShape(corners: [.topRight, .bottomRight], radius: 25)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Custom shape for correctly rounded corners
struct CustomCornerShape: Shape {
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

//
//  DishImageSection.swift
//  platemate_lol
//

import SwiftUI
//
//  DishImageSection.swift
//  platemate_lol
//

import SwiftUI

struct DishImageSection: View {
    @Binding var selectedImage: UIImage?
    @Binding var isShowingImagePicker: Bool
    @Binding var isShowingFilterSheet: Bool
    @Binding var imageScale: CGFloat
    @Binding var imageOpacity: Double
    
    var body: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 250)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
                    .padding(.horizontal)
                    .scaleEffect(imageScale)
                    .opacity(imageOpacity)
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            imageOpacity = 1.0
                            imageScale = 1.0
                        }
                    }
                    .overlay(
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Button(action: {
                                    isShowingImagePicker = true
                                }) {
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(Color.accentColor)
                                        .clipShape(Circle())
                                        .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                                }
                                
                                Button(action: {
                                    isShowingFilterSheet = true
                                }) {
                                    Image(systemName: "wand.and.stars")
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(Color.orange)
                                        .clipShape(Circle())
                                        .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                                }
                            }
                            .padding(12)
                        }
                    )
            } else {
                Button(action: { isShowingImagePicker = true }) {
                    VStack(spacing: 15) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.accentColor)
                        
                        Text("Add Photo")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Tap to capture your dish")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
            }
        }
    }
}

//
//  DishDetailsSection.swift
//  platemate_lol
//

import SwiftUI
//
//  DishDetailsSection.swift
//  platemate_lol
//

import SwiftUI
import SwiftUI

struct DishDetailsSection: View {
    @ObservedObject var viewModel: DishLogViewModel
    @Binding var dishName: String
    @Binding var restaurantName: String
    @Binding var notes: String
    @Binding var isQuickMode: Bool
    @Binding var activeField: DishLogViewModel.EntryField?
    @Binding var showRestaurantSuggestions: Bool
    @Binding var restaurantSuggestions: [String]
    @Environment(\.colorScheme) private var colorScheme
    
    // Animation states
    @State private var isExpanded = false
    @State private var fieldsAppeared = false
    
    var updateProgress: () -> Void
    var fetchSuggestions: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with subtle depth
            HStack {
                Label {
                    Text(isQuickMode ? "Quick Details" : "Dish Details")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : Color(UIColor.darkText))
                } icon: {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.8))
                }
                .padding(.horizontal, 4)
                
                Spacer()
                
                // Quick mode indicator with subtle animation
                if isQuickMode {
                    Text("Quick")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.9)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color.blue.opacity(0.3), radius: 2, x: 0, y: 1)
                        )
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                colorScheme == .dark ?
                Color(UIColor.systemGray6).opacity(0.4) :
                Color.white
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
            
            // Content with elegant spacing
            VStack(spacing: 22) {
                // Dish name field
                InputField(
                    title: "Dish Name",
                    placeholder: "What did you eat?",
                    text: $dishName,
                    iconName: "menucard",
                    delay: 0.1,
                    appeared: fieldsAppeared
                )
                .onChange(of: dishName) { _ in
                    updateProgress()
                }
                .onTapGesture {
                    activeField = .dishName
                    showRestaurantSuggestions = false
                    HapticFeedback.light()
                }
                
                // Restaurant name field with enhanced autocomplete
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("Restaurant")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 4)
                    .opacity(fieldsAppeared ? 1 : 0)
                    .offset(y: fieldsAppeared ? 0 : 5)
                    .animation(
                        Animation.spring(response: 0.5, dampingFraction: 0.8).delay(0.2),
                        value: fieldsAppeared
                    )
                    
                    TextField("Where did you eat it?", text: $restaurantName)
                        .padding()
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    colorScheme == .dark ?
                                    Color(UIColor.systemGray5) :
                                    Color(UIColor.systemGray6).opacity(0.8)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.gray.opacity(0.1), lineWidth: 0.5)
                                )
                                .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                        )
                        .opacity(fieldsAppeared ? 1 : 0)
                        .offset(y: fieldsAppeared ? 0 : 10)
                        .animation(
                            Animation.spring(response: 0.5, dampingFraction: 0.8).delay(0.25),
                            value: fieldsAppeared
                        )
                        .onTapGesture {
                            activeField = .restaurantName
                            if !restaurantName.isEmpty { fetchSuggestions() }
                            HapticFeedback.light()
                        }
                        .onChange(of: restaurantName) { newValue in
                            if !newValue.isEmpty {
                                fetchSuggestions()
                                showRestaurantSuggestions = true
                            } else {
                                showRestaurantSuggestions = false
                            }
                            updateProgress()
                        }
                    
                    // Restaurant suggestions with elegant animation
                    if showRestaurantSuggestions && !restaurantSuggestions.isEmpty {
                        EnhancedSuggestionsList(
                            suggestions: restaurantSuggestions,
                            restaurantName: $restaurantName,
                            showSuggestions: $showRestaurantSuggestions
                        )
                    }
                }
                
                // Notes editor with enhanced UI (visible only in full mode)
                if !isQuickMode {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 5) {
                            Image(systemName: "note.text")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Text("Notes")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 4)
                        .opacity(fieldsAppeared ? 1 : 0)
                        .offset(y: fieldsAppeared ? 0 : 5)
                        .animation(
                            Animation.spring(response: 0.5, dampingFraction: 0.8).delay(0.3),
                            value: fieldsAppeared
                        )
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 120)
                            .padding(12)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        colorScheme == .dark ?
                                        Color(UIColor.systemGray5) :
                                        Color(UIColor.systemGray6).opacity(0.8)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.gray.opacity(0.1), lineWidth: 0.5)
                                    )
                                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                            )
                            .opacity(fieldsAppeared ? 1 : 0)
                            .offset(y: fieldsAppeared ? 0 : 15)
                            .animation(
                                Animation.spring(response: 0.5, dampingFraction: 0.8).delay(0.35),
                                value: fieldsAppeared
                            )
                            .onTapGesture {
                                activeField = .notes
                                showRestaurantSuggestions = false
                                HapticFeedback.light()
                            }
                            .onChange(of: notes) { _ in
                                updateProgress()
                            }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ?
                          Color(UIColor.systemGray6).opacity(0.6) :
                          Color.white)
                    .shadow(
                        color: Color.black.opacity(0.07),
                        radius: 10, x: 0, y: 4
                    )
            )
            .offset(y: -8) // Create a partial overlap with header
        }
        .padding(.horizontal)
        .onAppear {
            // Animate content appearance
            withAnimation(.easeOut(duration: 0.3)) {
                isExpanded = true
            }
            
            // Delayed field appearance for staggered animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    fieldsAppeared = true
                }
            }
        }
    }
}

// Enhanced input field component
struct InputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let iconName: String
    let delay: Double
    let appeared: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: iconName)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 4)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 5)
            .animation(
                Animation.spring(response: 0.5, dampingFraction: 0.8).delay(delay),
                value: appeared
            )
            
            TextField(placeholder, text: $text)
                .padding()
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            colorScheme == .dark ?
                            Color(UIColor.systemGray5) :
                            Color(UIColor.systemGray6).opacity(0.8)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.gray.opacity(0.1), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(
                    Animation.spring(response: 0.5, dampingFraction: 0.8).delay(delay + 0.05),
                    value: appeared
                )
        }
    }
}

// Enhanced suggestions list with subtle animations
struct EnhancedSuggestionsList: View {
    let suggestions: [String]
    @Binding var restaurantName: String
    @Binding var showSuggestions: Bool
    @State private var appeared = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(suggestions.prefix(5).enumerated()), id: \.element) { index, suggestion in
                Button(action: {
                    restaurantName = suggestion
                    showSuggestions = false
                    HapticFeedback.light()
                }) {
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue.opacity(0.7))
                        
                        Text(suggestion)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary.opacity(0.4))
                            .opacity(restaurantName == suggestion ? 1 : 0)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                colorScheme == .dark ?
                                Color(UIColor.systemGray5).opacity(restaurantName == suggestion ? 0.7 : 0.4) :
                                Color(UIColor.systemGray6).opacity(restaurantName == suggestion ? 0.7 : 0.4)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical, 2)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(
                    Animation.spring(response: 0.4, dampingFraction: 0.8).delay(0.1 + Double(index) * 0.05),
                    value: appeared
                )
                
                if index < suggestions.prefix(5).count - 1 {
                    Divider()
                        .padding(.leading, 36)
                        .opacity(0.5)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeIn(duration: 0.2).delay(0.2 + Double(index) * 0.05), value: appeared)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 2)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    colorScheme == .dark ?
                    Color(UIColor.systemGray5).opacity(0.7) :
                    Color.white.opacity(0.95)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.gray.opacity(0.1), lineWidth: 0.5)
        )
        .padding(.top, 5)
        .onAppear {
            withAnimation(.easeOut(duration: 0.2)) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
    }
}


struct RestaurantSuggestionsList: View {
    let suggestions: [String]
    @Binding var restaurantName: String
    @Binding var showSuggestions: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: {
                        restaurantName = suggestion
                        showSuggestions = false
                    }) {
                        Text(suggestion)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                    }
                    .foregroundColor(.primary)
                    .background(
                        Color(UIColor.systemGray6)
                            .opacity(restaurantName == suggestion ? 0.5 : 0)
                    )
                    
                    Divider()
                }
            }
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
        }
        .frame(height: min(CGFloat(suggestions.count) * 44, 150))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}


//
//  RatingsSection.swift
//  platemate_lol
//

import SwiftUI
//
//  RatingsSection.swift
//  platemate_lol
//

import SwiftUI
import SwiftUI

struct RatingsSection: View {
    let isQuickMode: Bool
    @Binding var tasteRating: Double
    @Binding var presentationRating: Double
    @Binding var valueRating: Double
    @Environment(\.colorScheme) private var colorScheme
    
    // Animation states
    @State private var headerAppeared = false
    @State private var rowsAppeared = false
    
    var updateProgress: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced header with subtle depth
            HStack {
                Label {
                    Text("Ratings")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : Color(UIColor.darkText))
                } icon: {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.yellow)
                        .shadow(color: .yellow.opacity(0.5), radius: 1, x: 0, y: 0)
                }
                .padding(.horizontal, 4)
                .opacity(headerAppeared ? 1 : 0)
                .offset(y: headerAppeared ? 0 : 8)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: headerAppeared)
                
                Spacer()
                
                // Quick mode indicator
                if isQuickMode {
                    Text("Quick")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.9)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color.blue.opacity(0.3), radius: 2, x: 0, y: 1)
                        )
                        .foregroundColor(.white)
                        .opacity(headerAppeared ? 1 : 0)
                        .offset(x: headerAppeared ? 0 : 10)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: headerAppeared)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                colorScheme == .dark ?
                Color(UIColor.systemGray6).opacity(0.4) :
                Color.white
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
            
            // Content with elegant spacing
            VStack(spacing: 18) {
                // Enhanced rating rows with animations
                EnhancedRatingRow(
                    label: "Taste",
                    value: $tasteRating,
                    icon: "hand.thumbsup.fill",
                    iconColor: .blue,
                    delay: 0.1,
                    appeared: rowsAppeared,
                    updateProgress: updateProgress
                )
                
                if !isQuickMode {
                    Divider()
                        .opacity(0.5)
                        .padding(.horizontal, 5)
                        .opacity(rowsAppeared ? 1 : 0)
                        .animation(.easeIn.delay(0.25), value: rowsAppeared)
                    
                    EnhancedRatingRow(
                        label: "Presentation",
                        value: $presentationRating,
                        icon: "photo.fill",
                        iconColor: .purple,
                        delay: 0.25,
                        appeared: rowsAppeared,
                        updateProgress: updateProgress
                    )
                    
                    Divider()
                        .opacity(0.5)
                        .padding(.horizontal, 5)
                        .opacity(rowsAppeared ? 1 : 0)
                        .animation(.easeIn.delay(0.4), value: rowsAppeared)
                    
                    EnhancedRatingRow(
                        label: "Value",
                        value: $valueRating,
                        icon: "dollarsign.circle.fill",
                        iconColor: .green,
                        delay: 0.4,
                        appeared: rowsAppeared,
                        updateProgress: updateProgress
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ?
                          Color(UIColor.systemGray6).opacity(0.6) :
                          Color.white)
                    .shadow(
                        color: Color.black.opacity(0.07),
                        radius: 10, x: 0, y: 4
                    )
            )
            .offset(y: -8) // Create a partial overlap with header
        }
        .padding(.horizontal)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                headerAppeared = true
            }
            
            // Delayed field appearance for staggered animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation {
                    rowsAppeared = true
                }
            }
        }
    }
}

struct EnhancedRatingRow: View {
    let label: String
    @Binding var value: Double
    let icon: String
    let iconColor: Color
    let delay: Double
    let appeared: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false
    
    var updateProgress: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Enhanced label with custom styling
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(iconColor)
                    }
                    
                    Text(label)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.8))
                }
                
                Spacer()
                
                // Animated rating value display
                Text(String(format: "%.1f", value))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(ratingColor(for: value))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(ratingColor(for: value).opacity(0.15))
                            .overlay(
                                Capsule()
                                    .strokeBorder(ratingColor(for: value).opacity(0.2), lineWidth: 1)
                            )
                    )
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay), value: appeared)
            
            // Enhanced swipe rating with subtle animation
            EnhancedSwipeRatingView(rating: $value)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay + 0.1), value: appeared)
                .onChange(of: value) { _ in
                    updateProgress()
                    HapticFeedback.selection()
                }
        }
        .onAppear {
            // Start subtle animation after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isAnimating = true
            }
        }
    }
    
    private func ratingColor(for value: Double) -> Color {
        switch value {
        case 0..<2.5:
            return Color(red: 0.85, green: 0.25, blue: 0.2) // Refined red
        case 2.5..<3.8:
            return Color(red: 0.95, green: 0.6, blue: 0.1)  // Rich amber
        default:
            return Color(red: 0.2, green: 0.75, blue: 0.3)  // Vibrant green
        }
    }
}

// This is a placeholder for your SwipeRatingView - replace with your actual implementation
// but with enhanced visuals to match the design language
struct EnhancedSwipeRatingView: View {
    @Binding var rating: Double
    @Environment(\.colorScheme) private var colorScheme
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    private let trackHeight: CGFloat = 8
    private let knobSize: CGFloat = 24
    private let minRating: Double = 0.0
    private let maxRating: Double = 5.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.15),
                                colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: trackHeight)
                
                // Filled track
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                ratingColor(for: rating).opacity(0.8),
                                ratingColor(for: rating)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, min(trackPosition(for: rating, in: geometry.size.width), geometry.size.width)), height: trackHeight)
                
                // Rating knob with shadow and gradient
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
                    .overlay(
                        Circle()
                            .strokeBorder(ratingColor(for: rating).opacity(0.3), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: isDragging ? 4 : 2, x: 0, y: isDragging ? 2 : 1)
                    .frame(width: knobSize, height: knobSize)
                    .offset(x: trackPosition(for: rating, in: geometry.size.width) - knobSize / 2, y: 0)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                isDragging = true
                                let newRating = rating(for: gesture.location.x, in: geometry.size.width)
                                if abs(newRating - rating) >= 0.1 {
                                    rating = newRating
                                    HapticFeedback.light()
                                }
                            }
                            .onEnded { _ in
                                isDragging = false
                                HapticFeedback.selection()
                            }
                    )
                    .scaleEffect(isDragging ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
            }
            .frame(height: max(trackHeight, knobSize))
        }
        .frame(height: 30)
        .padding(.vertical, 8)
    }
    
    private func trackPosition(for rating: Double, in width: CGFloat) -> CGFloat {
        let ratio = CGFloat((rating - minRating) / (maxRating - minRating))
        return ratio * width
    }
    
    private func rating(for position: CGFloat, in width: CGFloat) -> Double {
        let clampedPosition = max(0, min(position, width))
        let ratio = clampedPosition / width
        let newRating = minRating + (maxRating - minRating) * Double(ratio)
        return min(max(round(newRating * 10) / 10, minRating), maxRating)
    }
    
    private func ratingColor(for value: Double) -> Color {
        switch value {
        case 0..<2.5:
            return Color(red: 0.85, green: 0.25, blue: 0.2) // Refined red
        case 2.5..<3.8:
            return Color(red: 0.95, green: 0.6, blue: 0.1)  // Rich amber
        default:
            return Color(red: 0.2, green: 0.75, blue: 0.3)  // Vibrant green
        }
    }
}

// Enhanced save button with animations and depth
struct SaveButton: View {
    let dishName: String
    let restaurantName: String
    let selectedImage: UIImage?
    let saveDish: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    @State private var isAnimating = false
    
    private var isFormValid: Bool {
        return !dishName.isEmpty && !restaurantName.isEmpty && selectedImage != nil
    }
    
    var body: some View {
        Button(action: {
            isPressed = true
            
            // Add haptic feedback for success
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            
            // Slight delay for animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                saveDish()
                generator.notificationOccurred(.success)
                
                // Reset pressed state after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isPressed = false
                }
            }
        }) {
            HStack {
                Spacer()
                
                ZStack {
                    // Subtle animated background effect
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .scaleEffect(isAnimating ? 1.1 : 0.8)
                        .opacity(isAnimating ? 0.6 : 0)
                    
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text("Save Dish")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.vertical, 18)
            .background(
                ZStack {
                    // Base gradient
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: isFormValid ?
                                                 [Color.accentColor.opacity(0.9), Color.accentColor] :
                                                 [Color.gray.opacity(0.7), Color.gray]),
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
                        .opacity(isFormValid ? 1 : 0.5)
                        .blendMode(.overlay)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isFormValid ? Color.white.opacity(0.3) : Color.clear,
                        lineWidth: 0.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: isFormValid ?
                    Color.accentColor.opacity(0.4) : Color.black.opacity(0.1),
                radius: isPressed ? 2 : 8,
                x: 0,
                y: isPressed ? 1 : 4
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        }
        .disabled(!isFormValid)
        .padding(.horizontal)
        .padding(.bottom, 20)
        .onAppear {
            // Start subtle animation
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// Shared haptic feedback utility
struct HapticFeedback {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
