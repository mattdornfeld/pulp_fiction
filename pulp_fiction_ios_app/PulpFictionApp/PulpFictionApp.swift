//
//  PictureSaverApp.swift
//  PictureSaver
//
//  Created by Matthew Dornfeld on 3/26/22.
//
//

import ComposableArchitecture
import SwiftUI

@main
struct PulpFictionApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                VStack {
                    NavigationLink("create", destination: PostCreatorView())
                    Divider()
                    NavigationLink("feed", destination: ScrollingContentView())
                }
            }
        }
    }
}

// @main
// struct PulpFictionApp2: App {
//    var body: some Scene {
//        WindowGroup {
//            AppView(
//              store: Store(
//                initialState: AppState(),
//                reducer: appReducer,
//                environment: AppEnvironment(
//                  mainQueue: .main
//                )
//              )
//            )
//        }
//    }
// }
