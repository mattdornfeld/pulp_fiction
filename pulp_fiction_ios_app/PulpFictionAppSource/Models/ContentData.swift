//
//  ContentData.swift
//  build_app_source
//
//  Created by Matthew Dornfeld on 9/25/22.
//

import Bow
import BowEffects
import Foundation
import UIKit

/// Downloads and contains a piece of content data from a url
public class ContentData: Codable, Equatable {
    public class InvalidURL: PulpFictionRequestError {}
    public class UnsupportedFileType: PulpFictionRequestError {}
    public class ErrorDeserializingImage: PulpFictionRequestError {}

    public enum ContentDataType: String, Codable, Equatable {
        case jpg

        static func create(_ fromUrl: String) throws -> ContentDataType {
            if fromUrl.hasSuffix(ContentDataType.jpg.rawValue) {
                return ContentDataType.jpg
            } else {
                throw UnsupportedFileType("Url \(fromUrl) has unsupported file type.")
            }
        }
    }

    public let data: Data
    public let contentDataType: ContentDataType
    public let urlMaybe: URL?
    
    public init(data: Data, contentDataType: ContentData.ContentDataType, urlMaybe: URL? = nil) {
        self.data = data
        self.contentDataType = contentDataType
        self.urlMaybe = urlMaybe
    }
    
    public static func == (lhs: ContentData, rhs: ContentData) -> Bool {
        lhs.data == rhs.data &&
        lhs.contentDataType == rhs.contentDataType &&
        lhs.urlMaybe == rhs.urlMaybe
    }

    static func create(_ fromUrl: String, _ dataSupplier: @escaping (URL) throws -> Data) -> IO<PulpFictionRequestError, ContentData> {
        IO.invoke {
            let url = try URL(string: fromUrl).getOrThrow(InvalidURL())
            let data = try dataSupplier(url)
            let contentDataType = try ContentDataType.create(fromUrl)
            return ContentData(
                data: data,
                contentDataType: contentDataType,
                url: url
            )
        }
    }

    public func toUIImage() -> Either<PulpFictionRequestError, UIImage> {
        guard let imageData = Data(
            base64Encoded: data,
            options: Data.Base64DecodingOptions.ignoreUnknownCharacters
        ) else {
            return Either.left(ErrorDeserializingImage())
        }

        if let uiImage = UIImage(data: imageData) {
            return Either.right(uiImage)
        } else {
            return Either.left(ErrorDeserializingImage())
        }
    }
}

public extension ContentData {
    convenience init(data: Data, contentDataType: ContentDataType, url: URL) {
        self.init(data: data, contentDataType: contentDataType, urlMaybe: url)
    }

    convenience  init(data: Data, contentDataType: ContentDataType) {
        self.init(data: data, contentDataType: contentDataType, urlMaybe: nil)
    }
}
