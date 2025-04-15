//
//  ImagePicker.swift
//  platemate_lol
//
//  Created by Raj Jagirdar on 4/14/25.
//

import SwiftUI
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isShowingFilterSheet: Bool
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        if let selectedImage = image as? UIImage {
                            // Set the initial image
                            self.parent.image = selectedImage
                            
                            // Show the filter sheet if an image was selected
                            self.parent.isShowingFilterSheet = true
                        }
                    }
                }
            }
        }
    }
}

struct ImageFilterSheet: View {
    @Binding var inputImage: UIImage?
    @Binding var outputImage: UIImage?
    @State private var currentFilter = "Original"
    @State private var filterIntensity: CGFloat = 0.5
    @State private var showingFilterIntensity = false
    @Environment(\.presentationMode) var presentationMode
    
    let filterOptions = ["Original", "Vibrant", "Warm", "Cool", "High Contrast", "Noir", "Vintage"]

    var body: some View {
        NavigationView {
            VStack {
                if let image = inputImage {
                    Image(uiImage: currentFilter == "Original" ? image : applyFilter(to: image))
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                        .padding()
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                }
                
                if showingFilterIntensity {
                    HStack {
                        Text("Intensity")
                            .foregroundColor(.secondary)
                        Slider(value: $filterIntensity, in: 0...1)
                            .onChange(of: filterIntensity) { _ in
                                // Live update the preview when slider changes
                                if let image = inputImage {
                                    outputImage = applyFilter(to: image)
                                }
                            }
                    }
                    .padding(.horizontal)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(filterOptions, id: \.self) { filter in
                            VStack {
                                if let thumbnail = inputImage?.thumbnail(size: CGSize(width: 80, height: 80)) {
                                    Image(uiImage: filter == "Original" ? thumbnail : applyFilter(named: filter, to: thumbnail, intensity: 0.7))
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(filter == currentFilter ? Color.blue : Color.clear, lineWidth: 3)
                                        )
                                }
                                
                                Text(filter)
                                    .font(.caption)
                                    .foregroundColor(filter == currentFilter ? .blue : .primary)
                            }
                            .onTapGesture {
                                withAnimation {
                                    currentFilter = filter
                                    showingFilterIntensity = filter != "Original"
                                    
                                    if let image = inputImage {
                                        outputImage = filter == "Original" ? image : applyFilter(to: image)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Enhance Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        if let image = inputImage {
                            outputImage = currentFilter == "Original" ? image : applyFilter(to: image)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private func applyFilter(to inputImage: UIImage) -> UIImage {
        return applyFilter(named: currentFilter, to: inputImage, intensity: filterIntensity)
    }
    
    private func applyFilter(named filterName: String, to inputImage: UIImage, intensity: CGFloat) -> UIImage {
        guard let ciImage = CIImage(image: inputImage) else { return inputImage }
        let context = CIContext()
        
        var outputCIImage: CIImage?
        
        switch filterName {
        case "Vibrant":
            let filter = CIFilter.vibrance()
            filter.inputImage = ciImage
            filter.amount = Float(intensity) * 1.0
            outputCIImage = filter.outputImage
            
        case "Warm":
            let filter = CIFilter.temperatureAndTint()
            filter.inputImage = ciImage
            filter.neutral = CIVector(x: 6500, y: 0) // Standard white point
            filter.targetNeutral = CIVector(x: 5000 + 2500 * CGFloat(intensity), y: 0) // Warmer
            outputCIImage = filter.outputImage
            
        case "Cool":
            let filter = CIFilter.temperatureAndTint()
            filter.inputImage = ciImage
            filter.neutral = CIVector(x: 6500, y: 0) // Standard white point
            filter.targetNeutral = CIVector(x: 8500 - 2000 * CGFloat(intensity), y: 0) // Cooler
            outputCIImage = filter.outputImage
            
        case "High Contrast":
            let filter = CIFilter.colorControls()
            filter.inputImage = ciImage
            filter.contrast = 1.0 + Float(intensity) * 0.8
            filter.saturation = 1.0 + Float(intensity) * 0.3
            outputCIImage = filter.outputImage
            
        case "Noir":
            let filter = CIFilter.photoEffectNoir()
            filter.inputImage = ciImage
            let baseOutput = filter.outputImage
            
            // Blend back some of the original based on intensity
            let blendFilter = CIFilter.sourceOverCompositing()
            blendFilter.inputImage = baseOutput
            blendFilter.backgroundImage = ciImage.applyingFilter("CIColorControls", parameters: ["inputContrast": 1.1])
            if intensity < 1.0 {
                outputCIImage = CIImage.blendWithMask(
                    foreground: baseOutput!,
                    background: ciImage,
                    mask: CIImage(color: CIColor(red: 1 - intensity, green: 1 - intensity, blue: 1 - intensity))
                )
            } else {
                outputCIImage = baseOutput
            }
            
        case "Vintage":
            let sepia = ciImage.applyingFilter("CISepiaTone", parameters: ["inputIntensity": Float(intensity) * 0.8])
            let colorControls = sepia.applyingFilter("CIColorControls",
                                                    parameters: ["inputSaturation": 0.5 + Float(intensity) * 0.2,
                                                                "inputContrast": 1.1])
            outputCIImage = colorControls.applyingFilter("CIVignette",
                                                      parameters: ["inputRadius": Float(intensity) * 2.0,
                                                                 "inputIntensity": Float(intensity) * 0.5])
            
        default:
            return inputImage
        }
        
        // Render the output image
        if let outputCIImage = outputCIImage,
           let cgImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return inputImage
    }
}

extension UIImage {
    func thumbnail(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

extension CIImage {
    static func blendWithMask(foreground: CIImage, background: CIImage, mask: CIImage) -> CIImage? {
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = foreground
        blendFilter.backgroundImage = background
        blendFilter.maskImage = mask
        return blendFilter.outputImage
    }
}
