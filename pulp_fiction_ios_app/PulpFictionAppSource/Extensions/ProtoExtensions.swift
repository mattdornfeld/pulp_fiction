//
//  ProtoExtensions.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/18/22.
//

import Bow
import Foundation

public extension CreatePostRequest {
    static func createImagePostRequest(_ caption: String, _ imageJpg: Data) -> CreatePostRequest {
        CreatePostRequest.with {
            $0.createImagePostRequest = CreatePostRequest.CreateImagePostRequest.with {
                $0.caption = caption
                $0.imageJpg = imageJpg
            }
        }
    }
}
