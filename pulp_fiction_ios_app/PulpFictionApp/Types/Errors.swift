//
//  Errors.swift
//  _idx_build_source_21C0F9E3_ios_min15.0
//
//  Created by Matthew Dornfeld on 9/5/22.
//

import Foundation

protocol PulpFictionError: Error {}

enum PulpFictionStartupError: PulpFictionError {
    case errorConnectingToBackendServer
}
