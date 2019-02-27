//
//  HighPassSkinSmoothingFilter.swift
//  phixer
//
//  Created by Philip Price on 2/6/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation

// this is just a Swift 'wrapper' class that provides access to the underlying Objective C filter
class HighPassSkinSmoothingFilter: YUCIHighPassSkinSmoothing {
    
    // filter display name
    func displayName() -> String {
        return "Skin Smoothing"
    }
    
    // filter attributes
    override var attributes: [String : Any]
    {
        return [
            kCIAttributeFilterDisplayName: displayName(),
            
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage],
            
            "inputAmount": [kCIAttributeIdentity: 0,
                            kCIAttributeClass: "NSNumber",
                            kCIAttributeDefault: 1.0,
                            kCIAttributeDisplayName: "Amount",
                            kCIAttributeMin: 0,
                            kCIAttributeSliderMin: 0,
                            kCIAttributeSliderMax: 2,
                            kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputRadius": [kCIAttributeIdentity: 0,
                            kCIAttributeClass: "NSNumber",
                            kCIAttributeDefault: 16,
                            kCIAttributeDisplayName: "Radius",
                            kCIAttributeMin: 0,
                            kCIAttributeSliderMin: 0,
                            kCIAttributeSliderMax: 40,
                            kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputSharpnessFactor": [kCIAttributeIdentity: 0,
                            kCIAttributeClass: "NSNumber",
                            kCIAttributeDefault: 0.6,
                            kCIAttributeDisplayName: "Sharpness",
                            kCIAttributeMin: 0,
                            kCIAttributeSliderMin: 0,
                            kCIAttributeSliderMax: 2,
                            kCIAttributeType: kCIAttributeTypeScalar],

            "inputToneCurveControlPoints": [kCIAttributeIdentity: 0,
                                  kCIAttributeClass: "NSArray<CIVector *> *",
                                  kCIAttributeDefault: 1,
                                  kCIAttributeDisplayName: "Control Points",
                                  kCIAttributeMin: 0,
                                  kCIAttributeSliderMin: 0,
                                  kCIAttributeSliderMax: 1,
                                  kCIAttributeType: kCIAttributeTypePosition3]
        ]
    }
}
