//
//  CGImage+Extensions.swift
//  phixer
//
//  Created by Philip Price on 11/3/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreGraphics
import Accelerate

extension CGImage {
    
    
    // resizes a CGImage to the requested size. Returns nil if the operation failed
    public func resize (_ size:CGSize) -> CGImage? {
        
        let colorSpace = (self.colorSpace != nil) ? self.colorSpace! : CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = self.alphaInfo.rawValue
        //let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        let context = CGContext(data: nil,
                                      width: Int(size.width),
                                      height: Int(size.height),
                                      bitsPerComponent: Int(8),
                                      bytesPerRow: Int(0),
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo)
        /* This crashes:
        let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: self.bitsPerComponent, bytesPerRow: self.bytesPerRow,
                                space: colorSpace, bitmapInfo: bitmapInfo)
        */
        guard context != nil else {
            log.error("Could not create CG context")
            return nil
        }
        
        // draw the 'old' CGImage into the new one at the calculation place
        context?.interpolationQuality = .high
        context?.draw(self, in: CGRect(origin: CGPoint.zero, size: size))
        let resizedCGImage = context!.makeImage()
        guard resizedCGImage != nil else {
            log.error("Could not create CGImage")
            return nil
        }

        return resizedCGImage
    }
    
    
    
    public func vectorResize(size:CGSize) -> CGImage? {
        var format = vImage_CGImageFormat(bitsPerComponent: UInt32(self.bitsPerComponent),
                                          bitsPerPixel: UInt32(self.bitsPerPixel),
                                          colorSpace: Unmanaged.passUnretained(self.colorSpace!),
                                          bitmapInfo: CGBitmapInfo(rawValue: self.bitmapInfo.rawValue),
                                          version: 0, decode: nil, renderingIntent: CGColorRenderingIntent.defaultIntent)
        var sourceBuffer = vImage_Buffer()
        defer {
            free(sourceBuffer.data)
        }
        var error = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, self, numericCast(kvImageNoFlags))
        guard error == kvImageNoError else { return nil }
        
        // create a destination buffer
        let destWidth = Int(size.width)
        let destHeight = Int(size.height)
        let bytesPerPixel = self.bitsPerPixel/8
        let destBytesPerRow = destWidth * bytesPerPixel
        let destData = UnsafeMutablePointer<UInt8>.allocate(capacity: destHeight * destBytesPerRow)
        defer {
            destData.deallocate()
        }
        var destBuffer = vImage_Buffer(data: destData, height: vImagePixelCount(destHeight), width: vImagePixelCount(destWidth), rowBytes: destBytesPerRow)
        
        // scale the image
        error = vImageScale_ARGB8888(&sourceBuffer, &destBuffer, nil, numericCast(kvImageHighQualityResampling))
        guard error == kvImageNoError else { return nil }
        
        // create a CGImage from vImage_Buffer
        let destCGImage = vImageCreateCGImageFromBuffer(&destBuffer, &format, nil, nil, numericCast(kvImageNoFlags), &error)?.takeRetainedValue()
        guard error == kvImageNoError else { return nil }

        return destCGImage
    }

}
