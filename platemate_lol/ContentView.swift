import SwiftUI

struct WelcomeView: View {
    @State private var animateTitle = false
    @State private var animateDescription = false
    @State private var animateButton = false
    @Environment(\.colorScheme) var colorScheme
    @Binding var hasSeenWelcome: Bool

    var body: some View {
        ZStack {
            // Background gradient (Unchanged)
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(white: 0.1) : Color(white: 0.95),
                    colorScheme == .dark ? Color(white: 0.05) : Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 40) {
                Spacer()

                // App icon or logo (Unchanged - Consider a custom logo later)
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .padding(.bottom, 20)

                // Title with animation - UPDATED
                Text("PlateMate") // <-- Changed from "Taste Journey"
                    .font(.system(size: 40, weight: .light, design: .default)) // <-- Changed from .thin to .light for slightly better legibility
                    .tracking(4) // <-- Kept tracking, but consider if it aids or hinders readability for "PlateMate"
                    .opacity(animateTitle ? 1 : 0)
                    .offset(y: animateTitle ? 0 : 20)

                // Description with animation (Unchanged - Fits "PlateMate" well enough for now)
                VStack(spacing: 22) {
                    Text("Discover and remember every dish")
                        .font(.system(size: 18, weight: .light))
                        .tracking(1)

                    Text("Your personal culinary memory keeper")
                        .font(.system(size: 18, weight: .light))
                        .tracking(1)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(animateDescription ? 1 : 0)
                .offset(y: animateDescription ? 0 : 15)

                Spacer()

                // Get Started button with animation - UPDATED
                Button(action: {
                    withAnimation {
                        hasSeenWelcome = true
                    }
                }) {
                    Text("Get Started") // <-- Changed from "Begin Your Journey" to be more standard and fit the new name
                        .font(.system(size: 18, weight: .regular))
                        .padding(.vertical, 16)
                        .padding(.horizontal, 40)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.8)) // <-- Kept styling for now, but consider removing opacity for a solid color later
                        )
                        .foregroundColor(.white)
                }
                .opacity(animateButton ? 1 : 0)
                .scaleEffect(animateButton ? 1 : 0.9)

                Spacer()
                    .frame(height: 80)
            }
            .padding()
        }
        .onAppear { // (Unchanged animation logic)
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animateTitle = true
            }
            withAnimation(.easeOut(duration: 1.0).delay(0.8)) {
                animateDescription = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(1.3)) {
                animateButton = true
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var dishViewModel = DishViewModel()
    @State private var hasSeenWelcome: Bool = false
    
    // Use this if you want to persist between app launches
    // @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    
    var body: some View {
        if !hasSeenWelcome {
            WelcomeView(hasSeenWelcome: $hasSeenWelcome)
        } else {
            TabView {
                DishLogView()
                    .environmentObject(dishViewModel)
                    .tabItem {
                        Label("Log", systemImage: "plus.circle")
                    }
                
                DiscoveryView()
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
            .tabViewStyle(.automatic)
            // This is the key modifier to force iPhone-style tabs on iPad
            .toolbar(.visible, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .transition(.opacity)
            .animation(.easeIn, value: hasSeenWelcome)
        }
    }
}
