//
// Created by Matthew Dornfeld on 4/3/22.
//

import Logging
import PhotosUI
import SwiftUI

struct ScrollingContentView: View {
    let logger = Logger(label: String(describing: ScrollingContentView.self))
    var body: some View {
        let images = try! Constants.imageDatabase.getImageWithMetadatas().map {
            ImageWithCaption(imageWithMetadata: $0)
        }.compactMap {
            $0
        }

        ScrollView {
            VStack(alignment: .leading) {
                ForEach(0 ..< images.count) {
                    images[$0]
                }
            }
        }
    }
}
