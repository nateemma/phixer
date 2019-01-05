//
//  ColorSketchFilter.swift
//  phixer
//
//  Created by Philip Price on 01/04/19.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

class ColorSketchFilter: CIFilter {
    var inputImage: CIImage?
    var inputThreshold: CGFloat = 5.0

    private let kernel: CIKernel!
    
    
    // filter display name
    func displayName() -> String {
        return "ColorSketch Edge Detection"
    }

    // init
    override init() {
        do {

            kernel = CIKernel(source:
                "kernel vec4 sobelFilter(sampler image, float threshold) {" +
                    "  mat3 sobel_x = mat3( -1, -2, -1, 0, 0, 0, 1, 2, 1 );" +
                    "  mat3 sobel_y = mat3( 1, 0, -1, 2, 0, -2, 1, 0, -1 );" +
                    "  float s_x = 0.0;" +
                    "  float s_y = 0.0;" +
                    "  vec2 dc = destCoord();" +
                    "  for (int i=-1; i <= 1; i++) {" +
                    "    for (int j=-1; j <= 1; j++) {" +
                    "      vec4 currentSample = sample(image, samplerTransform(image, dc + vec2(i,j)));" +
                    "      s_x += sobel_x[j+1][i+1] * currentSample.g;" +
                    "      s_y += sobel_y[j+1][i+1] * currentSample.g;" +
                    "    }" +
                    "  }" +
                    "  return vec4(s_x, s_y, 0.0, 1.0);" +
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
        inputThreshold = 5.0
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
                               kCIAttributeDefault: 1.0,
                               kCIAttributeDisplayName: "Threshold",
                               kCIAttributeMin: 0,
                               kCIAttributeSliderMin: 0.0,
                               kCIAttributeSliderMax: 2.0,
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
        
        log.debug("threshold: \(inputThreshold)")
        let extent = inputImage.extent
        let arguments = [inputImage, inputThreshold] as [Any]
        
        let edgeImage =  kernel.apply(extent: extent,
                                      roiCallback: { (index, rect) in return rect },
                                      arguments: arguments)
        
        return edgeImage?.applyingFilter("CIColorInvert")
    }
}
