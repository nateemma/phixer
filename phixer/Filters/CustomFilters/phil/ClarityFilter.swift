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
        
       // let contrastMask = inputImage.applyingFilter("LumaRangeFilter", parameters: ["inputLower":0.1, "inputUpper":0.8])
       //     .applyingFilter("CIColorInvert")
        
        //return contrastMask // tmp dbg
        
        let contrastyImage = inputImage
            .applyingFilter("CIVibrance", parameters: ["inputAmount": 0.2*factor])
            .applyingFilter("UnsharpMaskFilter", parameters: ["inputAmount":0.25, "inputRadius":50, "inputThreshold":0])
            .applyingFilter("OpacityFilter", parameters: ["inputOpacity":inputClarity])
        
        /****
         
        //TODO: the following is good, but the edges are too distinct
        let midtoneMask = contrastyImage
            .applyingFilter("LumaRangeFilter", parameters: ["inputLower":0.1, "inputUpper":0.95])
            .applyingFilter("CIColorInvert")
        
        // overlay the midtones on the original
        let midtoneImg = contrastyImage.applyingFilter("CIBlendWithMask", parameters: [kCIInputMaskImageKey: midtoneMask, kCIInputBackgroundImageKey: inputImage])

        let finalComposite = contrastyImage.applyingFilter("CILuminosityBlendMode", parameters: [kCIInputBackgroundImageKey:midtoneImg])
         ***/
        let finalComposite = contrastyImage.applyingFilter("CILuminosityBlendMode", parameters: [kCIInputBackgroundImageKey:inputImage])

        return finalComposite
    }
}
