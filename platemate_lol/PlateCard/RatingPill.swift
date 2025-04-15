//
//  RatingPill.swift
//  platemate_lol
//
//  Created by Raj Jagirdar on 4/14/25.
//


import SwiftUI

struct RatingPill: View {
    let label: String
    let value: Double
    let theme: PlateCardTheme
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(theme.colors.secondary)
            
            Text(String(format: "%.1f", value))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(ratingColor)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(ratingColor.opacity(0.1))
        .cornerRadius(20)
    }
    
    private var ratingColor: Color {
        switch value {
        case 0..<2.5:
            return .red
        case 2.5..<3.8:
            return .orange
        default:
            return .green
        }
    }
}