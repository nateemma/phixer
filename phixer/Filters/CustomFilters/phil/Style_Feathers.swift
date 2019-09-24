//
//  Style_Feathers.swift
//  Implements a Fast Neural Style transfer filter, based on "Feathers" by somebody famous
//
//  Created by Philip Price on 10/25/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage
import CoreML
import UIKit

class Style_Feathers: StyleTransferFilter {
    
    // returns the source image used to create the model. This is just to support UIs, not needed for the filter
    override func getSourceImage() -> UIImage? {
        let name = "style_feathers.jpg"
        let image = UIImage(named:name)
        if image == nil {
            log.error("Could not load source image: \(name)")
        }
        return image
    }
    
    // filter display name
    override func displayName() -> String {
        return "Style: Feathers"
    }
    
    // get the actual model
    override func getInputModel() -> MLModel? {
        return FNS_Feathers().model
    }
    
    // get the model size
    override func getModelSize() -> CGSize {
        return CGSize(width: 720, height: 720) // just have to know this (annoying)
    }
}
