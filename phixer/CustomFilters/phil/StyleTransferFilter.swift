//
//  StyleTransferFilter.swift
//  Base class for Style Transfer filters
//
//  Created by Philip Price on 10/25/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage
import CoreML
import UIKit


// This is the base class for all Style Transfer filters. Subclasses should override the vars and funcs tht define the model-specific characteristics
class StyleTransferFilter: CIFilter {
    
    ///////////////////////////////
    // required functions
    // The subclass should override all of the functions in the section below
    ///////////////////////////////
    
    // returns the source image used to create the model. This is just to support UIs, not needed for the filter
    // this should be overridden by the subclass
    func getSourceImage() -> UIImage? {
        log.error("Base class called. Func should be overriden")
        return nil
    }
    
    // filter display name
    // this should be overridden by the subclass
    func displayName() -> String {
        return "Style Transfer base class"
    }
    
    // get the input model for the specific style transfer
    // this should be overridden by the subclass
    func getInputModel() -> MLModel? {
        log.error("Base class called. Func should be overriden")
        return nil
    }
    
    // get the model size
    // this should be overridden by the subclass
    func getModelSize() -> CGSize {
        log.error("Base class called. Func should be overriden")
        return CGSize.zero
    }

    
    ///////////////////////////////
    // Default implementation.
    // This should work for any Style Transfer filter as long as the functions above are properly implemented
    ///////////////////////////////
    
    // the CIFilter used to run the model
    var coreMLFilter: CIFilter? = nil
    
    // the input image for the model
    var inputImage: CIImage? = nil
    
    // these vars should be set by the subclass
    var inputModel: MLModel? = nil
    var modelSize:CGSize = CGSize.zero

    // default settings
    override func setDefaults() {
        inputImage = nil
    }
    
    
    // filter attributes
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: displayName(),
            
            kCIInputImageKey: [kCIAttributeIdentity: 0,
                               kCIAttributeClass: "CIImage",
                               kCIAttributeDisplayName: "Image",
                               kCIAttributeType: kCIAttributeTypeImage],
            
            "inputModel": [kCIAttributeIdentity: 0,
                               kCIAttributeClass: "String",
                               kCIAttributeDefault: 0.0,
                               kCIAttributeDisplayName: "Model",
                               kCIAttributeMin: 0,
                               kCIAttributeSliderMin: 0.0,
                               kCIAttributeSliderMax: 0.0,
                               kCIAttributeType: "String"],
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
        
        if (inputModel == nil) {
            inputModel = getInputModel()
            if inputModel == nil {
                log.error("NIL model returned")
                return nil
            }
        }
        
        if (coreMLFilter == nil){
            coreMLFilter = CIFilter(name: "CICoreMLModelFilter")
        }
        modelSize = getModelSize()
        coreMLFilter?.setValue(inputModel, forKey: "inputModel")

        
        // resize input image to match model input size (image gets stretched otherwise)
        let resizedImage = MLModelHelper.prepareInputImage(image: inputImage, imageSize: inputImage.extent.size, modelSize: modelSize)

        // provide the resized image to the filter
        coreMLFilter?.setValue(resizedImage, forKey: kCIInputImageKey)
        
        // run filter and restore output to original size
        let outimage = MLModelHelper.processOutputImage(image: coreMLFilter?.outputImage, modelSize: modelSize, targetSize: inputImage.extent.size)
        
        // reset model and filter because it's a big chunk of memory
        inputModel = nil
        coreMLFilter = nil
        
        return outimage
    }
}
