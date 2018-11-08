//
//  ClarityFilter.swift
//  phixer
//
//  Created by Philip Price on 10/25/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

class ClarityFilter: CIFilter {
    let fname = "Clarity"
    var inputImage: CIImage?
    var inputClarity:CGFloat = 0.2
    
    
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
                           kCIAttributeType: kCIAttributeTypeImage],
            
            "inputClarity": [kCIAttributeIdentity: 0,
                             kCIAttributeClass: "NSNumber",
                             kCIAttributeDefault: 0.2,
                             kCIAttributeDisplayName: "Clarity",
                             kCIAttributeMin: 0,
                             kCIAttributeSliderMin: 0,
                             kCIAttributeSliderMax: 1,
                             kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }
    
    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputClarity":
            inputClarity = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }

    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            return nil
        }
        
        // input -> LumaRangeFilter -> Vibrance -> LuminosityBlend -> output
        // input -> UnsharpMask -> Opacity      -^
        
        let vibrantImage = inputImage.applyingFilter("CIVibrance", parameters: ["inputAmount": 0.2])

        let contrastyImage = inputImage.applyingFilter("LumaRangeFilter", parameters: ["inputLower":0.25, "inputUpper":0.75])
            .applyingFilter("CIUnsharpMask", parameters: ["inputRadius":50, "inputIntensity":0.2])
            .applyingFilter("OpacityFilter", parameters: ["inputOpacity":inputClarity])
        
        let finalComposite = contrastyImage.applyingFilter("CILuminosityBlendMode", parameters: [kCIInputBackgroundImageKey:vibrantImage])
        return finalComposite
    }
}
