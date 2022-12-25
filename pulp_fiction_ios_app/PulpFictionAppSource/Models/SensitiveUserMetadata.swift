//
//  SensitiveUserMetadata.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/17/22.
//

import BowOptics
import Foundation

struct SensitiveUserMetadata: UserData, Equatable, AutoSetter {
    var email: String
    var phoneNumber: String
    var dateOfBirth: Date

    func getFormattedDateOfBirth() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter.string(from: dateOfBirth)
    }
}
