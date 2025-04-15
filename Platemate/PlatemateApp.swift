//
//  PlatemateApp.swift
//  Platemate
//
//  Created by Raj Jagirdar on 4/14/25.
//

import SwiftUI

@main
struct PlatemateApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
