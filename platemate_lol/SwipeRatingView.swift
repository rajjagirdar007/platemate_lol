//
//  SwipeRatingView.swift
//  platemate_lol
//
//  Created by Raj Jagirdar on 4/14/25.
//

import SwiftUI

struct SwipeRatingView: View {
    @Binding var rating: Double
    @State private var dragValue: Double = 0
    
    // Haptic feedback generator
    let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    @State private var lastFeedbackValue: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .foregroundColor(Color(UIColor.systemGray6))
                    .frame(width: geometry.size.width, height: 12)
                    .cornerRadius(6)
                
                // Filled track
                Rectangle()
                    .foregroundColor(ratingColor)
                    .frame(width: max(0, CGFloat(rating) / 5.0 * geometry.size.width), height: 12)
                    .cornerRadius(6)
                
                // Drag handle
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(ratingColor, lineWidth: 2)
                    )
                    .offset(x: CGFloat(rating) / 5.0 * geometry.size.width - 14)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let newRating = 5 * value.location.x / geometry.size.width
                                rating = min(max(newRating, 0), 5)
                                
                                // Trigger haptic feedback when crossing integer boundaries
                                let currentRatingInt = Int(rating)
                                if currentRatingInt != lastFeedbackValue {
                                    impactGenerator.prepare()
                                    impactGenerator.impactOccurred()
                                    lastFeedbackValue = currentRatingInt
                                }
                            }
                    )
                
                // Rating markers
                HStack {
                    ForEach(0..<6) { i in
                        Spacer()
                        if i > 0 && i < 5 {
                            Circle()
                                .fill(rating >= Double(i) ? ratingColor : Color(UIColor.systemGray4))
                                .frame(width: 6, height: 6)
                        }
                    }
                    Spacer()
                }
                .frame(width: geometry.size.width, height: 12)
            }
            .frame(height: 30)
            
            // Rating labels
            HStack {
                Text("0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("5")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 25)
        }
        .frame(height: 45)
        .onAppear {
            // Initialize the lastFeedbackValue
            lastFeedbackValue = Int(rating)
        }
    }
    
    private var ratingColor: Color {
        switch rating {
        case 0..<2:
            return Color.red
        case 2..<3.5:
            return Color.orange
        default:
            return Color.green
        }
    }
}

struct SwipeRatingView_Previews: PreviewProvider {
    static var previews: some View {
        SwipeRatingView(rating: .constant(3.5))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
