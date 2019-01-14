//
//  BrightnessFilter.swift
//  phixer
//
//  Created by Philip Price on 12/24/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

// filter to implement contrast adjustment (subset of CIColorFilter)

class BrightnessFilter: CIFilter {
    let fname = "Brightness"
    var inputImage: CIImage?
    var inputBrightness:CGFloat = 0.0
    
    
    // default settings
    override func setDefaults() {
        inputImage = nil
        inputBrightness = 0.0
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
                           kCIAttributeType: kCIAttributeTypeImage],
            
            "inputBrightness": [kCIAttributeIdentity: 0,
                             kCIAttributeClass: "NSNumber",
                             kCIAttributeDefault: 0.0,
                             kCIAttributeDisplayName: "Brightness",
                             kCIAttributeMin: -1.0,
                             kCIAttributeSliderMin: -1.0,
                             kCIAttributeSliderMax: 1.0,
                             kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }

    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputBrightness":
            inputBrightness = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }

    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            return nil
        }
        
        return inputImage.applyingFilter("CIColorControls", parameters: ["inputBrightness": inputBrightness])

    }
}
