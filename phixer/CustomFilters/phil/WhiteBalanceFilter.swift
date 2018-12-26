//
//  WhiteBalanceFilter.swift
//  phixer
//
//  Created by Philip Price on 10/25/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

class WhiteBalanceFilter: CIFilter {
    var inputImage: CIImage?
    var inputTemperature:CGFloat = 0.02
    var inputTint:CGFloat = 0.05


    
    // default settings
    override func setDefaults() {
        inputImage = nil
        inputTemperature = 6500.0
        inputTint = 0.0
    }
    
    
    // filter display name
    func displayName() -> String {
        return "Luma Range"
    }
    
    
    // filter attributes
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: displayName(),
            
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage],
            
            "inputTemperature": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "NSNumber",
                           kCIAttributeDefault: 6500.0,
                           kCIAttributeDisplayName: "Temperature",
                           kCIAttributeMin: 2000,
                           kCIAttributeSliderMin: 2000,
                           kCIAttributeSliderMax: 10000,
                           kCIAttributeType: kCIAttributeTypeScalar]
            ,
            
            "inputTint": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "NSNumber",
                           kCIAttributeDefault: 0.0,
                           kCIAttributeDisplayName: "Tint",
                           kCIAttributeMin: -100,
                           kCIAttributeSliderMin: -100,
                           kCIAttributeSliderMax: 100,
                           kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }
    
    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputTemperature":
            inputTemperature = value as! CGFloat
        case "inputTint":
            inputTint = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }

    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            log.error("No input image")
            return nil
        }
        
        let targetNeutral = CIVector(x: 6500, y: 0)
        let neutral = CIVector(x: inputTemperature, y: inputTint)
        //log.debug("temp:\(inputTemperature) tint:\(inputTint)")
        
        return inputImage.applyingFilter("CITemperatureAndTint", parameters: ["inputNeutral": neutral, "inputTargetNeutral": targetNeutral])
        
    }
}
