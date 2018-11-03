//
//  MLModelHelper.swift
//  phixer
//
//  Created by Philip Price on 11/2/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//


// Helpers for dealing with CoreML Models

import Foundation
import CoreImage
import CoreML


class MLModelHelper {
    
    // Resizes the input image to be a multiple of the model input size. The original image is in the middle of the output image
    public static func prepareInputImage(image:CIImage?, imageSize:CGSize, modelSize:CGSize) -> CIImage? {
        
        guard (image != nil) else {
            log.error("NIL image supplied")
            return nil
        }

        var resizedImage:CIImage? = nil
        
        // First, calculate the size of the output image, which is a multiple of the model size
        // Note: this is a 'fit' calculation, i.e. the input image will fit entirely in the output image
        
        let boundingRect = CGRect(x: 0, y: 0, width: modelSize.width, height: modelSize.height)
        let rect:CGRect = Geometry.aspectFitToRect(aspectRatio: imageSize, boundingRect: boundingRect)
        
       //log.debug("image:\(imageSize) model:\(modelSize) rect:\(rect)")
        
        let inputCGImage = image?.cgImage


        // create a new CGImage with the desired size
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapContext = CGContext(data: nil,
                                      width: Int(modelSize.width),
                                      height: Int(modelSize.height),
                                      bitsPerComponent: Int(8),
                                      bytesPerRow: Int(0),
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard bitmapContext != nil else {
            log.error("Could not create CG context")
            return nil
        }

        // draw the 'old' CGImage into the new one at the calculation place (NOTE: this is not the same as a 'normal' resize)
        bitmapContext?.interpolationQuality = .high
        bitmapContext?.draw(inputCGImage!, in: rect)
        let resizedCGImage = bitmapContext!.makeImage()
        guard resizedCGImage != nil else {
            log.error("Could not create CGImage")
            return nil
        }

        // convert back to CIImage
        resizedImage = CIImage(cgImage: resizedCGImage!)
        return resizedImage
    }
    
    
    // processes the output of a model and crops/resizes it to match the supplied size
    public static func processOutputImage(image:CIImage?, modelSize:CGSize, targetSize:CGSize) -> CIImage? {
        
        guard (image != nil) else {
            log.error("NIL image supplied")
            return nil
        }
        
        var resizedImage:CIImage? = nil
        
        var cgimage:CGImage? = image?.cgImage
        if (cgimage == nil) { // this often (always?) happens with generated images
            //log.error("No CGImage in CIImage, creating one...")
            cgimage = image?.generateCGImage()
        }
        if (cgimage == nil) {
            log.error("Coild not convert CIImage to CGImage")
            return nil
        }

        // scale up to match the longest side of the target size
        let side = max(targetSize.width, targetSize.height)
        let size = CGSize(width: side, height: side)
        let scaledCGImage = cgimage?.resize(size)
        //let scaledCGImage = cgimage?.vectorResize(size: size) // just playing with different algorithm

        // crop down to the target size
        let x = (side - targetSize.width) / 2
        let y = (side - targetSize.height) / 2
        let rect = CGRect(x: x, y: y, width: targetSize.width, height: targetSize.height)
        
        //log.debug("image:\(image!.extent.size) target:\(targetSize) model:\(modelSize) rect:\(rect)")
        
        let croppedCGImage = scaledCGImage?.cropping(to: rect)
        if (croppedCGImage != nil){
            resizedImage = CIImage(cgImage: croppedCGImage!)
        } else {
            log.error("Crop failed")
        }
        
        return resizedImage
    }
 }
