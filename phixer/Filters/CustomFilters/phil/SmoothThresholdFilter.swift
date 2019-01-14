//
//  SmoothThresholdFilter.swift
//  phixer
//
//  Created by Philip Price on 10/25/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

class SmoothThresholdFilter: CIFilter {
    var inputImage: CIImage?
    //var inputEdgeO: CGFloat = 0.025
    //var inputEdge1: CGFloat = 0.075
    var inputThreshold:CGFloat = 0.05
    
    let kernel = CIColorKernel(source:
        "kernel vec4 crtColor(__sample image, float threshold) \n" +
            "{ \n" +
            "    float luma = dot(image.rgb, vec3(0.2126, 0.7152, 0.0722));" +
            "    float t = smoothstep(threshold-0.001, threshold+0.001, luma);" +
            "    return vec4(t, t, t, 1.0);" +
    "}"
    )
    
    // default settings
    override func setDefaults() {
        inputImage = nil
        inputThreshold = 0.05
    }
    
    
    // filter display name
    func displayName() -> String {
        return "Smooth Threshold"
    }
    
    
    // filter attributes
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: displayName(),
            
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage],
            
            "inputThreshold": [kCIAttributeIdentity: 0,
                             kCIAttributeClass: "NSNumber",
                             kCIAttributeDefault: 0.05,
                             kCIAttributeDisplayName: "Threshold",
                             kCIAttributeMin: 0,
                             kCIAttributeSliderMin: 0,
                             kCIAttributeSliderMax: 0.1,
                             kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }
    
    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputThreshold":
            inputThreshold = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }

    override var outputImage: CIImage? {
        guard let inputImage = inputImage, let kernel = kernel else {
            log.error("No input image")
            return nil
        }
        
        //TODO: allow setting of thresholds, or use average luminance of the input image
        
        let extent = inputImage.extent
        let arguments = [inputImage, inputThreshold] as [Any]
        
        return kernel.apply(extent: extent, arguments: arguments)
    }
}
