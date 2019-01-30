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


        
        let hipassImage = inputImage
            .applyingFilter("HighPassFilter", parameters: ["inputRadius": inputRadius])

        
        //return hipassImage //tmp
        
        let sharpImage = hipassImage.applyingFilter("CIOverlayBlendMode", parameters: [kCIInputBackgroundImageKey:inputImage])
        //let sharpImage = hipassImage.applyingFilter("CIHardLightBlendMode", parameters: [kCIInputBackgroundImageKey:inputImage]) // intense, may use this in some other way


        //return sharpImage // tmp
        
        let finalComposite = sharpImage
            .applyingFilter("CILuminosityBlendMode", parameters: [kCIInputBackgroundImageKey: inputImage])

        return finalComposite
    }
}
