//
// Created by Matthew Dornfeld on 4/3/22.
//

import Logging
import PhotosUI
import SwiftUI

struct ScrollingContentView: View {
    let logger = Logger(label: String(describing: ScrollingContentView.self))
    let localImageStore: LocalImageStore

    var body: some View {
        let imagesWithMetadata = localImageStore
            .batchGet()
            .getOrElse([])
            .sorted { $0.imageMetadata.createdAt.seconds > $1.imageMetadata.createdAt.seconds }
            .compactMap { $0 }

        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(imagesWithMetadata) { imageWithMetadata in
                    ImageWithCaption(imageWithMetadata)
                }
            }
        }
    }
}
