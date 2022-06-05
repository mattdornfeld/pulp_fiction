//
//  Extensions.swift
//  _idx_PictureSaverSource_6C36F415_ios_min15.0
//
//  Created by Matthew Dornfeld on 5/22/22.
//

import Foundation
import Logging
import UIKit

struct UIImageCompanion {
    static let logger: Logger = .init(label: String(describing: UIImageCompanion.self))
}

extension UIImage {
    func serializeImage() -> Data? {
        guard let imageData = pngData() else {
            UIImageCompanion.logger.error("Error converting \(self) to pngData")
            return nil
        }

        return imageData.base64EncodedData()
    }
}
