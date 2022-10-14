//
// Functionality for interacting with a post via swiping
//
//  SwipablePostView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/13/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

private struct SwipablePostState: Equatable {
    /// The offset of the post from its initial position
    var dragOffset: CGSize = .zero
    /// The visibility of the parts of the view that signify a post is being upvoted
    var upvoteOpacity: CGFloat = 0.0
    /// The visibility of the part of the view that signify a post is being downvoted
    var downvoteOpacity: CGFloat = 0.0
}

private struct SwipablePostEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
}

private enum SwipablePostAction {
    /// Called when post is being moved via a swipe
    case translate(CGSize)
    /// Called when post is moved back to neutral position
    case neutral
    /// Called when post is swiped to the upvote position
    case upvote
    /// Called when post is swiped to the downvote position
    case downvote
}

private let reducer = Reducer<SwipablePostState, SwipablePostAction, SwipablePostEnvironment> {
    state, action, _ in
    switch action {
    case let .translate(dragOffset):
        state.dragOffset = dragOffset

        if (dragOffset.width + 1e-6) < 0 {
            return .task { .upvote }
        } else if (dragOffset.width - 1e-6) > 0 {
            return .task { .downvote }
        } else {
            return .task { .neutral }
        }

    case .neutral:
        state.upvoteOpacity = 0.0
        state.downvoteOpacity = 0.0
        return .none

    case .upvote:
        state.upvoteOpacity = 1.0
        state.downvoteOpacity = 0.0
        return .none

    case .downvote:
        state.upvoteOpacity = 0.0
        state.downvoteOpacity = 1.0
        return .none
    }
}

private struct Upvote: View {
    private let color = Color.white

    var body: some View {
        Image(systemName: "arrow.up")
            .foregroundStyle(color)
    }
}

private struct Downvote: View {
    private let color = Color.white

    var body: some View {
        Image(systemName: "arrow.down")
            .foregroundStyle(color)
    }
}

/// A wrapper view that introduces functionality for interacting with a post via swiping
struct SwipablePostView<Content: View>: View {
    /// The post view that swiping functionality will be added to
    let postView: Content
    private let store: Store<SwipablePostState, SwipablePostAction> = Store(
        initialState: SwipablePostState(),
        reducer: reducer,
        environment: SwipablePostEnvironment(mainQueue: .main)
    )

    var body: some View {
        ZStack {
            WithViewStore(store) { viewStore in
                Color.orange.opacity(viewStore.state.upvoteOpacity)
                Color.blue.opacity(viewStore.state.downvoteOpacity)
                postView
                    .background(Color.white)
                    .offset(x: viewStore.state.dragOffset.width, y: 0)
                    .gesture(DragGesture()
                        .onChanged { value in
                            viewStore.send(.translate(value.translation))
                        }
                        .onEnded { _ in
                            viewStore.send(.translate(CGSize.zero))
                        })
                    .overlay(alignment: .trailing) { Upvote().opacity(viewStore.state.upvoteOpacity) }
                    .overlay(alignment: .leading) { Downvote().opacity(viewStore.state.downvoteOpacity) }
            }
        }
    }
}

extension View {
    /// Convenience method that can be called in a composable way for making a post swipable
    func makeSwipable() -> some View {
        SwipablePostView(postView: self)
    }
}
