//
//  TextCustomizationView.swift
//  platemate_lol
//
//  Created by Raj Jagirdar on 4/14/25.
//


import SwiftUI

struct TextCustomizationView: View {
    @Binding var customization: TextCustomization
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Text Size")) {
                    Slider(value: $customization.fontSize, in: 0.8...1.5, step: 0.1) {
                        Text("Text Size")
                    } minimumValueLabel: {
                        Text("A").font(.system(size: 12))
                    } maximumValueLabel: {
                        Text("A").font(.system(size: 24))
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Customize Text")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}