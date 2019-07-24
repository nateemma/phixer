//
//  SplitToningFilter.swift
//  phixer
//
// Filter to emulate the Split Toning function of Lightroom/Photoshop
//
//  Created by Philip Price on 06/16/19
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import CoreImage
import UIKit


class SplitToningFilter: CIFilter {
    var inputImage: CIImage?
    var inputHighlightHue:CGFloat = 0.0
    var inputHighlightSaturation:CGFloat = 0.5
    var inputShadowHue:CGFloat = 0.1
    var inputShadowSaturation:CGFloat = 0.5

    
    // default settings
    override func setDefaults() {
        inputImage = nil
        inputHighlightHue = 0.0
        inputHighlightSaturation = 0.5
        inputShadowHue = 0.1
        inputShadowSaturation = 0.5
    }
    
    
    // filter display name
    func displayName() -> String {
        return "Split Toning"
    }
    
    
    // filter attributes
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: displayName(),
            
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage],
            
            "inputHighlightHue": [kCIAttributeIdentity: 0,
                                  kCIAttributeClass: "NSNumber",
                                  kCIAttributeDefault: 0.0,
                                  kCIAttributeDisplayName: "Highlight Hue",
                                  kCIAttributeMin: 0.0,
                                  kCIAttributeSliderMin: 0.0,
                                  kCIAttributeSliderMax: 1.0,
                                  kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputHighlightSaturation": [kCIAttributeIdentity: 0,
                                  kCIAttributeClass: "NSNumber",
                                  kCIAttributeDefault: 0.5,
                                  kCIAttributeDisplayName: "Highlight Saturation",
                                  kCIAttributeMin: 0.0,
                                  kCIAttributeSliderMin: 0.0,
                                  kCIAttributeSliderMax: 1.0,
                                  kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputShadowHue": [kCIAttributeIdentity: 0,
                                  kCIAttributeClass: "NSNumber",
                                  kCIAttributeDefault: 0.1,
                                  kCIAttributeDisplayName: "Shadow Hue",
                                  kCIAttributeMin: 0.0,
                                  kCIAttributeSliderMin: 0.0,
                                  kCIAttributeSliderMax: 1.0,
                                  kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputShadowSaturation": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "NSNumber",
                           kCIAttributeDefault: 0.5,
                           kCIAttributeDisplayName: "Shadow Saturation",
                           kCIAttributeMin: 0.0,
                           kCIAttributeSliderMin: 0.0,
                           kCIAttributeSliderMax: 1.0,
                           kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }
    
    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputHighlightHue":
            inputHighlightHue = value as! CGFloat
        case "inputHighlightSaturation":
            inputHighlightSaturation = value as! CGFloat
        case "inputShadowHue":
            inputShadowHue = value as! CGFloat
        case "inputShadowSaturation":
            inputShadowSaturation = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }

    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            log.error("No input image")
            return nil
        }
        
        // check that there is something to apply (some presets specify split toning with no values)
        guard (abs(inputShadowHue) + abs(inputShadowSaturation) + abs(inputHighlightHue) + abs(inputHighlightSaturation)) > 0.001 else {
            log.verbose("Null split toning. Ignoring")
            return inputImage
        }
        
        // for now, apply CIFalseFilter and Screen Blend to emulate the effect
        //  TODO: combine these into a kernel so that we can take the luminace value of the source pixel
        
        // Original idea taken from: https://stackoverflow.com/questions/7961929/split-tone-effect-using-core-image-filters/8092453#8092453
        // Values are the result of playing around. Taken from reference colours used in HSV filter

        let color1 = CIColor(h: inputShadowHue, s: inputShadowSaturation, v: 0.270588, alpha:0.5)
        let color2 = CIColor(h: inputHighlightHue, s: inputHighlightSaturation, v: 0.901961, alpha:0.5)
        //log.verbose("CIColor1: \(color1), CIColor2: \(color2)")

        // DBG: UIColor much more user friendly, so check colour conversion with that
        //let uicolor1 = UIColor(hue: inputHighlightHue, saturation: inputHighlightSaturation, brightness: 0.5, alpha: 1.0)
        //let uicolor2 = UIColor(hue: inputShadowHue, saturation: inputShadowSaturation, brightness: 0.5, alpha: 1.0)
        //log.verbose("UIColor1: \(uicolor1), UIColor2: \(uicolor2)")
        
        let falseImg = inputImage.applyingFilter("CIFalseColor", parameters: ["inputColor0": color1, "inputColor1": color2])

        let screenImg = falseImg.applyingFilter("CIScreenBlendMode", parameters: ["inputBackgroundImage": inputImage])
        //let screenImg = falseImg.applyingFilter("CIColorBlendMode", parameters: ["inputBackgroundImage": inputImage])
        //let screenImg = falseImg.applyingFilter("CIHueBlendMode", parameters: ["inputBackgroundImage": inputImage])
        return screenImg
        
        //return screenImg.applyingFilter("CIHueBlendMode", parameters: ["inputBackgroundImage": inputImage])
        //return screenImg.applyingFilter("CIColorBlendMode", parameters: ["inputBackgroundImage": inputImage])
        //return falseImg.applyingFilter("CIColorBlendMode", parameters: ["inputBackgroundImage": inputImage])
        //return falseImg.applyingFilter("CIHueBlendMode", parameters: ["inputBackgroundImage": inputImage])
        //return screenImg.applyingFilter("CIHueBlendMode", parameters: ["inputBackgroundImage": inputImage])

    }
}
