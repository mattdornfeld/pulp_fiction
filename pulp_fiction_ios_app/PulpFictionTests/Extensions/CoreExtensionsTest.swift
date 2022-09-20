//
//  CoreExtensionsTest.swift
//  test_unit.__internal__.__test_bundle
//
//  Created by Matthew Dornfeld on 9/19/22.
//

import Foundation
import PulpFictionAppSource
import XCTest

class Int64Test: XCTestCase {
    func testFormatAsStringForView() throws {
        [
            ("123", 123),
            ("1.2K", 1230),
            ("1.2M", 1_230_000),
            ("1.2B", 1_230_000_000),
        ].forEach { t2 in
            XCTAssertEqual(t2.0, Int64(t2.1).formatAsStringForView())
        }
    }
}
