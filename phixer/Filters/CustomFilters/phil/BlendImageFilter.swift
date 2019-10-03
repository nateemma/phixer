//
//  BlendImageFilter.swift
//  phixer
//
//  Created by Philip Price on 09/26/19.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage


// pseudo filter that blends the input image with the supplied asset or name or photo id, using the supplied blend mode
// Intended for use in presets (so that you can define the blend image by name)

class BlendImageFilter: CIFilter {
    
    let fname = "Blend Images"
    var inputImage: CIImage?
    var inputName:String = ""
    var inputMode:Int = 0
    var inputOpacity:CGFloat = 1.0
    
    static var opacityFilter:OpacityFilter = OpacityFilter()

    // default settings
    override func setDefaults() {
        inputImage = nil
        inputName = ""
        inputMode = 0
        inputOpacity = 1.0
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
                           kCIAttributeType: kCIAttributeTypeImage],
            
            "inputName": [kCIAttributeIdentity: 0,
                          kCIAttributeClass: "NSString",
                          kCIAttributeDisplayName: "Blend Image Name",
                          kCIAttributeType: "String"],
            
            "inputMode": [kCIAttributeIdentity: 0,
                          kCIAttributeClass: "NSNumber",
                          kCIAttributeDisplayName: "Blend Mode",
                          kCIAttributeDefault: 0,
                          kCIAttributeMin: 0,
                          kCIAttributeSliderMin: 0,
                          kCIAttributeSliderMax: Float(BlendMode.count.rawValue - 1),
                          kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputOpacity": [kCIAttributeIdentity: 0,
                          kCIAttributeClass: "NSNumber",
                          kCIAttributeDisplayName: "Opacity",
                          kCIAttributeDefault: 1.0,
                          kCIAttributeMin: 0,
                          kCIAttributeSliderMin: 0,
                          kCIAttributeSliderMax: 1.0,
                          kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }
    
    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputName":
            inputName = value as! String
        case "inputMode":
            inputMode = Int(value as! CGFloat)
        case "inputOpacity":
            inputOpacity = value as! CGFloat

        default:
            log.error("Invalid key: \(key)")
        }
    }

    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            return nil
        }

        var image:CIImage? = inputImage
        
        // get blend mode
        if let mode = BlendMode(rawValue: inputMode) {
            
            // get associated filter
            if let filter = mode.getFilter() {
                
                // get the blend image
                if let blendImage = getBlendImage(name: inputName) {
                    
                    log.verbose("Blend: \(inputName) Mode: \(mode)")
                    // set the filter parameters
                    filter.setValue(blendImage, forKey: kCIInputImageKey)
                    filter.setValue(inputImage, forKey: "inputBackgroundImage")
                    
                    // reduce the opacity (if necessary)
                    if inputOpacity < 0.99 {
                        BlendImageFilter.opacityFilter.setValue(inputOpacity, forKey: "inputOpacity")
                        BlendImageFilter.opacityFilter.setValue(filter.outputImage, forKey: kCIInputImageKey)
                        BlendImageFilter.opacityFilter.setValue(inputImage, forKey: "inputBackgroundImage")
                        image = BlendImageFilter.opacityFilter.outputImage
                    } else {
                        image = filter.outputImage
                    }
                    
                } else {
                    log.error("Error getting blend image")
                }
            } else {
                log.error("Error creating blend filter")
            }
        } else {
            log.error("Invalid blend mode: \(inputMode)")
        }
        return image
    }
    
    private func getBlendImage(name: String) -> CIImage? {
        var image: CIImage? = nil
        
        let size = inputImage?.extent.size
        // empty string is a special case, just return the current Blend Image (which could be NIL)
        if name.isEmpty {
            image = ImageManager.getCurrentBlendImage()?.resize(size: size!)
        } else {
            let asset = ImageManager.getImageFromAssets(assetID: name, size: size!)
            image = CIImage(image: asset!)
        }
        
        return image
    }
}
