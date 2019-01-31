//
//  HighPassFilter.swift
//  phixer
//
//  Created by Philip Price on 10/25/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage


// implements a high pass filter. Note that the output is grey toned, and intended for use with filters such as OverlayBlend and the "LightBlend" family (mid grey is ignored)
class HighPassFilter: CIFilter {
    var inputImage: CIImage?
    var inputRadius: CGFloat = 10.0

    private let kernel: CIColorKernel!

    override init() {
        do {
            kernel = try! CIColorKernel(source:
                "kernel vec4 highpass(__sample image, __sample gaussianBlurredImage) \n" +
                    "{ \n" +
                    "    vec3 highpass = image.rgb - gaussianBlurredImage.rgb + vec3(0.5,0.5,0.5);\n" +
                    "    float luma = dot(highpass, vec3(0.2126, 0.7152, 0.0722));\n" +
                    "    return vec4(luma, luma, luma, 1.0);\n" +
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
        inputRadius = 10.0
    }
    
    
    // filter display name
    func displayName() -> String {
        return "High Pass Filter"
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
                            kCIAttributeDefault: 10.0,
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
        guard let inputImage = inputImage, let kernel = kernel else {
            log.error("No input image")
            return nil
        }
        
        let blurredImage = inputImage
            .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": inputRadius])
            .clampedToExtent()
            .cropped(to: inputImage.extent)

        if blurredImage == nil {
            log.error("NIL blurred image")
        }

        //return blurredImage // tmp
        let extent = inputImage.extent
        let arguments = [inputImage, blurredImage] as [Any]
        
        return kernel.apply(extent: extent, arguments: arguments)
    }
}
