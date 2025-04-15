import SwiftUI

struct WelcomeView: View {
    @State private var animateTitle = false
    @State private var animateDescription = false
    @State private var animateButton = false
    @Environment(\.colorScheme) var colorScheme
    @Binding var hasSeenWelcome: Bool
    
    var body: some View {
        ZStack {
            // Background gradient
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
                
                // App icon or logo
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .padding(.bottom, 20)
                
                // Title with animation
                Text("Taste Journey")
                    .font(.system(size: 40, weight: .thin, design: .default))
                    .tracking(4)
                    .opacity(animateTitle ? 1 : 0)
                    .offset(y: animateTitle ? 0 : 20)
                
                // Description with animation
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
                
                // Get Started button with animation
                Button(action: {
                    // This will trigger the content view transition
                    withAnimation {
                        hasSeenWelcome = true
                    }
                }) {
                    Text("Begin Your Journey")
                        .font(.system(size: 18, weight: .regular))
                        .padding(.vertical, 16)
                        .padding(.horizontal, 40)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.8))
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
        .onAppear {
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

// Update ContentView to manage state and transitions
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
            .transition(.opacity)
            .animation(.easeIn, value: hasSeenWelcome)
        }
    }
}
