//
//  CGImagePropertyOrientation+Extensions.swift
//  phixer
//
//  Created by Philip Price on 2/8/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit



extension CGImagePropertyOrientation {
    
    // Create from UI version of orientation
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}

extension CGImagePropertyOrientation: CustomStringConvertible {
    
    // String representation
    public var description: String {
        var desc: String = ""
        switch self {
        case .up: desc = ".up"
        case .upMirrored: desc = ".upMirrored"
        case .down: desc = ".down"
        case .downMirrored: desc = ".downMirrored"
        case .left: desc = ".left"
        case .leftMirrored: desc = ".leftMirrored"
        case .right: desc = ".right"
        case .rightMirrored: desc = ".rightMirrored"
        }
        return desc
    }
}
