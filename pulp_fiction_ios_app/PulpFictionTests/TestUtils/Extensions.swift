//
//  Extensions.swift
//  test_unit
//
//  Created by Matthew Dornfeld on 12/20/22.
//

import Foundation

@testable import PulpFictionAppSource

extension BackendMessenger {
    func getPulpFictionTestClientWithFakeData() -> PulpFictionTestClientWithFakeData {
        pulpFictionClientProtocol as! PulpFictionTestClientWithFakeData
    }
}
