//
//  SmoothThresholdFilter.swift
//  phixer
//
//  Created by Philip Price on 10/25/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

class LumaRangeFilter: CIFilter {
    var inputImage: CIImage?
    var inputLower:CGFloat = 0.02
    var inputUpper:CGFloat = 0.05

    let kernel = CIColorKernel(source:
        "kernel vec4 lumaRangeFilter(__sample image, float lower, float upper) {" +
        "float luma = dot(image.rgb, vec3(0.2126, 0.7152, 0.0722));" +
        "vec4 result = ((luma>=lower) && (luma<=upper)) ? image : vec4(0.0);" +
        "return result;" +
        "}"
    )
    
    // default settings
    override func setDefaults() {
        inputImage = nil
    }
    
    
    // filter display name
    func displayName() -> String {
        return "Luma Range"
    }
    
    
    // filter attributes
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: displayName(),
            
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage],
            
            "inputLower": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "NSNumber",
                           kCIAttributeDefault: 0.25,
                           kCIAttributeDisplayName: "Lower",
                           kCIAttributeMin: 0,
                           kCIAttributeSliderMin: 0,
                           kCIAttributeSliderMax: 0.9,
                           kCIAttributeType: kCIAttributeTypeScalar]
            ,
            
            "inputUpper": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "NSNumber",
                           kCIAttributeDefault: 0.75,
                           kCIAttributeDisplayName: "Upper",
                           kCIAttributeMin: 0,
                           kCIAttributeSliderMin: 0.01,
                           kCIAttributeSliderMax: 1.0,
                           kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }
    
    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputLower":
            inputUpper = value as! CGFloat
        case "inputUpper":
            inputUpper = value as! CGFloat
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
        let arguments = [inputImage, inputLower, inputUpper] as [Any]
        
        return kernel.apply(extent: extent, arguments: arguments)
    }
}
