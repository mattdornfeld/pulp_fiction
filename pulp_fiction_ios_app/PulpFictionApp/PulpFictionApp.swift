//
//  PulpFictionApp.swift
//
//  Created by Matthew Dornfeld on 9/15/22.
//
//

import PulpFictionAppSource
import SwiftUI

@main
struct PulpFictionApp: App {
    let pulpFictionAppViewBuilder = PulpFictionAppViewBuilder(ExternalMessengers.create())

    public var body: some Scene {
        WindowGroup {
            pulpFictionAppViewBuilder.buildView()
        }
    }
}
