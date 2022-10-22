//
//  CodableUIImage.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 10/21/22.
//

import Foundation
import UIKit

@propertyWrapper
struct CodableUIImage: Codable, Equatable {
    var uiImage: UIImage

    enum CodingKeys: String, CodingKey {
        case image
    }

    init(image: UIImage) {
        uiImage = image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.decode(Data.self, forKey: CodingKeys.image)
        guard let image = UIImage(data: data) else {
            throw DecodingError.dataCorruptedError(forKey: CodingKeys.image, in: container, debugDescription: "Decoding image failed")
        }

        uiImage = image
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uiImage.toContentData().getOrThrow().data, forKey: CodingKeys.image)
    }

    public init(wrappedValue: UIImage) {
        self.init(image: wrappedValue)
    }

    public var wrappedValue: UIImage {
        get { uiImage }
        set { uiImage = newValue }
    }
}
