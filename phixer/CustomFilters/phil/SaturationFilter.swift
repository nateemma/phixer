//
//  SaturationFilter.swift
//  phixer
//
//  Created by Philip Price on 12/24/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

// filter to implement contrast adjustment (subset of CIColorFilter)

class SaturationFilter: CIFilter {
    let fname = "Saturation"
    var inputImage: CIImage?
    var inputSaturation:CGFloat = 1.0
    
    
    // default settings
    override func setDefaults() {
        inputImage = nil
        inputSaturation = 1.0
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
            
            "inputSaturation": [kCIAttributeIdentity: 0,
                             kCIAttributeClass: "NSNumber",
                             kCIAttributeDefault: 1.0,
                             kCIAttributeDisplayName: "Saturation",
                             kCIAttributeMin: 0.0,
                             kCIAttributeSliderMin: 0.0,
                             kCIAttributeSliderMax: 2.0,
                             kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }

    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputSaturation":
            inputSaturation = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }

    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            return nil
        }
        
        return inputImage.applyingFilter("CIColorControls", parameters: ["inputSaturation": inputSaturation])

    }
}
