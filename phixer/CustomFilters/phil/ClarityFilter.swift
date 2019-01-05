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
        inputClarity = 0.2
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
        
        let factor:CGFloat = (1.0+inputClarity)
        
       let vibrantImage = inputImage.applyingFilter("CIVibrance", parameters: ["inputAmount": 0.2*factor])
        
        let contrastyImage = inputImage.applyingFilter("LumaRangeFilter", parameters: ["inputLower":0.25, "inputUpper":0.75])
            .applyingFilter("CIUnsharpMask", parameters: ["inputRadius":50, "inputIntensity":0.25])
            .applyingFilter("CISharpenLuminance", parameters: ["inputSharpness":0.4*factor])
            .applyingFilter("OpacityFilter", parameters: ["inputOpacity":inputClarity])
        
        log.debug("c:\(inputClarity) f:\(factor) v:\(0.2*factor) s:\(0.4*factor)")
        
        let finalComposite = contrastyImage.applyingFilter("CIAdditionCompositing", parameters: [kCIInputBackgroundImageKey:vibrantImage])
        //let finalComposite = vibrantImage.applyingFilter("CIAdditionCompositing", parameters: [kCIInputBackgroundImageKey:contrastyImage])
        //let finalComposite = contrastyImage.applyingFilter("CIOverlayBlendMode", parameters: [kCIInputBackgroundImageKey:vibrantImage])
        //let finalComposite = contrastyImage.applyingFilter("CISourceOverCompositing", parameters: [kCIInputBackgroundImageKey:vibrantImage])
        //let finalComposite = vibrantImage.applyingFilter("CILuminosityBlendMode", parameters: [kCIInputBackgroundImageKey:contrastyImage])

        return finalComposite
    }
}
