//
//  ForegroundMaskFilter.swift
//  phixer
//
//  Created by Philip Price on 08/13/19
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

// filter to create a foreground mask from an image. Items in the foreground are non-black (greyscale)

class ForegroundMaskFilter: CIFilter {
    let fname = "Foreground Mask"
    var inputImage: CIImage?
    
    
    // default settings
    override func setDefaults() {
        inputImage = nil
    }
    
    
    // filter display name
    func displayName() -> String {
        return fname
    }
    
    
    // filter attributes
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: displayName(),
            
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage]
        ]
    }

    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        default:
            log.error("Invalid key: \(key)")
        }
    }

    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            return nil
        }
        
        //TODO: check to see if portrait matte is available first
        
        // TODO: play with radius parameter
        let radius:CGFloat = 2.0
        let threshold:CGFloat = 0.001
        let foregroundMask = inputImage
            .applyingFilter("CIHeightFieldFromMask", parameters: ["inputRadius":radius])
            //.applyingFilter("SmoothThresholdFilter", parameters: ["inputThreshold":threshold])
            //.applyingFilter("CIColorInvert")
            .applyingFilter("CIPhotoEffectMono")
            .applyingFilter("LumaRangeFilter", parameters: ["inputLower": 0.005, "inputUpper": 1.1])
        
        return foregroundMask
    }
}
