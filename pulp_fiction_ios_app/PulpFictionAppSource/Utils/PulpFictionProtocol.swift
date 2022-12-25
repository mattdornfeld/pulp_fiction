//
//  PulpFictionProtocol.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/25/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

protocol PulpFictionProtocol {
    var externalMessengers: ExternalMessengers { get }
    var backendMessenger: BackendMessenger { get }
    var postFeedMessenger: PostFeedMessenger { get }
}

extension PulpFictionProtocol {
    var backendMessenger: BackendMessenger { externalMessengers.backendMessenger }
    var postFeedMessenger: PostFeedMessenger { externalMessengers.postFeedMessenger }
}

protocol PulpFictionView: PulpFictionProtocol, View {}

protocol PulpFictionReducerProtocol: PulpFictionProtocol, ReducerProtocol {}

protocol PulpFictionToolbarContent: PulpFictionProtocol, ToolbarContent {}
