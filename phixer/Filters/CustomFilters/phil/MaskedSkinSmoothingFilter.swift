//
//  MaskedSkinSmoothingFilter.swift
//  phixer
//
//  Created by Philip Price on 02/27/19
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

// filter that masks skin based on a supplied colour, then applies skin smoothing and overlays oit back on the original image
class MaskedSkinSmoothingFilter: CIFilter {
    
    let fname = "Masked Skin Smoothing"
    private static let defaultColor = CIColor(red: 1.0, green: 206/255, blue: 180/255, alpha: 1.0) // typical (N.European) Caucasian skin colour

    var inputImage: CIImage? = nil
    var inputAmount: CGFloat = 1.0
    var inputRadius: CGFloat = 16.0
    var inputSharpnessFactor: CGFloat = 0.6
    var inputToneCurveControlPoints: [CIVector] = []
    var inputColor:CIColor = MaskedSkinSmoothingFilter.defaultColor
    var inputVariance:CGFloat = 0.4


    // default settings
    override func setDefaults() {
        log.verbose("Setting defaults")
        inputImage = nil
        inputAmount = 1.0
        inputRadius = 16.0
        inputSharpnessFactor = 0.6
        inputToneCurveControlPoints = [CIVector(x: 0, y: 0),
                                       CIVector(x: 120/255.0, y: 146/255.0),
                                       CIVector(x: 1.0, y: 1.0)]
        inputColor = MaskedSkinSmoothingFilter.defaultColor
        inputVariance = 0.4
    }


    // filter display name
    func displayName() -> String {
        return fname
    }


    // filter attributes
    override var attributes: [String: Any] {
        return [
            kCIAttributeFilterDisplayName: displayName(),
            
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage],
            
            "inputAmount": [kCIAttributeIdentity: 0,
                            kCIAttributeClass: "NSNumber",
                            kCIAttributeDefault: 1.0,
                            kCIAttributeDisplayName: "Amount",
                            kCIAttributeMin: 0,
                            kCIAttributeSliderMin: 0,
                            kCIAttributeSliderMax: 2,
                            kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputRadius": [kCIAttributeIdentity: 0,
                            kCIAttributeClass: "NSNumber",
                            kCIAttributeDefault: 16,
                            kCIAttributeDisplayName: "Radius",
                            kCIAttributeMin: 0,
                            kCIAttributeSliderMin: 0,
                            kCIAttributeSliderMax: 40,
                            kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputSharpnessFactor": [kCIAttributeIdentity: 0,
                                     kCIAttributeClass: "NSNumber",
                                     kCIAttributeDefault: 0.6,
                                     kCIAttributeDisplayName: "Sharpness",
                                     kCIAttributeMin: 0,
                                     kCIAttributeSliderMin: 0,
                                     kCIAttributeSliderMax: 2,
                                     kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputToneCurveControlPoints": [kCIAttributeIdentity: 0,
                                            kCIAttributeClass: "NSArray<CIVector *> *",
                                            kCIAttributeDefault: 1,
                                            kCIAttributeDisplayName: "Control Points",
                                            kCIAttributeMin: 0,
                                            kCIAttributeSliderMin: 0,
                                            kCIAttributeSliderMax: 1,
                                            kCIAttributeType: kCIAttributeTypePosition3],
            
            "inputColor": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIColor",
                           kCIAttributeDefault: CIColor(red: 1.0, green: 206/255, blue: 180/255, alpha: 1.0),
                           kCIAttributeDisplayName: "Base Color",
                           kCIAttributeMin: 0,
                           kCIAttributeSliderMin: 0,
                           kCIAttributeSliderMax: 0,
                           kCIAttributeType: kCIAttributeTypeColor],
            
            "inputVariance": [kCIAttributeIdentity: 0,
                              kCIAttributeClass: "NSNumber",
                              kCIAttributeDefault: 0.1,
                              kCIAttributeDisplayName: "Variance",
                              kCIAttributeMin: 0,
                              kCIAttributeSliderMin: 0.001,
                              kCIAttributeSliderMax: 0.99,
                              kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }


    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputAmount":
            inputAmount = value as! CGFloat
        case "inputRadius":
            inputRadius = value as! CGFloat
        case "inputSharpnessFactor":
            inputSharpnessFactor = value as! CGFloat
        case "inputToneCurveControlPoints":
            inputToneCurveControlPoints = value as! [CIVector]
        case "inputColor":
            inputColor = value as! CIColor
        case "inputVariance":
            inputVariance = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }
    
    override func value(forKey key: String) -> Any? {
        switch key {
        case "inputImage":
            return inputImage
        case "outputImage":
            return outputImage
        case "inputAmount":
            return inputAmount
        case "inputRadius":
            return inputRadius
        case "inputSharpnessFactor":
            return inputSharpnessFactor
        case "inputToneCurveControlPoints":
            return inputToneCurveControlPoints
        case "inputColor":
            return inputColor
        case "inputVariance":
            return inputVariance
        default:
            log.error("Invalid key: \(key)")
            return nil
        }
    }

    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            log.error("NIL input image")
            return nil
        }


        // get the skin mask
        let skinMask = inputImage
            .applyingFilter("HueRangeFilter", parameters: ["inputColor": inputColor, "inputVariance": inputVariance])
        
        //return skinMask // tmp
        
       // smooth the masked image
        let smoothedImage = skinMask
            .applyingFilter("HighPassSkinSmoothingFilter",
                            parameters: ["inputAmount": inputAmount, "inputRadius": inputRadius, "inputSharpnessFactor": inputSharpnessFactor, "inputToneCurveControlPoints": inputToneCurveControlPoints])
        //return smoothedImage // tmp

        // blend with original
        let finalComposite = smoothedImage.applyingFilter("CISourceOverCompositing", parameters: [kCIInputBackgroundImageKey:inputImage])


        return finalComposite
    }
}
