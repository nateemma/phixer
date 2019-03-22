//
//  EnhanceFaceFilter.swift
//  phixer
//
//  Created by Philip Price on 03/21/19
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

// filter that runs facial detection on an image and adjusts/enhances all of the main features of any faces found
class EnhanceFaceFilter: CIFilter {
    
    let fname = "Enhance Face"

    var inputImage: CIImage? = nil
    var processedImage: CIImage? = nil


    // default settings
    override func setDefaults() {
        log.verbose("Setting defaults")
        inputImage = nil
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
 
    override func value(forKey key: String) -> Any? {
        switch key {
        case "inputImage":
            return inputImage
        case "outputImage":
            return outputImage
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

        self.processedImage = self.inputImage

//        DispatchQueue.main.async {
        
            // if no faces, then run facial detection
            if FaceDetection.count() <= 0 {
                FaceDetection.detectFaces(on: self.inputImage!, orientation: InputSource.getOrientation(), completion: {
                    self.processImage()
                })
            } else {
                self.processImage()
            }
//        }
        return processedImage
    }
    
    private func processImage() {
        self.processedImage = self.inputImage
        
        // apply auto fix and then all of the facial filters. Using defaults for all filters here
        // Note that running the lips filter also takes care of the teeth
        let adjustedImg = self.inputImage?
            //.applyingFilter("AutoAdjustFilter")
            .applyingFilter("EnhanceEyesFilter")
            .applyingFilter("EnhanceEyebrowsFilter")
            .applyingFilter("EnhanceLipsFilter")
            //.applyingFilter("EnhanceTeethFilter")
            .applyingFilter("MaskedSkinSmoothingFilter")
        

        guard adjustedImg != nil else {
            log.error("NIL adjustedImg")
            return
        }
        
        self.processedImage = adjustedImg
    }
}
