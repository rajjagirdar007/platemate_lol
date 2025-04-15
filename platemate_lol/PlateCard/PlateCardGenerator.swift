//
//  PlateCardGenerator.swift
//  platemate_lol
//
//  Created by Raj Jagirdar on 4/14/25.
//


import SwiftUI

struct PlateCardGenerator: View {
    let dish: Dish
    @ObservedObject var viewModel: DishViewModel
    
    @State private var selectedTheme: PlateCardTheme = .classic
    @State private var textCustomization = TextCustomization()
    @State private var showCustomizationOptions = false
    
    var body: some View {
        VStack {
            PlateCardView(
                dish: dish,
                theme: selectedTheme,
                textCustomization: textCustomization,
                viewModel: viewModel
            )
            .padding(.top, 20)
            
            Divider()
                .padding(.horizontal)
            
            VStack(alignment: .leading) {
                Text("Choose a template")
                    .font(.headline)
                    .padding(.horizontal)
                
                PlateCardTemplateSelector(selectedTheme: $selectedTheme, dish: dish)
            }
            
            Button {
                showCustomizationOptions = true
            } label: {
                HStack {
                    Image(systemName: "textformat.size")
                    Text("Customize Text")
                }
                .frame(maxWidth: 220)
            }
            .buttonStyle(.bordered)
            .padding()
            
            Spacer()
        }
        .navigationTitle("Plate Card")
        .sheet(isPresented: $showCustomizationOptions) {
            TextCustomizationView(customization: $textCustomization)
        }
    }
}
