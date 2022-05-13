//
// Created by Matthew Dornfeld on 4/3/22.
//

import SwiftUI

struct ImageWithCaption: View {
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

    func serializeImage() -> String? {
        guard let imageData = uiImage.pngData() else {
            return nil
        }

        return imageData.base64EncodedString(options: .lineLength64Characters)
    }
}
