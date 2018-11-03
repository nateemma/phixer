//
//  Style_LaMuse.swift
//  Implements a Fast Neural Style transfer filter, based on "La Muse" by somebody famous
//
//  Created by Philip Price on 10/25/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage
import CoreML

class Style_LaMuse: CIFilter {
    var inputImage: CIImage? = nil
    var coreMLFilter: CIFilter? = nil
    
    private var inputModel: MLModel? = nil
    private var modelSize:CGSize = CGSize.zero
    
    // default settings
    override func setDefaults() {
        inputImage = nil
    }
    
    
    // filter display name
    func displayName() -> String {
        return "Style: LaMuse"
    }
    
    
    // filter attributes
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: displayName(),
            
            kCIInputImageKey: [kCIAttributeIdentity: 0,
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
        
        if (inputModel == nil) || (coreMLFilter == nil){
            coreMLFilter = CIFilter(name: "CICoreMLModelFilter")
            inputModel = FNS_La_Muse_1().model
            modelSize = CGSize(width: 720, height: 720) // just have to know this (annoying)
            if inputModel == nil {
                log.error("NIL model returned")
            }
            coreMLFilter?.setValue(inputModel, forKey: "inputModel")
        }
        
        // resize input image to match model input size (image gets stretched otherwise)
        let resizedImage = MLModelHelper.prepareInputImage(image: inputImage, imageSize: inputImage.extent.size, modelSize: modelSize)

        // provide the resized image to the filter
        coreMLFilter?.setValue(resizedImage, forKey: kCIInputImageKey)
        
        // run filter and restore output to original size
        let outimage = MLModelHelper.processOutputImage(image: coreMLFilter?.outputImage, modelSize: modelSize, targetSize: inputImage.extent.size)
        
        return outimage
    }
}
