//
//  ForegroundLightingFilter.swift
//  phixer
//
//  Created by Philip Price on 08/13/19
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

// filter to blur the background

class ForegroundLightingFilter: CIFilter {
    let fname = "Foreground Lighting"
    var inputImage: CIImage?
    var inputForeground: CGFloat = 0.1
    var inputBackground: CGFloat = -0.2

    
    // default settings
    override func setDefaults() {
        inputImage = nil
        inputForeground = 0.1
        inputBackground = -0.2
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
            
            "inputForeground": [kCIAttributeIdentity: 0,
                            kCIAttributeClass: "NSNumber",
                            kCIAttributeDefault: 0.1,
                            kCIAttributeDisplayName: "Foreground",
                            kCIAttributeMin: 0,
                            kCIAttributeSliderMin: 0.0,
                            kCIAttributeSliderMax: 1.0,
                            kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputBackground": [kCIAttributeIdentity: 0,
                            kCIAttributeClass: "NSNumber",
                            kCIAttributeDefault: -0.2,
                            kCIAttributeDisplayName: "Background",
                            kCIAttributeMin: -4.0,
                            kCIAttributeSliderMin: -4.0,
                            kCIAttributeSliderMax: 0.0,
                            kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }

    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputForeground":
            inputForeground = value as! CGFloat
        case "inputBackground":
            inputBackground = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }

    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            return nil
        }
        
        // get foreground mask
        let mask = inputImage.applyingFilter("ForegroundMaskFilter")
        
        // generate light & dark versions
        let lightImg = inputImage.applyingFilter("CIHighlightShadowAdjust", parameters: ["inputShadowAmount": inputForeground, "inputHighlightAmount": 0.9])
        let darkImg = inputImage.applyingFilter("CIExposureAdjust", parameters: ["inputEV": inputBackground])
        
        // mask light over dark version
        let image = darkImg.applyingFilter("CIBlendWithMask", parameters: [kCIInputMaskImageKey: mask, kCIInputBackgroundImageKey: lightImg])

        return image
    }
}
