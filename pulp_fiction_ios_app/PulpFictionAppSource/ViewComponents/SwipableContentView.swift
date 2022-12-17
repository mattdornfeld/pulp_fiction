//
//  Functionality for interacting with a view via swiping
//
//  SwipablePostView.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/23/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// Reducer that manages updating a view while it's being swiped
struct SwipablePostViewReducer<ViewComponentsReducer: ReducerProtocol>: ReducerProtocol where ViewComponentsReducer.State: Equatable, ViewComponentsReducer.Action: Equatable {
    /// Function that supplies a reducer that's used to update the components when a swipe action occurs
    let viewComponentsReducerSuplier: () -> ViewComponentsReducer
    /// Function that's called on swipe end. This is where the logic to call ViewComponentsReducer is specified.
    let updateViewComponentsActionSupplier: (inout State, CGSize) -> ViewComponentsReducer.Action?

    struct State: Equatable {
        /// The offset of the post from its initial position. Keeps track of how far the post has been dragged
        var dragOffset: CGSize = .zero
        /// The visibility of the parts of the view that signify a post is being swiped left
        var swipeLeftOpacity: CGFloat = 0.0
        /// The visibility of the part of the view that signify a post is being swiped right
        var swipeRightOpacity: CGFloat = 0.0
        /// State of the external view components
        var viewComponentsState: ViewComponentsReducer.State
    }

    enum Action: Equatable {
        /// Called when post is being moved via a swipe
        case translate(CGSize)
        /// Called when post is moved back to neutral position
        case neutral
        /// Called when post is swiped to the left position
        case swipeLeft
        /// Called when post is swiped to the right position
        case swipeRight
        /// Called when a swipe gesture is ended
        case endSwipeGesture(CGSize)
        /// Called to update the view components
        case updateViewComponents(ViewComponentsReducer.Action?)

        static func == (lhs: SwipablePostViewReducer<ViewComponentsReducer>.Action, rhs: SwipablePostViewReducer<ViewComponentsReducer>.Action) -> Bool {
            switch (lhs, rhs) {
            case let (.translate(lhsTranslation), .translate(rhsTranslation)):
                return lhsTranslation == rhsTranslation
            case (.neutral, .neutral):
                return true
            case (.swipeLeft, .swipeLeft):
                return true
            case (.swipeRight, .swipeRight):
                return true
            case let (.endSwipeGesture(lhsTranslation), .endSwipeGesture(rhsTranslation)):
                return lhsTranslation == rhsTranslation
            case let (.updateViewComponents(lhsAction), .updateViewComponents(rhsAction)):
                return lhsAction == rhsAction
            default:
                return false
            }
        }
    }

    var body: some ReducerProtocol<State, Action> {
        Scope(
            state: \.viewComponentsState,
            action: /Action.updateViewComponents
        ) {
            viewComponentsReducerSuplier()
        }

        Reduce { state, action in
            switch action {
            case let .translate(dragOffset):
                state.dragOffset = dragOffset

                if (dragOffset.width + 1e-6) < 0 {
                    return .task { .swipeLeft }
                } else if (dragOffset.width - 1e-6) > 0 {
                    return .task { .swipeRight }
                } else {
                    return .task { .neutral }
                }

            case .neutral:
                state.swipeLeftOpacity = 0.0
                state.swipeRightOpacity = 0.0
                return .none

            case .swipeLeft:
                state.swipeLeftOpacity = 1.0
                state.swipeRightOpacity = 0.0
                return .none

            case .swipeRight:
                state.swipeLeftOpacity = 0.0
                state.swipeRightOpacity = 1.0
                return .none

            case let .endSwipeGesture(dragOffset):
                let action = updateViewComponentsActionSupplier(&state, dragOffset)
                return .task { .updateViewComponents(action) }

            case .updateViewComponents:
                return .task { .translate(CGSize.zero) }
            }
        }
    }
}

/// A wrapper view that introduces functionality for interacting with a post via swiping
struct SwipableContentView<Content: View, SwipableSwipeViewReducer: ReducerProtocol>: View where SwipableSwipeViewReducer.State: Equatable, SwipableSwipeViewReducer.Action: Equatable {
    /// View that is wrapped in the swipe functionality
    let postView: Content
    /// Symbol that appears on the right side of postView when a left swipe occurs
    let swipeLeftSymbolName: String
    /// Symbol that appears on the left side of postView when a right swipe occurs
    let swipeRightSymbolName: String
    private let store: ComposableArchitecture.StoreOf<SwipablePostViewReducer<SwipableSwipeViewReducer>>

    init(
        store: ComposableArchitecture.StoreOf<SwipablePostViewReducer<SwipableSwipeViewReducer>>,
        swipeLeftSymbolName: String,
        swipeRightSymbolName: String,
        postViewBuilder: @escaping () -> Content
    ) {
        postView = postViewBuilder()
        self.swipeLeftSymbolName = swipeLeftSymbolName
        self.swipeRightSymbolName = swipeRightSymbolName
        self.store = store
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                Color.orange.opacity(viewStore.state.swipeLeftOpacity)
                Color.blue.opacity(viewStore.state.swipeRightOpacity)
                postView
                    .background(Color.white)
                    .offset(x: viewStore.state.dragOffset.width, y: 0)
                    .gesture(DragGesture()
                        .onChanged { value in
                            viewStore.send(.translate(value.translation))
                        }
                        .onEnded { value in
                            viewStore.send(.endSwipeGesture(value.translation))
                        })
                    .overlay(alignment: .trailing) {
                        Image(systemName: swipeLeftSymbolName)
                            .foregroundStyle(Color.white)
                            .opacity(viewStore.state.swipeLeftOpacity)
                    }
                    .overlay(alignment: .leading) {
                        Image(systemName: swipeRightSymbolName)
                            .foregroundStyle(Color.white)
                            .opacity(viewStore.state.swipeRightOpacity)
                    }
            }
        }
    }
}
