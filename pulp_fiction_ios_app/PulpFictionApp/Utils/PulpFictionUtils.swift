//
//  PulpFictionUtils.swift
//  _idx_build_source_21C0F9E3_ios_min15.0
//
//  Created by Matthew Dornfeld on 9/5/22.
//

import Foundation
import SwiftProtobuf

public enum PulpFictionUtils {
    public static func getAppDirectoryFileURL(fileName: String) -> URL {
        Constants.appDirectoryURL.appendingPathComponent(fileName)
    }

    public static func getCurrentProtobufTimestamp() -> Google_Protobuf_Timestamp {
        let currentTime = Date().timeIntervalSince1970
        let currentTimeInSeconds = Int(currentTime)
        let millisecondsSinceLastSecond = Int(currentTime * 1000) - currentTimeInSeconds * 1000

        return Google_Protobuf_Timestamp.with {
            $0.seconds = Int64(currentTimeInSeconds)
            $0.nanos = Int32(millisecondsSinceLastSecond * 1_000_000)
        }
    }

    public static func generateRandomInt64() -> Int64 {
        Int64.random(in: Int64.min ... Int64.max)
    }

    public static func buildImageWithMetadata(serializedImage: Data) -> ImageWithMetadata {
        return buildImageWithMetadata(
            imageId: UUID().uuidString,
            createdAt: getCurrentProtobufTimestamp(),
            serializedImage: serializedImage
        )
    }

    public static func buildImageWithMetadata(imageId: String, createdAt: Google_Protobuf_Timestamp, serializedImage: Data) -> ImageWithMetadata {
        return ImageWithMetadata(imageId, serializedImage, createdAt)
    }
}
