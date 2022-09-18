//
//  ResourceConfigs.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/17/22.
//

import Bow
import Foundation

struct ResourceConfigs {
    static let resourceBundleFileIdentifier: Option<String> = getenv("resourceBundleFileIdentifier")
        .toOption()
        .flatMap { String(utf8String: $0).toOption() }^
}
