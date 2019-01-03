//
//  DehazeFilter.swift
//  phixer
//
//  Created by Philip Price on 12/26/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

class DehazeFilter: CIFilter {
    private static let defaultColor = CIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    var inputImage: CIImage?
    lazy var inputColor:CIColor = DehazeFilter.defaultColor
    var inputDistance:CGFloat = 0.2
    var inputSlope:CGFloat = 0.0

    let kernel = CIColorKernel(source:
        "kernel vec4 dehazeKernel(sampler src, __color color, float distance, float slope) {" +
        "vec4   t;" +
        "float  d;" +
        "d = destCoord().y * slope  +  distance;" +
        "t = unpremultiply(sample(src, samplerCoord(src)));" +
        "t = (t - d*color) / (1.0-d);" +
        "return premultiply(t);" +
        "}"
    )
    
    // default settings
    override func setDefaults() {
        inputImage = nil
        inputColor = DehazeFilter.defaultColor
        inputDistance = 0.2
        inputSlope = 0.0
    }
    
    
    // filter display name
    func displayName() -> String {
        return "Dehaze"
    }
    

    
    // filter attributes
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: displayName(),
            
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage],
            
            "inputDistance": [kCIAttributeIdentity: 0,
                              kCIAttributeDisplayName: "Distance",
                           kCIAttributeClass: "NSNumber",
                           kCIAttributeDefault: 0.2,
                           kCIAttributeMin: 0.0,
                           kCIAttributeMax: 1.0,
                           kCIAttributeSliderMin: 0,
                           kCIAttributeSliderMax: 0.7,
                           kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputSlope": [kCIAttributeIdentity: 0,
                           kCIAttributeDisplayName: "Slope",
                           kCIAttributeClass: "NSNumber",
                           kCIAttributeDefault: 0.0,
                           kCIAttributeMin: -0.01,
                           kCIAttributeMax: 0.01,
                           kCIAttributeSliderMin: -0.01,
                           kCIAttributeSliderMax: 0.01,
                           kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputColor": [kCIAttributeIdentity: 0,
                           kCIAttributeDisplayName: "Color",
                           kCIAttributeClass: "CIColor",
                           kCIAttributeDefault: DehazeFilter.defaultColor,
                           kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }
    

    override func value(forKey key: String) -> Any? {
        switch key {
        case "inputImage":
            return inputImage
        case "inputDistance":
            return inputDistance
        case "inputSlope":
            return inputSlope
        case "inputColor":
            return inputColor
        default:
            log.error("Invalid key: \(key)")
            return nil
        }
    }

    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputDistance":
            inputDistance = value as! CGFloat
        case "inputSlope":
            inputSlope = value as! CGFloat
        case "inputColor":
            inputColor = value as! CIColor
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
        let arguments = [inputImage, inputColor, inputDistance, inputSlope] as [Any]
        
        return kernel.apply(extent: extent, arguments: arguments)
    }
}
