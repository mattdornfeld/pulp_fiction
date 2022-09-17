//
//  PulpFictionAppPreview.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/14/22.
//

import Bow
import Foundation
import PulpFictionAppSource
import SwiftUI

@main
struct PulpFictionAppPreview: App {
    let pulpFictionAppViewBuilder = {
        let externalMessengersCreateResult = ExternalMessengers.create()        
        
        externalMessengersCreateResult.onSuccess{externalMessengers in
            let postDataCache = externalMessengers
                .postDataMessenger
                .postDataCache
            
            ImagePostData.generate().mapRight{ imagePostData in
                postDataCache
                    .put(imagePostData)
                    .unsafeRunSyncEither()
            }
            
            ImagePostData.generate().map{ imagePostData in
                postDataCache
                    .put(imagePostData)
                    .unsafeRunSyncEither()
            }
            
//            print(postDataCache.listPostIdsInCache())
        }
        
        return PulpFictionAppViewBuilder(externalMessengersCreateResult)
    }()

    public var body: some Scene {
        WindowGroup {
            pulpFictionAppViewBuilder.buildView()
        }
    }
}
