import SwiftUI

struct ContentView: View {
    @StateObject private var dishViewModel = DishViewModel()
    
    var body: some View {
        TabView {
            DishLogView()
                .environmentObject(dishViewModel)
                .tabItem {
                    Label("Log", systemImage: "plus.circle")
                }
            
            DiscoveryView(dishViewModel: dishViewModel)
                .environmentObject(dishViewModel)
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
            
            MemoryLaneView()
                .environmentObject(dishViewModel)
                .tabItem {
                    Label("Memories", systemImage: "clock.arrow.circlepath")
                }
        }
    }
}
