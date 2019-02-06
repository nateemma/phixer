//
//  CropRotateFilter.swift
//  phixer
//
//  Created by Philip Price on 12/24/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

// filter to implement crop and rotate
// Note that the input rectangle must be in (CG) Image coordinates, not view coordinates

class CropRotateFilter: CIFilter {
    let fname = "Crop/Rotate"
    var inputImage: CIImage?
    var inputAngle: CGFloat = 0.0
    var inputRectangle: CIVector = CIVector(values: [0.0, 0.0, 0.0, 0.0], count: 4)
    
    private var rotateFilter: CIFilter?  = CIFilter(name: "CIStraightenFilter")
    private var cropFilter: CIFilter? = CIFilter(name: "CICrop")
    private var affineFilter: CIFilter? = CIFilter(name: "CIAffineTransform")

    // default settings
    override func setDefaults() {
        inputImage = nil
        inputAngle = 0.0
        inputRectangle = CIVector(values: [0.0, 0.0, 0.0, 0.0], count: 4)
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
            
            "inputAngle": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "NSNumber",
                           kCIAttributeDefault: 0.0,
                           kCIAttributeDisplayName: "Rotation",
                           kCIAttributeMin: -2.0 * CGFloat(Double.pi),
                           kCIAttributeSliderMin: -2.0 * CGFloat(Double.pi),
                           kCIAttributeSliderMax: 2.0 * CGFloat(Double.pi),
                           kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputRectangle": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIVector",
                           kCIAttributeDefault: 0.0,
                           kCIAttributeDisplayName: "Crop Area",
                           kCIAttributeMin: 0.0,
                           kCIAttributeSliderMin: 0.0,
                           kCIAttributeSliderMax: 0.0,
                           kCIAttributeType: kCIAttributeTypeRectangle]
        ]
    }

    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputAngle":
            inputAngle = value as! CGFloat
        case "inputRectangle":
            inputRectangle = value as! CIVector
        default:
            log.error("Invalid key: \(key)")
        }
    }

    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            return nil
        }
        
        // rotate and fill
        self.rotateFilter?.setValue(inputImage, forKey: "inputImage")
        self.rotateFilter?.setValue(inputAngle, forKey: "inputAngle")
        let rotatedImage = self.rotateFilter?.outputImage?
            .clampedToExtent()
            .cropped(to: inputImage.extent)
        
        if rotatedImage == nil {
            log.error("Rotated image is NIL. Angle:\(inputAngle)")
            return inputImage
        }
        
        
        // crop
        self.cropFilter?.setValue(rotatedImage, forKey: "inputImage")
        self.cropFilter?.setValue(inputRectangle, forKey: "inputRectangle")
        let croppedImage = (self.cropFilter?.outputImage)
        if croppedImage == nil {
            log.error("Cropped image is NIL. area:\(inputRectangle)")
            return inputImage
        }
        
        
        // the cropped image may still have an offset applied, need to remove that
        let translation = CGAffineTransform(translationX: -(croppedImage?.extent.origin.x)!, y: -(croppedImage?.extent.origin.y)!)
        let translatedImage = croppedImage?.transformed(by: translation)
        
        
        return translatedImage

    }
}
