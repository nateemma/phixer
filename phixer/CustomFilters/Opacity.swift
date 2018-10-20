//
//  Opacity.swift
//  Compound filter to provide an opacity effect with 1 or 2 images
// If 1 image is supplied then the alpha channel is set to the provided value
// If 2 are provided then the foreground is overlayed on the background with the alpha value supplied
//
//  Created by Philip Price on 10/19/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

/** based on Stack Overflow answer https://stackoverflow.com/a/20160693 :
 CIImage *overlayImage = … // from file, CGImage etc
CIImage *backgroundImage = … // likewise

CGFloat alpha = 0.5;
CGFloat rgba[4] = {0.0, 0.0, 0.0, alpha};
CIFilter *colorMatrix = [CIFilter filterWithName:@"CIColorMatrix"];
[colorMatrix setDefaults];
[colorMatrix setValue:overlayImage forKey: kCIInputImageKey];
[colorMatrix setValue:[CIVector vectorWithValues:rgba count:4] forKey:@"inputAVector"];

CIFilter *composite = [CIFilter filterWithName:@"CISourceOverCompositing"];
[composite setDefaults];
[composite setValue:colorMatrix.outputImage forKey: kCIInputImageKey];
[composite setValue:backgroundImage forKey: kCIInputBackgroundImageKey];

UIImage *blendedImage = [UIImage imageWithCIImage:composite.outputImage];
 **/

class Opacity: FilterDescriptor {
    
    public let alphaKey:String = "alpha"
    
    // override the base class properties
    override var key: String { return "Opacity" }
    override var title: String { return "Set Opacity"}
    override var filterOperationType: FilterOperationType { return .custom }
    override var numParameters: Int { return 1 }
    override var parameterConfiguration: [String:ParameterSettings] { return customSettings }

    private var customSettings:[String:ParameterSettings] = [:]
    private var colorMatrix:CIFilter? = nil
    private var alphaVector:CIVector? = nil
    private var rgba:[CGFloat] = [0.0, 0.0, 0.0, 1.0]
    private var composite:CIFilter? = nil

    override init(){
        super.init()
        customSettings = [:]
        // manually add the alpha parameter to the parameter list (so that it will be displayed)
        let p = ParameterSettings(key: alphaKey, title: "opacity", min: 0.0, max: 1.0, value: 0.8, type: .float)
        self.customSettings[alphaKey] = p
        stashParameters()
        
        colorMatrix = CIFilter(name: "CIColorMatrix")
        composite = CIFilter(name: "CISourceOverCompositing")
    }
    
    // Override the apply functions
    
    
    override func apply (image: CIImage?, image2: CIImage?=nil) -> CIImage? {
        
        guard image != nil else {
            log.error("NIL image supplied")
            return nil
        }

        guard (colorMatrix != nil), (composite != nil) else {
            log.error("Filters not set up")
            return nil
        }
        
        var img:CIImage? = nil

        // run the colour matrix filter
        colorMatrix?.setDefaults()
        colorMatrix?.setValue(image, forKey: kCIInputImageKey)

        rgba[3] = CGFloat(self.getParameter(alphaKey))
        alphaVector = CIVector(values: rgba, count: 4)
        colorMatrix?.setValue(alphaVector, forKey:"inputAVector")

        img = colorMatrix?.outputImage
        if image2 == nil {
            // only 1 input so return alpha adjusted image
            return img
        } else {
            // 2nd image provided, so blend with alpha adjusted image
            composite?.setDefaults()
            composite?.setValue(img, forKey: kCIInputImageKey)
            composite?.setValue(image2, forKey: kCIInputBackgroundImageKey)
            return composite?.outputImage
        }

        return nil
    }
    
}
