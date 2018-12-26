//
//  ContrastFilter.swift
//  phixer
//
//  Created by Philip Price on 12/24/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

// filter to implement contrast adjustment (subset of CIColorFilter)

class ContrastFilter: CIFilter {
    let fname = "Contrast"
    var inputImage: CIImage?
    var inputContrast:CGFloat = 1.0
    
    
    // default settings
    override func setDefaults() {
        inputImage = nil
        inputContrast = 1.0
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
            
            "inputContrast": [kCIAttributeIdentity: 0,
                             kCIAttributeClass: "NSNumber",
                             kCIAttributeDefault: 1.0,
                             kCIAttributeDisplayName: "Contrast",
                             kCIAttributeMin: 0.25,
                             kCIAttributeSliderMin: 0.25,
                             kCIAttributeSliderMax: 4.0,
                             kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }

    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputContrast":
            inputContrast = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }

    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            return nil
        }
        
        return inputImage.applyingFilter("CIColorControls", parameters: ["inputContrast": inputContrast])

    }
}
