//
//  platemate_lolApp.swift
//  platemate_lol
//
//  Created by Raj Jagirdar on 4/14/25.
//

import SwiftUI

@main
struct platemate_lolApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
