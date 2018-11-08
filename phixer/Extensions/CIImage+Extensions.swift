//
//  CIImage+Extensions.swift
//  phixer
//
//  Created by Philip Price on 11/3/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreGraphics
import CoreImage

extension CIImage {
    
    // use the same context across all instances, as it is expensive to create
    private static var context:CIContext? = nil
    
    // creates a CGImage - useful for cases when the CIImage was not created from a CGImage (or UIImage)
    public func generateCGImage() -> CGImage? {
        if (CIImage.context == nil){
            CIImage.context = CIContext(options: [kCIContextUseSoftwareRenderer : false, kCIContextHighQualityDownsample : true ])
        }
        let imgRect = CGRect(x: 0, y: 0, width: self.extent.width, height: self.extent.height)
        return CIImage.context?.createCGImage(self, from: imgRect)
    }
}
