import SwiftUI
import UIKit

struct ShareOptionsView: View {
    var getImage: () -> UIImage?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: DishViewModel
    let dish: Dish
    
    // Animation states
    @State private var headerAppeared = false
    @State private var gridAppeared = false
    @State private var buttonsAppeared = false
    @State private var selectedPlatform: String? = nil
    
    private let socialPlatforms = ["Instagram", "Twitter", "Facebook", "Messages"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced header
            VStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 30, weight: .light))
                    .foregroundColor(.accentColor)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ?
                                  Color(UIColor.systemGray6) :
                                  Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 1)
                    )
                    .offset(y: headerAppeared ? 0 : -20)
                    .opacity(headerAppeared ? 1 : 0)
                
                Text("Share to")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : Color(UIColor.darkText))
                    .padding(.top, 8)
                    .offset(y: headerAppeared ? 0 : 10)
                    .opacity(headerAppeared ? 1 : 0)
                
                Text("Choose where you'd like to share your dish")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .offset(y: headerAppeared ? 0 : 10)
                    .opacity(headerAppeared ? 1 : 0)
            }
            .padding(.top, 24)
            .padding(.bottom, 16)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: headerAppeared)
            
            // Divider with refined styling
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.1),
                            Color.gray.opacity(0.2),
                            Color.gray.opacity(0.1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 24)
            
            // Enhanced social platform grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 95))], spacing: 16) {
                ForEach(Array(socialPlatforms.enumerated()), id: \.element) { index, platform in
                    EnhancedSocialButton(
                        platform: platform,
                        isSelected: selectedPlatform == platform,
                        delay: Double(index) * 0.1,
                        appeared: gridAppeared,
                        action: {
                            selectPlatform(platform)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
            
            // Spacer to push content to the top
            Spacer()
            
            // Enhanced action buttons
            VStack(spacing: 14) {
                EnhancedActionButton(
                    title: "Save to Photos",
                    icon: "photo.on.rectangle",
                    color: Color.blue,
                    delay: 0.1,
                    appeared: buttonsAppeared
                ) {
                    saveToPhotos()
                }
                
                EnhancedActionButton(
                    title: "More Options",
                    icon: "ellipsis.circle",
                    color: Color.green,
                    delay: 0.2,
                    appeared: buttonsAppeared
                ) {
                    shareWithActivitySheet()
                }
                
                EnhancedActionButton(
                    title: "Cancel",
                    icon: "xmark.circle",
                    color: Color.red,
                    delay: 0.3,
                    appeared: buttonsAppeared,
                    isDestructive: true
                ) {
                    withAnimation {
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            colorScheme == .dark ?
            Color(UIColor.systemBackground) :
            Color(UIColor.systemGroupedBackground)
        )
        .onAppear {
            // Staggered animations
            withAnimation(.easeOut(duration: 0.4)) {
                headerAppeared = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.5)) {
                    gridAppeared = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.5)) {
                    buttonsAppeared = true
                }
            }
        }
    }
    
    private func selectPlatform(_ platform: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedPlatform = platform
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Slight delay before sharing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            shareToSocialMedia(platform: platform)
        }
    }
    
    private func saveToPhotos() {
        if let image = getImage() {
            // Haptic success feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            viewModel.trackSharedDish(dish)
        }
        dismiss()
    }
    
    private func shareWithActivitySheet() {
        if let image = getImage() {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            let controller = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = scene.windows.first?.rootViewController {
                rootVC.present(controller, animated: true)
                viewModel.trackSharedDish(dish)
            }
        }
        dismiss()
    }
    
    private func shareToSocialMedia(platform: String) {
        if let image = getImage() {
            // Save image to photos first
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            
            // Open app via URL scheme if possible
            let urlScheme = platform.lowercased() + "://"
            if let url = URL(string: urlScheme), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Fallback to activity sheet
                shareWithActivitySheet()
                return
            }
            
            viewModel.trackSharedDish(dish)
        }
        dismiss()
    }
}

// Enhanced social media button with Jony Ive aesthetic
struct EnhancedSocialButton: View {
    let platform: String
    let isSelected: Bool
    let delay: Double
    let appeared: Bool
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isPressed = false
                }
            }
        }) {
            VStack(spacing: 12) {
                // Icon with background
                ZStack {
                    // Multi-layered circle for depth
                    Circle()
                        .fill(
                            colorScheme == .dark ?
                            Color(UIColor.systemGray5) :
                            Color.white
                        )
                        .frame(width: 60, height: 60)
                        .shadow(
                            color: socialMediaColor(for: platform).opacity(isSelected ? 0.3 : 0.1),
                            radius: isSelected ? 8 : 5,
                            x: 0,
                            y: isSelected ? 4 : 2
                        )
                    
                    // Subtle gradient overlay
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.7),
                                    Color.white.opacity(colorScheme == .dark ? 0 : 0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    // Icon
                    Image(systemName: socialMediaIcon(for: platform))
                        .font(.system(size: 24, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(socialMediaColor(for: platform))
                }
                .overlay(
                    Circle()
                        .strokeBorder(
                            socialMediaColor(for: platform).opacity(isSelected ? 0.3 : 0),
                            lineWidth: 2
                        )
                )
                
                // Platform name
                Text(platform)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium, design: .rounded))
                    .foregroundColor(isSelected ?
                                   socialMediaColor(for: platform) :
                                   (colorScheme == .dark ? .white : Color(UIColor.darkText)))
            }
            .padding(.vertical, 10)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(
                Animation.spring(response: 0.4, dampingFraction: 0.7).delay(delay),
                value: appeared
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func socialMediaIcon(for platform: String) -> String {
        switch platform {
        case "Instagram": return "camera.circle.fill"
        case "Twitter": return "bird"
        case "Facebook": return "person.2.circle.fill"
        case "Messages": return "message.circle.fill"
        default: return "square.and.arrow.up"
        }
    }
    
    private func socialMediaColor(for platform: String) -> Color {
        switch platform {
        case "Instagram":
            return Color(red: 215/255, green: 42/255, blue: 180/255) // Refined purple-pink
        case "Twitter":
            return Color(red: 29/255, green: 161/255, blue: 242/255) // Twitter blue
        case "Facebook":
            return Color(red: 59/255, green: 89/255, blue: 152/255) // Facebook blue
        case "Messages":
            return Color(red: 76/255, green: 217/255, blue: 100/255) // Messages green
        default:
            return Color.blue
        }
    }
}

// Enhanced action button with Jony Ive aesthetic
struct EnhancedActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let delay: Double
    let appeared: Bool
    var isDestructive: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: {
            isPressed = true
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            // Add slight delay for animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                action()
                
                // Reset pressed state after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isPressed = false
                }
            }
        }) {
            HStack {
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.trailing, 4)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.vertical, 16)
            .background(
                ZStack {
                    // Base gradient
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color.opacity(0.85),
                                    color
                                ]),
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
                        .blendMode(.overlay)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(
                color: color.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(
            Animation.spring(response: 0.4, dampingFraction: 0.7).delay(delay),
            value: appeared
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
}
