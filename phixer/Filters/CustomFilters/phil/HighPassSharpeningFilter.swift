//
//  HighPassSharpeningFilter.swift
//  phixer
//
//  Created by Philip Price on 01/29/19
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

class HighPassSharpeningFilter: CIFilter {
    let fname = "High-Pass Sharpening"
    var inputImage: CIImage?
    var inputRadius: CGFloat = 4.0
    var inputThreshold: CGFloat = 0.01


    // default settings
    override func setDefaults() {
        inputImage = nil
        inputRadius = 4.0
        inputThreshold = 0.01
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
            
            "inputRadius": [kCIAttributeIdentity: 0,
                            kCIAttributeClass: "NSNumber",
                            kCIAttributeDefault: 4.0,
                            kCIAttributeDisplayName: "Radius",
                            kCIAttributeMin: 0.0,
                            kCIAttributeSliderMin: 0.0,
                            kCIAttributeSliderMax: 50.0,
                            kCIAttributeType: kCIAttributeTypeScalar],
            
            
            "inputThreshold": [kCIAttributeIdentity: 0,
                               kCIAttributeClass: "NSNumber",
                               kCIAttributeDefault: 0.01,
                               kCIAttributeDisplayName: "Threshold",
                               kCIAttributeMin: 0,
                               kCIAttributeSliderMin: 0.001,
                               kCIAttributeSliderMax: 0.3,
                               kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }


    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputRadius":
            inputRadius = value as! CGFloat
        case "inputThreshold":
            inputThreshold = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }

    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            return nil
        }

        //        Blur (value 10) on image 1.
        //        High pass filter (value 10) on image 2.
        //        Set image 2 to 50% opacity.
        //        Add a contrast layer, set it to legacy and +50 contrast.
        //        Overlay image 2 and original
        //        Overlay or Linear Dodge Blend imag1 & image 2 (blend)
        //
        //        Luminosity or Hard Light blend with original (optional)


        /***
        let hipassImage = inputImage
            .applyingFilter("SmoothThresholdFilter", parameters: ["inputThreshold": inputThreshold])
            .applyingFilter("CIOverlayBlendMode", parameters: [kCIInputBackgroundImageKey:inputImage])
            //.applyingFilter("OpacityFilter", parameters: ["inputOpacity": 0.5])
            //.applyingFilter("ContrastFilter", parameters: ["inputContrast": 0.5])
***/
        
        let blurredImage = inputImage
            .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": inputRadius])
            .clampedToExtent()
            .cropped(to: inputImage.extent)
        
        let hipassImage = inputImage
            .applyingFilter("CISubtractBlendMode", parameters: [kCIInputBackgroundImageKey:blurredImage])
            .applyingFilter("CIOverlayBlendMode", parameters: [kCIInputBackgroundImageKey:inputImage])

        
        //return hipassImage //tmp
        
        //let sharpImage = hipassImage.applyingFilter("CIOverlayBlendMode", parameters: [kCIInputBackgroundImageKey:blurredImage])
        let sharpImage = blurredImage.applyingFilter("CILinearDodgeBlendMode", parameters: [kCIInputBackgroundImageKey:hipassImage])


        //return sharpImage // tmp
        
        let finalComposite = sharpImage
            .applyingFilter("CILuminosityBlendMode", parameters: [kCIInputBackgroundImageKey: inputImage])
            //.applyingFilter("CIMultiplyBlendMode", parameters: [kCIInputBackgroundImageKey: inputImage])

        return finalComposite
    }
}
