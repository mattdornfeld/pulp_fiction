//
// Created by Matthew Dornfeld on 4/3/22.
//

import Bow
import BowEffects
import Logging
import PhotosUI
import SwiftUI

public struct ScrollingContentView: View {
    private static let logger = Logger(label: String(describing: ScrollingContentView.self))
    private let postFeedMessenger: PostFeedMessenger

    public init(postFeedMessenger: PostFeedMessenger) {
        self.postFeedMessenger = postFeedMessenger
    }

    private func getImagePostViews() -> [ImagePostView] {
        return postFeedMessenger
            .getGlobalPostFeed()
            .takeAll()
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(getImagePostViews()) { $0 }
            }
        }
    }
}
