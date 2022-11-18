//
//  SensitiveUserMetadata.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 11/17/22.
//

import Foundation

struct SensitiveUserMetadata: Equatable {
    let email: String
    let phoneNumber: String
    let dateOfBirth: Date

    func getFormattedDateOfBirth() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter.string(from: dateOfBirth)
    }
}
