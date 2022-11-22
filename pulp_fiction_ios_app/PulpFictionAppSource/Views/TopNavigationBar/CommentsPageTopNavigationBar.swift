//
//  CommentsPageTopNavigationBar.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/28/22.
//

import Foundation
import SwiftUI

struct CommentsPageTopNavigationBar: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Title("Comments")
                .foregroundColor(.gray)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Symbol(
                symbolName: "plus",
                size: 20,
                color: .gray
            ).navigateOnTap(destination: CommentCreatorView())
        }
    }
}
