//
//  platemate_lolApp.swift
//  platemate_lol
//
//  Created by Raj Jagirdar on 4/14/25.
//

import SwiftUI

@main
struct platemate_lolApp: App {
    // Use our custom CoreDataManager instead of PersistenceController
    let coreDataManager = CoreDataManager.shared
    
    // Create a shared instance of DishViewModel to use throughout the app
    @StateObject private var dishViewModel = DishViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Pass the managed object context to views
                .environment(\.managedObjectContext, coreDataManager.persistentContainer.viewContext)
                // Make the dish view model available to all views
                .environmentObject(dishViewModel)
        }
    }
}
