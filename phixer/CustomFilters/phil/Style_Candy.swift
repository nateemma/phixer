//
//  Style_Candy.swift
//  Implements a Fast Neural Style transfer filter, based on "Candy" by somebody famous
//
//  Created by Philip Price on 10/25/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage
import CoreML
import UIKit

class Style_Candy: StyleTransferFilter {
    
    // returns the source image used to create the model. This is just to support UIs, not needed for the filter
    override func getSourceImage() -> UIImage? {
        return UIImage(named:"style_candy.jpg")
    }
    
    // filter display name
    override func displayName() -> String {
        return "Style: Candy"
    }
    
    // get the actual model
    override func getInputModel() -> MLModel? {
        return FNS_Candy_1().model
    }
    
    // get the model size
    override func getModelSize() -> CGSize {
        return CGSize(width: 720, height: 720) // just have to know this (annoying)
    }
}
