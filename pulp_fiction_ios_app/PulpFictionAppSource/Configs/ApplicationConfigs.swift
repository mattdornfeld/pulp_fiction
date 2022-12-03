//
//  ApplicationConfigs.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 12/3/22.
//

import Foundation

struct ApplicationConfigs {
    static let isTestMode: Bool = {
        if let isTestMode = getenv("isTestMode") {
            return NSString(utf8String: isTestMode)
                .getOrElse("false")
                .boolValue
        }
        return false
    }()
}
