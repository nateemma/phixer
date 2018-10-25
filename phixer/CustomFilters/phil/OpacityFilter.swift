//
//  OpacityCIFiilter.swift
//  A CIFilter class that either changes the opacity of a single layer or blends 2 layers with the specified opacity
//
//  Created by Philip Price on 10/24/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

class OpacityFilter: CIFilter {
    
    
    // Filters parameters:
    var inputImage : CIImage? = nil
    var inputBackgroundImage : CIImage? = nil
    var inputOpacity: CGFloat = 1.0
    
    
    private let colorMatrix = CIFilter(name: "CIColorMatrix")
    private let composite = CIFilter(name: "CISourceOverCompositing")
    private var img:CIImage? = nil
    private var rgba:[CGFloat] = [0.0, 0.0, 0.0, 1.0]

    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    // default settings
    override func setDefaults()
    {
        inputImage = nil
        inputBackgroundImage = nil
        inputOpacity = 1.0
    }
    
    
    // filter display name
    func displayName() -> String
    {
        return "Opacity"
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
            
            "inputBackgroundImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage],
            
            "inputOpacity": [kCIAttributeIdentity: 0,
                            kCIAttributeClass: "NSNumber",
                            kCIAttributeDefault: 1,
                            kCIAttributeDisplayName: "Opacity",
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
        case "inputBackgroundImage":
            inputBackgroundImage = value as? CIImage
        case "inputOpacity":
            inputOpacity = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }
    
    // the output from the filter
    override var outputImage: CIImage! {
        
        guard inputImage != nil else {
            log.error("NIL image supplied")
            return nil
        }
        
        guard (colorMatrix != nil), (composite != nil) else {
            log.error("Filters not set up")
            return nil
        }
        
        
        // run the colour matrix filter
        colorMatrix?.setDefaults()
        colorMatrix?.setValue(inputImage, forKey: kCIInputImageKey)
        
        rgba[3] = CGFloat(inputOpacity)
        let alphaVector = CIVector(values: rgba, count: 4)
        colorMatrix?.setValue(alphaVector, forKey:"inputAVector")
        
        log.debug ("Setting opacity to:\(rgba[3])")
        img = colorMatrix?.outputImage
        if inputBackgroundImage == nil {
            // only 1 input so return alpha adjusted image
            return img
        } else {
            // 2nd image provided, so blend with alpha adjusted image
            composite?.setDefaults()
            composite?.setValue(img, forKey: kCIInputImageKey)
            composite?.setValue(inputBackgroundImage, forKey: kCIInputBackgroundImageKey)
            return composite?.outputImage
        }

    }

}
