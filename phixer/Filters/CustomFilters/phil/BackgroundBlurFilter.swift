//
//  BackgroundBlurFilter.swift
//  phixer
//
//  Created by Philip Price on 08/13/19
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

// filter to blur the background

class BackgroundBlurFilter: CIFilter {
    let fname = "Background Blur"
    var inputImage: CIImage?
    var inputRadius: CGFloat = 4.0
    
    
    // default settings
    override func setDefaults() {
        inputImage = nil
        inputRadius = 4.0
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
            
            "inputRadius": [kCIAttributeIdentity: 0,
                            kCIAttributeClass: "NSNumber",
                            kCIAttributeDefault: 4.0,
                            kCIAttributeDisplayName: "Radius",
                            kCIAttributeMin: 0,
                            kCIAttributeSliderMin: 0.5,
                            kCIAttributeSliderMax: 10.0,
                            kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }

    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputRadius":
            inputRadius = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }

    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            return nil
        }
        
        
        // generate blurred version
        let blur = inputImage.applyingFilter("CIGaussianBlur", parameters: ["inputRadius": inputRadius])
        
        // get foreground mask
        let mask = inputImage.applyingFilter("ForegroundMaskFilter")
        
        // mask original over blurred version
        let image = blur.applyingFilter("CIBlendWithMask", parameters: [kCIInputMaskImageKey: mask, kCIInputBackgroundImageKey: inputImage])

        return image
    }
}
