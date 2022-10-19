//
//  PostView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/9/22.
//

import Foundation
import SwiftUI

public protocol PostView: View, Identifiable, Equatable {
    var id: Int { get }
}
