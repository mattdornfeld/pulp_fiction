//
// Created by Matthew Dornfeld on 4/29/22.
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
            imageId: generateRandomInt64(),
            createdAt: getCurrentProtobufTimestamp(),
            serializedImage: serializedImage
        )
    }

    public static func buildImageWithMetadata(imageId: Int64, createdAt: Google_Protobuf_Timestamp, serializedImage: Data) -> ImageWithMetadata {
        let imageMetadata = ImageMetadata.with {
            $0.imageID = imageId
            $0.createdAt = createdAt
        }

        return ImageWithMetadata.with {
            $0.imageMetadata = imageMetadata
            $0.imageAsBase64Png = serializedImage
        }
    }
}
