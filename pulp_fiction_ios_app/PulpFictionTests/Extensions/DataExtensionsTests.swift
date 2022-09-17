//
//  DataExtensionsTests.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/13/22.
//

import Foundation
import PulpFictionAppSource
import XCTest

class DateTest: XCTestCase {
    func testFormatAsStringForView() throws {
        let currentDate = try Date.fromIsoDateString("2022-01-01T00:00:00+0000")

        [
            ("5 seconds ago", try currentDate.addDelta(second: -5)),
            ("5 minutes ago", try currentDate.addDelta(minute: -5)),
            ("5 hours ago", try currentDate.addDelta(hour: -5)),
            ("25 hours ago", try currentDate.addDelta(hour: -25)),
            ("2 days ago", try currentDate.addDelta(hour: -49)),
            ("9 days ago", try currentDate.addDelta(day: -9)),
            ("142 weeks ago", try currentDate.addDelta(day: -1000)),
        ].forEach { t2 in
            XCTAssertEqual(t2.0, t2.1.formatAsStringForView(currentDate))
        }
    }
}
