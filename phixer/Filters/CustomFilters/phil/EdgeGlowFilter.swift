//
//  EdgeGlowFilter.swift
//  phixer
//
//  Created by Philip Price on 10/25/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

class EdgeGlowFilter: CIFilter {
    var inputImage: CIImage?
    
    
    // default settings
    override func setDefaults() {
        inputImage = nil
    }
    
    
    // filter display name
    func displayName() -> String {
        return "Edge Glow"
    }
    
    
    // filter attributes
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: displayName(),
            
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage]
        ]
    }
    
    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        default:
            log.error("Invalid key: \(key)")
        }
    }

    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            return nil
        }
        let extent = inputImage.extent
        let edgesImage = inputImage.applyingFilter("CIEdges", parameters: [kCIInputIntensityKey: 10])
        let glowingImage = CIFilter(name: "CIColorControls", parameters: [kCIInputImageKey: edgesImage, kCIInputSaturationKey: 1.75])?
                                   .outputImage?.applyingFilter("CIBloom", parameters: [kCIInputRadiusKey: 2.5, kCIInputIntensityKey: 1.25])
                                   .cropped(to: extent)
        let darkImage = inputImage.applyingFilter("CIPhotoEffectNoir", parameters: [:])
                                  .applyingFilter("CIExposureAdjust", parameters: ["inputEV": -1.5])
        let finalComposite = glowingImage!.applyingFilter("CIAdditionCompositing", parameters: [kCIInputBackgroundImageKey:darkImage])
        return finalComposite
    }
}
