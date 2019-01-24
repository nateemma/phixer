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
    
    // crate a CGImage of specified size, filled with specified (CG) color. Useful for masking etc.
    public static func create(size:CGSize, fillcolor:CGColor) -> CGImage? {
        let colorSpace =  CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        let context = CGContext(data: nil,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: Int(8),
                                bytesPerRow: Int(0),
                                space: colorSpace,
                                bitmapInfo: bitmapInfo)

        guard context != nil else {
            log.error("Could not create CG context")
            return nil
        }
        
        context?.setFillColor(fillcolor)
        context?.fill(CGRect(origin: CGPoint.zero, size: size))
        
        // create the CGImage
        let cgImage = context!.makeImage()
        
        return cgImage
    }

    
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
            log.error("Could not create CG context. size:\(size)")
            return self
        }
        
        // draw the 'old' CGImage into the new one at the calculation place
        context?.interpolationQuality = .high
        context?.draw(self, in: CGRect(origin: CGPoint.zero, size: size))
        let resizedCGImage = context!.makeImage()
        guard resizedCGImage != nil else {
            log.error("Could not create CGImage")
            return self
        }

        return resizedCGImage
    }
    
    
    // different implementation of resize, using the vector library
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

    
    // function to apply convolution matrix to an image, using the Accelerate framework
    // Note: divisor is the number used to normaise the result to 1. Typically, this would be [1-1/(1 + sum of elements)]
    //       Convolutions such as Sobel etc. are typically pre-normalised, so just set to 1
    func applyConvolution(matrix: [Int16], divisor: Int) -> CGImage? {
        guard (matrix.count == 9 || matrix.count == 25 || matrix.count == 49) else {
            log.error("Kernel size must be 3x3, 5x5 or 7x7.")
            return nil
            
        }
        
        // DBG: check sum
        var sum:Int16 = 0
        for i in matrix {
            sum = sum + i
        }
        if sum != 0 {
            log.warning ("Sum:\(sum), expected 0")
        }
        
        let matrixSide = UInt32(sqrt(Float(matrix.count)))
  
        var format = vImage_CGImageFormat(bitsPerComponent: UInt32(self.bitsPerComponent),
                                          bitsPerPixel: UInt32(self.bitsPerPixel),
                                          colorSpace: Unmanaged.passUnretained(self.colorSpace!),
                                          bitmapInfo: CGBitmapInfo(rawValue: self.bitmapInfo.rawValue),
                                          version: 0, decode: nil, renderingIntent: CGColorRenderingIntent.defaultIntent)

        // set up source buffer from the current CGImage
        var sourceBuffer = vImage_Buffer()
        defer {
            free(sourceBuffer.data)
        }
        var error = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, self, numericCast(kvImageNoFlags))
        guard error == kvImageNoError else {
            return nil
        }
        
        // create a destination buffer
        let destWidth = Int(self.width)
        let destHeight = Int(self.height)
        let bytesPerPixel = self.bitsPerPixel/8
        let destBytesPerRow = destWidth * bytesPerPixel
        let destData = UnsafeMutablePointer<UInt8>.allocate(capacity: destHeight * destBytesPerRow)
        defer {
            destData.deallocate()
        }
        var destBuffer = vImage_Buffer(data: destData, height: vImagePixelCount(destHeight), width: vImagePixelCount(destWidth), rowBytes: destBytesPerRow)

        // run the convolution
        var backgroundColor : Array<UInt8> = [0,0,0,0]
        
        let cerror = vImageConvolve_ARGB8888(&sourceBuffer, &destBuffer, nil, 0, 0, matrix, matrixSide, matrixSide, Int32(divisor), &backgroundColor, UInt32(kvImageBackgroundColorFill))
        guard cerror == kvImageNoError else {
            return nil
        }

        
        // create a CGImage from vImage_Buffer
        
        let cgimage = vImageCreateCGImageFromBuffer(&destBuffer, &format, nil, nil, numericCast(kvImageNoFlags), &error)?.takeRetainedValue()
        
        return cgimage
    }

}
