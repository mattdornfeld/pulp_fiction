//
//  ContentView.swift
//  PictureSaver
//
//  Created by Matthew Dornfeld on 3/26/22.
//
//

import CoreImage
import CoreImage.CIFilterBuiltins
import Logging
import SwiftProtobuf
import SwiftUI

struct ContentView: View {
    @State private var blurAmount = 0.0
    @State private var currentFilter: CIFilter = .sepiaTone()
    @State private var filterIntensity = 0.5
    @State private var foregroundColor = Color.blue
    @State private var image: Image?
    @State private var inputImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var showingConfirmation = false
    @State private var showingFilterSheet = false
    @State private var showingImagePicker = false
    let context: CIContext = .init()
    private let logger: Logger = .init(label: String(describing: ContentView.self))

    var body: some View {
        NavigationView {
            VStack {
                imageSelector()
                intensitySlider()
                changeFilterButton()
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("Instafilter")
            .onChange(of: inputImage) { _ in
                loadImage()
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage)
            }
            .confirmationDialog("Select a filter", isPresented: $showingFilterSheet, actions: filterSelector)
        }
    }

    private func imageSelector() -> some View {
        ZStack {
            Rectangle()
                .fill(.secondary)

            Text("Tap to select a picture")
                .foregroundColor(.white)
                .font(.headline)

            image?
                .resizable()
                .scaledToFit()
        }
        .onTapGesture {
            showingImagePicker = true
        }
    }

    private func intensitySlider() -> some View {
        HStack {
            Text("Intensity")
            Slider(value: $filterIntensity)
                .onChange(of: filterIntensity) { _ in
                    applyProcessing()
                }
        }
        .padding(.vertical)
    }

    private func changeFilterButton() -> some View {
        HStack {
            Button("Change Filter") {
                showingFilterSheet = true
            }

            Spacer()

            Button("Save", action: save)
        }
    }

    @ViewBuilder
    private func filterSelector() -> some View {
        let buttonData: [(String, CIFilter)] = [
            ("Crystallize", CIFilter.crystallize()),
            ("Edges", CIFilter.edges()),
            ("Gaussian Blur", CIFilter.gaussianBlur()),
            ("Pixellate", CIFilter.pixellate()),
            ("Sepia Tone", CIFilter.sepiaTone()),
            ("Unsharp Mask", CIFilter.unsharpMask()),
            ("Vignette", CIFilter.vignette()),
        ]

        ForEach(buttonData, id: \.0) { buttonDatum in
            Button(buttonDatum.0) {
                setFilter(buttonDatum.1)
            }
        }

        Button("Cancel", role: .cancel) {}
    }

    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys

        if inputKeys.contains(kCIInputIntensityKey) {
            currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)
        }
        if inputKeys.contains(kCIInputRadiusKey) {
            currentFilter.setValue(filterIntensity * 200, forKey: kCIInputRadiusKey)
        }
        if inputKeys.contains(kCIInputScaleKey) {
            currentFilter.setValue(filterIntensity * 10, forKey: kCIInputScaleKey)
        }

        guard let outputImage = currentFilter.outputImage else {
            return
        }

        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            let uiImage = UIImage(cgImage: cgimg)
            image = Image(uiImage: uiImage)
            processedImage = uiImage
        }
    }

    func loadImage() {
        guard let inputImage = inputImage else {
            return
        }
        let beginImage = CIImage(image: inputImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }

    func save() {
        guard let serializedImage = processedImage?.serializeImage() else {
            logger.error("Error serializing image")
            return
        }

        let imageId = Utils.generateRandomInt64()

        let imageMetadata = ImageMetadata.with {
            $0.imageID = imageId
            $0.createdAt = Utils.getCurrentProtobufTimestamp()
        }

        let imageWithMetadata = ImageWithMetadata.with {
            $0.imageMetadata = imageMetadata
            $0.imageAsBase64Png = serializedImage
        }
        
        logger.debug("Saving \(ImageWithMetadata.self) \(imageId)")

        do {
            try Constants.imageDatabase.put(imageWithMetadata: imageWithMetadata)
        } catch {
            logger.error("Error saving image \(imageMetadata) to database: \(error)")
        }
    }

    func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
    }
}
