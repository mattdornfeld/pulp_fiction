//
// Created by Matthew Dornfeld on 4/29/22.
//

import Foundation
import SwiftProtobuf

struct Utils {
    static func getAppDirectoryFilePath(fileName: String) -> String {
        Constants.appDirectoryURL.path + fileName
    }

    static func getCurrentProtobufTimestamp() -> Google_Protobuf_Timestamp {
        let currentTime = Date().timeIntervalSince1970
        let currentTimeInSeconds = Int(currentTime)
        let millisecondsSinceLastSecond = Int(currentTime * 1000) - currentTimeInSeconds * 1000

        return Google_Protobuf_Timestamp.with {
            $0.seconds = Int64(currentTimeInSeconds)
            $0.nanos = Int32(millisecondsSinceLastSecond * 1_000_000)
        }
    }

    static func generateRandomInt64() -> Int64 {
        Int64.random(in: Int64.min ... Int64.max)
    }
}
