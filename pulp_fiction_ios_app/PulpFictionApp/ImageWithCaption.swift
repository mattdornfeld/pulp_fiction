//
// Created by Matthew Dornfeld on 4/3/22.
//

import Logging
import SwiftUI

struct ImageWithCaption: View {
    private static let logger = Logger(label: String(describing: ImageWithCaption.self))
    let imageId: Int64
    let image: Image
    let caption: String
    let createdAt: Date
    private let uiImage: UIImage
    var body: some View {
        VStack {
            image.resizable().scaledToFit()
            Text(caption)
        }
    }

    init(imageId: Int64, uiImage: UIImage, caption: String, createdAt: Date) {
        self.imageId = imageId
        self.uiImage = uiImage
        self.caption = caption
        self.createdAt = createdAt
        image = Image(uiImage: uiImage)
    }

    init?(imageWithMetadata: ImageWithMetadata) {
        let imageData = Data(
            base64Encoded: imageWithMetadata.imageAsBase64Png,
            options: Data.Base64DecodingOptions.ignoreUnknownCharacters
        )!

        let imageMetadata = imageWithMetadata.imageMetadata
        let imageId = imageWithMetadata.imageMetadata.imageID
        let createdAt = Date(timeIntervalSince1970: Double(imageMetadata.createdAt.seconds))

        if let uiImage = UIImage(data: imageData) {
            self.init(imageId: imageWithMetadata.imageMetadata.imageID, uiImage: uiImage, caption: imageWithMetadata.caption, createdAt: createdAt)
        } else {
            ImageWithCaption.logger.error("Error loading image \(imageId)")
            return nil
        }
    }
}
