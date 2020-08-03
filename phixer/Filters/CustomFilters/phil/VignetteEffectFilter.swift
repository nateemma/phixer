//
//  VignetteEffectFilter.swift
//  phixer
//
//  Created by Philip Price on 09/11/2019.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

// this is a wrapper for the CIVignetteEffect filter that takes relative position and distance (0..1) instead of pixel values.
// Why on earth did Apple make the parameters image-dependent (so you can't apply the same values to different images and get the same effect)?!

class VignetteEffectFilter: CIFilter {
    let fname = "VignetteEffect"
    var inputImage: CIImage?
    var inputCentre: CIVector = CIVector(x: 0.5, y: 0.5)
    var inputRadius: CGFloat = 0.5
    var inputIntensity: CGFloat = 0.5
    var inputFalloff: CGFloat = 0.5
    
    
    // default settings
    override func setDefaults() {
        inputImage = nil
        inputCentre = CIVector(x: 0.5, y: 0.5)
        inputRadius = 0.5
        inputIntensity = 0.5
        inputFalloff = 0.5
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
            
            "inputCentre": [kCIAttributeIdentity: 0,
                                    kCIAttributeDisplayName: "Center",
                                    kCIAttributeClass: "CIVector",
                                    kCIAttributeDefault: CIVector(x: 0.5, y: 0.5),
                                    kCIAttributeType: kCIAttributeTypePosition],
            
            "inputRadius": [kCIAttributeIdentity: 0,
                                    kCIAttributeClass: "NSNumber",
                                    kCIAttributeDefault: 0.0,
                                    kCIAttributeDisplayName: "Radius",
                                    kCIAttributeMin: -1.0,
                                    kCIAttributeSliderMin: -1.0,
                                    kCIAttributeSliderMax: 1.0,
                                    kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputIntensity": [kCIAttributeIdentity: 0,
                               kCIAttributeClass: "NSNumber",
                               kCIAttributeDefault: 0.5,
                               kCIAttributeDisplayName: "Intensity",
                               kCIAttributeMin: 0.0,
                               kCIAttributeSliderMin: 0.0,
                               kCIAttributeSliderMax: 1.0,
                               kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputFalloff": [kCIAttributeIdentity: 0,
                               kCIAttributeClass: "NSNumber",
                               kCIAttributeDefault: 0.5,
                               kCIAttributeDisplayName: "Falloff",
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
        case "inputCentre":
            inputCentre = value as! CIVector
        case "inputRadius":
            inputRadius = value as! CGFloat
        case "inputIntensity":
            inputIntensity = value as! CGFloat
        case "inputFalloff":
            inputFalloff = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }

    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            return nil
        }
        
        // convert centre position and radius to pixel values
        return inputImage.applyingFilter("CIVignetteEffect", parameters: [ "inputCenter": centre,
                                                                           "inputRadius": radius,
                                                                           "inputIntensity": inputIntensity,
                                                                           "inputFalloff": inputFalloff ]

    }
}
