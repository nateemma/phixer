//
//  Sobel5x5Filter.swift
//  phixer
//
//  Created by Philip Price on 01/04/19.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

class Sobel5x5Filter: CIFilter {
    var inputImage: CIImage?
    var inputThreshold: CGFloat = 0.0
    
    private let kernel: CIColorKernel!

    // filter display name
    func displayName() -> String {
        return "Sobel 5x5"
    }

    // init
    override init() {

        
        //TODO: 1. use luma value instead of rgb value
        //      2. calc gradient and compare against threshold
        //      3. use smoothstep instead of black/white
        
        kernel = try! CIColorKernel(source:
            "kernel vec4 combineXY(__sample image1, __sample image2, float threshold)" +
                "{" +
                "   float luma1 = dot(vec3(0.2126, 0.7152, 0.0722), image1.rgb);\n" +
                "   float luma2 = dot(vec3(0.2126, 0.7152, 0.0722), image2.rgb);\n" +
                "   float h = length(image1.rgb);\n" +
                "   float v = length(image2.rgb);\n" +
                //"   float d = length(vec2(h,v)) * threshold;\n" +
                "   float d = length(vec2(luma1,luma2));\n" +
                "   if (d > threshold) {\n" +
                "       return vec4(vec3(d), 1);\n" +
                "   } else {\n" +
                "       return vec4(vec3(0.0), 1);\n" +
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
        inputThreshold = 0.5
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
                               kCIAttributeDefault: 0.5,
                               kCIAttributeDisplayName: "Threshold",
                               kCIAttributeMin: 0.0,
                               kCIAttributeSliderMin: 0.01,
                               kCIAttributeSliderMax: 1.0,
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
        guard let inputImage = inputImage else {
            log.error("No input image")
            return nil
        }
        
        log.debug("threshold: \(inputThreshold)")
        
        // using Accelerate, CIConvolution filters don't seem to work...
        let  cgimage = inputImage.getCGImage(size:inputImage.extent.size)
        
        /*** One-pass matrices
        // Sobel convolution matrix (there are various possible sets)
        let m3_1:[Int16] = [0, -2, -2,
                            2,  0, -2,
                            2,  2,  0]
        let m3_2:[Int16] = [ 0, -2, 2,
                            -4,  0, 4,
                            -2,  0, 2]
        let m5_1:[Int16] = [  0,   4,  10,  12,  10,
                             -4,   0,  20,  20,  12,
                            -10, -20,   0,  20,  12,
                            -12, -20, -20,   0,   4,
                            -10, -12, -10,  -4,   0
                           ]
        let outCGImage = cgimage?.applyConvolution(matrix: m3_1, divisor: 1)
         
                 // return the corresponding CIImage
        if outCGImage != nil {
            return CIImage(cgImage: outCGImage)
        } else {
            return nil
        }
         **/
        
        // Two-pass (x and y) matrices

        let m5_1_x:[Int16] = [-5,  -4,  0,  4,  5,
                              -8, -10,  0,  8, 10,
                             -10, -20,  0, 20, 10,
                              -8, -10,  0,  8, 10,
                              -5,  -4,  0,  4,  5
                             ]
        
        let m5_1_y:[Int16] = [ 5,   8,  10,  8,   5,
                               4,  10,  20,  10,  4,
                               0,   0,   0,   0,  0,
                              -4, -10, -20, -10, -4,
                              -5,  -8, -10,  -8, -5
                               ]
        
        let ciimage_x = CIImage(cgImage: (cgimage?.applyConvolution(matrix: m5_1_x, divisor: 1))!)
        let ciimage_y = CIImage(cgImage: (cgimage?.applyConvolution(matrix: m5_1_y, divisor: 1))!)

        let extent = inputImage.extent
        let arguments = [ciimage_x, ciimage_y, inputThreshold] as [Any]
        return  kernel.apply(extent: extent, arguments: arguments)
        
    }
}
