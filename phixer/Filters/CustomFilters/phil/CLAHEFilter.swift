//
//  CLAHEFilter.swift
//  phixer
//
//  Created by Philip Price on 2/6/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation

class CLAHEFilter: YUCICLAHE {
    
    // filter display name
    func displayName() -> String {
        return "Contrast Limited Histogram"
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
            
            "inputClipLimit": [kCIAttributeIdentity: 0,
                             kCIAttributeClass: "NSNumber",
                             kCIAttributeDefault: 1,
                             kCIAttributeDisplayName: "Clip Limit",
                             kCIAttributeMin: 0,
                             kCIAttributeSliderMin: 0,
                             kCIAttributeSliderMax: 2,
                             kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputTileGridSize": [kCIAttributeIdentity: 0,
                             kCIAttributeClass: "CIVector",
                             kCIAttributeDefault: 1,
                             kCIAttributeDisplayName: "Tile Grid Size",
                             kCIAttributeMin: 0,
                             kCIAttributeSliderMin: 0,
                             kCIAttributeSliderMax: 1,
                             kCIAttributeType: kCIAttributeTypePosition]
        ]
    }
    
}
