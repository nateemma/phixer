//
//  EnhanceTeethFilter.swift
//  phixer
//
//  Created by Philip Price on 03/21/19
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

// filter that runs facial detection on an image and adjusts/enhances the teeth area of any faces found
class EnhanceTeethFilter: CIFilter {
    
    let fname = "Enhance Teeth"

    var inputImage: CIImage? = nil
    var processedImage: CIImage? = nil
    var inputBrightness: CGFloat = 0.01
    var inputClarity: CGFloat = 0.5


    // default settings
    override func setDefaults() {
        //log.verbose("Setting defaults")
        inputImage = nil
        processedImage = nil
        inputBrightness = 0.01
        inputClarity = 0.5
    }


    // filter display name
    func displayName() -> String {
        return fname
    }


    // filter attributes
    override var attributes: [String: Any] {
        return [
            kCIAttributeFilterDisplayName: displayName(),
            
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage],
            
            "inputBrightness": [kCIAttributeIdentity: 0,
                              kCIAttributeClass: "NSNumber",
                              kCIAttributeDefault: 0.01,
                              kCIAttributeDisplayName: "Brightness",
                              kCIAttributeMin: 0,
                              kCIAttributeSliderMin: 0,
                              kCIAttributeSliderMax: 0.05,
                              kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputClarity": [kCIAttributeIdentity: 0,
                             kCIAttributeClass: "NSNumber",
                             kCIAttributeDefault: 0.6,
                             kCIAttributeDisplayName: "Clarity",
                             kCIAttributeMin: 0,
                             kCIAttributeSliderMin: 0,
                             kCIAttributeSliderMax: 1,
                             kCIAttributeType: kCIAttributeTypeScalar]

        ]
    }


    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputBrightness":
                inputBrightness = value as! CGFloat
        case "inputClarity":
            inputClarity = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }
 
    override func value(forKey key: String) -> Any? {
        switch key {
        case "inputImage":
            return inputImage
        case "outputImage":
            return outputImage
        case "inputBrightness":
            return inputBrightness
        case "inputClarity":
            return inputClarity
        default:
            log.error("Invalid key: \(key)")
            return nil
        }
    }

    override var outputImage: CIImage? {
        guard inputImage != nil else {
            log.error("NIL input image")
            return inputImage
        }

        // if no faces, then run facial detection
        if FaceDetection.count() <= 0 {
            FaceDetection.detectFaces(on: self.inputImage!, orientation: InputSource.getOrientation(), completion: { [weak self] in
                self?.processImage()
            })
        } else {
            processImage()
        }
        return processedImage
    }
    
    private func processImage() {
        self.processedImage = self.inputImage
        
        // increase brightness, vibrance, clarity and sharpen, also de-saturate red
        let yVector = CIVector(x: 0.0, y: 0.1, z: 1.0) // set saturation to low value (but not 0.0)
        let adjustedImg = self.inputImage?
            .applyingFilter("MultiBandHSV", parameters: ["inputYellowShift": yVector, "inputOrangeShift": yVector])
            .applyingFilter("BrightnessFilter", parameters: ["inputBrightness": self.inputBrightness])
            .applyingFilter("ClarityFilter", parameters: ["inputClarity": self.inputClarity])
            .applyingFilter("CISharpenLuminance", parameters: ["inputRadius": 1.6, "inputSharpness": 0.4])
        guard adjustedImg != nil else {
            log.error("NIL adjustedImg")
            return
        }

        // get the facial features
        let faceList = FaceDetection.getFeatures()
        guard faceList.count > 0 else {
            log.warning("No faces detected")
            return
        }
        
        // build a compound path for the lips
        var contourList:[[CGPoint]] = [[]]
        for i in 0..<faceList.count {
            contourList.append(faceList[i].innerLips)
        }
        let path = FaceDetection.createCompoundPath(points: contourList)
        
        // create a mask
        let mask = FaceDetection.createMask(cgpath: path, size: EditManager.getImageSize())
        guard mask != nil else {
            log.error("NIL Mask")
            return
        }
        
        // blend the original and the adjusted version using the mask
        let maskedImg =  adjustedImg?.applyingFilter("CIBlendWithMask", parameters: [kCIInputMaskImageKey: mask!, kCIInputBackgroundImageKey:self.inputImage!])
        
        self.processedImage = maskedImg
    }
}
