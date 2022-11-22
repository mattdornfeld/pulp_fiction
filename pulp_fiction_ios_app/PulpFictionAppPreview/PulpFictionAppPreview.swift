//
//  PulpFictionAppPreview.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/14/22.
//

import Bow
import BowEffects
import Foundation
import PulpFictionAppSource
import SwiftUI

@main
struct PulpFictionAppPreview: App {
    private let pulpFictionAppViewBuilder: PulpFictionAppViewBuilder = {
        let externalMessengersEither = ExternalMessengers.createForTests(numPostsInFeedResponse: PreviewAppConfigs.numPostsInFeedResponse)
        return .init(externalMessengersEither)
    }()

    var body: some Scene {
        WindowGroup {
            pulpFictionAppViewBuilder.buildView()
        }
    }
}
