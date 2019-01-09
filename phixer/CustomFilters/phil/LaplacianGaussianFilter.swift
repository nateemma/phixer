//
//  LaplacianGaussianFilter.swift
//  phixer
//
//  Created by Philip Price on 01/04/19.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

class LaplacianGaussianFilter: CIFilter {
    var inputImage: CIImage?
    var inputThreshold: CGFloat = 0.0
    
    
    // filter display name
    func displayName() -> String {
        return "Laplacian Gaussian Edge Detection"
    }

    // init
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // default settings
    override func setDefaults() {
        inputImage = nil
        inputThreshold = 0.0
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
                               kCIAttributeDefault: 0.0,
                               kCIAttributeDisplayName: "Threshold",
                               kCIAttributeMin: -1.0,
                               kCIAttributeSliderMin: -1.0,
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

        /*** Using CIFilters:
        let arr: [CGFloat] = [  0,  0,  -1,  0,  0,
                                0, -1,  -2, -1,  0,
                               -1, -2, -16, -2, -1,
                                0, -1,  -2, -1,  0,
                                0,  0,  -1,  0,  0
                               ]

        let weights = CIVector(values: arr, count: 25)

        let tmpImg = inputImage.applyingFilter("CIConvolution5X5", parameters: ["inputWeights": weights, "inputBias": inputThreshold])
        
        let rgba:[CGFloat] = [0.0, 0.0, 0.0, 1.0]
        let alphaVector = CIVector(values: rgba, count: 4)
        return tmpImg.applyingFilter("CIColorMatrix", parameters:["inputAVector": alphaVector])
        ***/
        
        
        // using Accelerate:
        let  cgimage = inputImage.getCGImage(size:inputImage.extent.size)
        let matrix:[Int16] = [   0,  0,  -1,  0,  0,
                                 0, -1,  -2, -1,  0,
                                -1, -2,  16, -2, -1,
                                 0, -1,  -2, -1,  0,
                                 0,  0,  -1,  0,  0
                             ]
        let outCGImage = cgimage?.applyConvolution(matrix: matrix, divisor: 1)
        if outCGImage != nil {
            return CIImage(cgImage: outCGImage!)
        } else {
            return nil
        }
    }
}
