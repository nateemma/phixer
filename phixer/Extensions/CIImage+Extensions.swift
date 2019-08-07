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
    
    // get the current CIContext, creating it if necessary
    private static func getContext() -> CIContext? {
        if (CIImage.context == nil){
            CIImage.context = CIContext(options: [ CIContextOption.useSoftwareRenderer : false, CIContextOption.highQualityDownsample : true,
                CIContextOption.cacheIntermediates : false])
        }
        return CIImage.context
    }
    
    // creates a CGImage - useful for cases when the CIImage was not created from a CGImage (or UIImage)
    public func generateCGImage(size:CGSize) -> CGImage? {
        let result = autoreleasepool { () -> CGImage? in
            //let imgRect = CGRect(x: 0, y: 0, width: self.extent.width, height: self.extent.height)
            let imgRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            return CIImage.getContext()?.createCGImage(self, from: imgRect)
        }
        return result
    }
    
    // get the associated CGImage, creating it if necessary
    // (Images created by filters typically do not have a cgImage)
    public func getCGImage(size:CGSize) -> CGImage? {
        let result = autoreleasepool { () -> CGImage? in
            if self.cgImage == nil {
                // self.cgImage is read-only so can't set it
                return self.generateCGImage(size:size)
            } else {
                return self.cgImage
            }
        }
        return result
    }

    
    // resize a CIImage
    public func resize(size:CGSize) -> CIImage? {
        
        
        var result: CIImage? = nil
        result = self
        autoreleasepool {
            // get the CGImage for this CIImage
            let cgimage = self.getCGImage(size:self.extent.size)
            
            // double-check that CGImage was created
            if cgimage == nil  {
                log.error("Could not generate CGImage")
            } else {
                
                // resize the CGImage and check result
                let cgimage2 = cgimage?.resize(size)
                if cgimage2 == nil {
                    log.error("Could not resize CGImage")
                } else {
                    result = CIImage(cgImage: cgimage2!)
                }
            }
        }
        return result
    }
    
    // get a portrait Matte Image, if it exists (iOS12 and later)
    func portraitEffectsMatteImage() -> CIImage? {

        
        if #available(iOS 12.0, *) {
            let matteData = self.portraitEffectsMatte
            if matteData != nil {
                return CIImage(portaitEffectsMatte: matteData!)
            } else {
                return nil
            }
        } else {
            // Fallback on earlier versions
            return nil
        }
    }
}
