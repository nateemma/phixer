//
//  EnhanceEyebrowsFilter.swift
//  phixer
//
//  Created by Philip Price on 03/21/19
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

// filter that runs facial detection on an image and adjusts/enhances the eyebrows area of any faces found
class EnhanceEyebrowsFilter: CIFilter {
    
    let fname = "Enhance Eyebrows"

    var inputImage: CIImage? = nil
    var processedImage: CIImage? = nil
    //var inputBrightness: CGFloat = 0.01
    var inputClarity: CGFloat = 0.5


    // default settings
    override func setDefaults() {
        //log.verbose("Setting defaults")
        inputImage = nil
        processedImage = nil
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
        
        // increase clarity and sharpen
        let adjustedImg = self.inputImage?
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
        
        // build a compound path for the eyebrows
        var contourList:[[CGPoint]] = [[]]
        for i in 0..<faceList.count {
            contourList.append(faceList[i].leftEyebrow)
            contourList.append(faceList[i].rightEyebrow)
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
