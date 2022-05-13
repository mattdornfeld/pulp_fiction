//
// Created by Matthew Dornfeld on 4/3/22.
//

import PhotosUI
import SwiftUI
import Logging

struct ScrollingContentView: View {
    let logger = Logger(label: String(describing: ScrollingContentView.self))
    var body: some View {
        let images = try! Constants.imageDatabase.getImageWithCaptions()

        ScrollView {
            VStack(alignment: .leading) {
                ForEach(0..<images.count) {
                    images[$0]
                }
            }
        }
    }
}