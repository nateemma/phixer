//
//  UnsharpMaskFilter.swift
//  phixer
//
//  Created by Philip Price on 01/04/19.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage


// implements a traditional Unsharp Mask, as you see in most (all?) image editing apps like Photoshop

class UnsharpMaskFilter: CIFilter {
    var inputImage: CIImage?
    var inputAmount: CGFloat = 0.0
    var inputRadius: CGFloat = 0.0
    var inputThreshold: CGFloat = 0.0

    private let kernel: CIColorKernel!

    // filter display name
    func displayName() -> String {
        return "Unsharp Mask"
    }

    // init
    override init() {
        
        // algorithm adapted from Wikipedia: https://en.wikipedia.org/wiki/Unsharp_masking
        
        kernel = try! CIColorKernel(source:
            "kernel vec4 combine(__sample sharpImage, __sample  blurredImage, float intensity, float threshold)" +
                "{" +
                "   float alpha = sharpImage.a);\n" +
                "   vec3 sharpImageColor = sharpImage.rgb;\n" +
                "   vec3 blurredImageColor = blurredImage.rgb;\n" +
                "   if (distance(sharpImageColor,blurredImageColor) > threshold) {\n" +
                "       vec3 result = sharpImageColor.rgb  + (sharpImageColor.rgb - blurredImageColor.rgb) * intensity;\n" +
                "       float r = clamp(result.r, 0.0, 1.0);\n" +
                "       float g = clamp(result.g, 0.0, 1.0);\n" +
                "       float b = clamp(result.b, 0.0, 1.0);\n" +
                "       return vec4(r, g, b, 1.0);\n" +
                "   } else {\n" +
                "       return sharpImage;\n" +
                "   }\n" +
                "}"
        )
        
        if kernel == nil {
            log.error("Could not create CIColorKernel")
        }
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // default settings
    override func setDefaults() {
        inputImage = nil
        inputAmount = 0.25
        inputRadius = 4.0
        inputThreshold = 0.25
    }
    
    
    // filter attributes
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: displayName(),
            
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage],
            
            "inputAmount": [kCIAttributeIdentity: 0,
                               kCIAttributeClass: "NSNumber",
                               kCIAttributeDefault: 0.25,
                               kCIAttributeDisplayName: "Amount",
                               kCIAttributeMin: 0.0,
                               kCIAttributeSliderMin: 0.0,
                               kCIAttributeSliderMax: 2.0,
                               kCIAttributeType: kCIAttributeTypeScalar],
            
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
                               kCIAttributeDefault: 0.25,
                               kCIAttributeDisplayName: "Threshold",
                               kCIAttributeMin: 0.0,
                               kCIAttributeSliderMin: 0.0,
                               kCIAttributeSliderMax: 40.0,
                               kCIAttributeType: kCIAttributeTypeScalar],
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
        case "inputThreshold":
            inputThreshold = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }

    
    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            log.error("No input image")
            return nil
        }
        
        log.debug("amount:\(inputAmount), radius:\(inputRadius), threshold:\(inputThreshold)")
        

        // create a blurred version of the input image
        let blurredImg = inputImage.applyingFilter("CIGaussianBlur", parameters: ["inputRadius": inputRadius]).clampedToExtent()
            .cropped(to: inputImage.extent)
        
        // combine the original and blurred version
        let sharpImg = kernel.apply(extent: inputImage.extent, arguments: [inputImage, blurredImg, inputAmount, inputThreshold])
        
        return sharpImg
        
        // use luminance blending to create the final image
        return sharpImg?.applyingFilter("CILuminosityBlendMode", parameters: [kCIInputBackgroundImageKey:inputImage])
    }
}
