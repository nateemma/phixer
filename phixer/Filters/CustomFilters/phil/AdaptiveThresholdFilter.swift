//
//  AdaptiveThresholdFilter.swift
//  phixer
//
//  Created by Philip Price on 10/25/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

class AdaptiveThresholdFilter: CIFilter {
    var inputImage: CIImage?
    var inputRadius: CGFloat = 5.0

    //var kernel:CIKernel? = nil
    private let kernel: CIColorKernel!
    //private let kernel: CIKernel!

    // init
    override init() {
        do {
            kernel = try! CIColorKernel(source:
                "kernel vec4 thresholdFilter(__sample image, __sample threshold)" +
                    "{" +
                    "   float imageLuma = dot(image.rgb, vec3(0.2126, 0.7152, 0.0722));" +
                    "   float thresholdLuma = dot(threshold.rgb, vec3(0.2126, 0.7152, 0.0722));" +
                    "   float t = smoothstep(thresholdLuma-0.002, imageLuma+0.003, imageLuma);" +
                    "   return vec4(vec3(t), 1);" +
                "}"
            )
            
            if kernel == nil {
                log.error("Could not create CIColorKernel")
            }
        } catch {
            log.error("Could not create filter. Error: \(error)")
        }
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // default settings
    override func setDefaults() {
        inputImage = nil
        inputRadius = 5.0
    }
    
    
    // filter display name
    func displayName() -> String {
        return "Adaptive Threshold"
    }
    
    
    // filter attributes
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: displayName(),
            
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage],
            
            "inputRadius": [kCIAttributeIdentity: 0,
                               kCIAttributeClass: "NSNumber",
                               kCIAttributeDefault: 5.0,
                               kCIAttributeDisplayName: "Radius",
                               kCIAttributeMin: 0,
                               kCIAttributeSliderMin: 0.5,
                               kCIAttributeSliderMax: 10.0,
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
        guard let inputImage = inputImage, let kernel = kernel else {
            log.error("No input image")
            return nil
        }
        
        let blurred = inputImage.applyingFilter("CIBoxBlur", parameters: [kCIInputRadiusKey: inputRadius]) // block size
        let extent = inputImage.extent
        let arguments = [inputImage, blurred]
        return kernel.apply(extent: extent, arguments: arguments)
    }
}
