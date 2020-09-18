//
//  AutoAdjustFilter.swift
//  phixer
//
//  Created by Philip Price on 2/6/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

class AutoAdjustFilter: CIFilter {
    let fname = "Auto Adjust"
    var inputImage: CIImage?
    
    
    // default settings
    override func setDefaults() {
        inputImage = nil
    }
    
    
    // filter display name
    func displayName() -> String {
        return fname
    }
    
    
    // filter attributes
    override var attributes: [String : Any] {
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

    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            return nil
        }
        
//        let options:[String : AnyObject] = [CIDetectorImageOrientation:1 as AnyObject]
//        let filters = inputImage.autoAdjustmentFilters(options: options)
        let filters = inputImage.autoAdjustmentFilters()
        var image: CIImage? = inputImage
        
        for filter: CIFilter in filters {
            filter.setValue(image, forKey: kCIInputImageKey)
            log.verbose("Applying filter: \(filter)")
            image =  filter.outputImage
        }
        return image
    }
}
