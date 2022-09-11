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
    private let postDataCache: PostDataCache
    
    private func getImagePostDatas() -> [ImagePostData] {
        let listPostIdsInCacheResult = IO<PulpFictionRequestError, [UUID]>.var()
        let bulkGetResult = IO<PulpFictionRequestError, [Option<PostDataOneOf>]>.var()
        
        return binding(
            listPostIdsInCacheResult <- postDataCache.listPostIdsInCache(),
            bulkGetResult <- postDataCache.bulkGet(listPostIdsInCacheResult.get),
            yield: bulkGetResult.get
        )^
            .unsafeRunSyncEither()
            .fold(
                { error in []},
                { postDataOneOfMaybes in postDataOneOfMaybes.flattenOption()}
            )
            .mapAndFilterEmpties{ (postDataOneOf) -> Option<ImagePostData> in
                switch postDataOneOf.toPostData() {
                case let postData as ImagePostData:
                    return Option.some(postData)
                default:
                    return Option<ImagePostData>.none()
                }
            }
    }

    public var body: some View {
        let imagesWithCaptions = getImagePostDatas()
            .mapAndFilterErrors{imagePostData in
                ImageWithCaption.create(imagePostData)
            }
        
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(imagesWithCaptions){$0}
            }
        }
    }
}

public extension ScrollingContentView {
    init(_ postDataCache: PostDataCache) {
        self.init(postDataCache: postDataCache)
    }
}
