//
//  CommentCreatorView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/28/22.
//

import Foundation
import SwiftUI

/// View for creating and posting comments
struct CommentCreatorView: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    var body: some View {
        EditTextView(
            prompt: "Write a comment",
            createButtonLabel: "Comment",
            createButtonAction: { comment in
                if comment.count == 0 {
                    return
                }

                print(comment)
                self.presentationMode.wrappedValue.dismiss()
            }
        )
    }
}
