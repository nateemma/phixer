//
//  ImageView.swift
//
//
//  Based on code by Simon Gladman in project CoreImageHelpers
//  Copyright © 2016 Simon Gladman. All rights reserved.
//

import GLKit
import UIKit
import MetalKit
import QuartzCore


/// `MetalImageView` extends an `MTKView` and exposes an `image` property of type `CIImage` to
/// simplify Metal based rendering of Core Image filters.


class MetalImageView: MTKView
{
    
    /// The image to display. The image will be rendered when this is set
    var image: CIImage? { didSet { renderImage() }
    }
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    lazy var commandQueue: MTLCommandQueue = { [unowned self] in
            return self.device!.makeCommandQueue()!
        }()
    
    lazy var ciContext: CIContext = { [unowned self] in
        //return CIContext(mtlDevice: self.device!, options: [kCIImageColorSpace: NSNull(), kCIImageProperties: NSNull(), kCIContextWorkingColorSpace: NSNull()])
        return CIContext(mtlDevice: self.device!)
        }()
    
    
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect,
                   device: device ?? MTLCreateSystemDefaultDevice())
        
        if super.device == nil {
            fatalError("Device doesn't support Metal")
        }
        
        framebufferOnly = false
    }
    
    
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    
    func renderImage() {
        guard device != nil else {
            log.error("NIL device")
            return
        }
        
        if let image = image {

            if let targetTexture = currentDrawable?.texture {
                
                let commandBuffer = commandQueue.makeCommandBuffer()
                
                let bounds = CGRect(origin: CGPoint.zero, size: drawableSize)
                
                let originX = image.extent.origin.x
                let originY = image.extent.origin.y
                
                let scaleX = drawableSize.width / image.extent.width
                let scaleY = drawableSize.height / image.extent.height
                let scale = min(scaleX, scaleY)

                let scaledImage = image.transformed(by: CGAffineTransform(translationX: -originX, y: -originY))
                                       .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                
                ciContext.render(scaledImage,
                                 to: targetTexture,
                                 commandBuffer: commandBuffer,
                                 bounds: bounds,
                                 colorSpace: colorSpace)

                /***
                 ciContext.render(image,
                                 to: targetTexture,
                                 commandBuffer: commandBuffer,
                                 bounds: bounds,
                                 colorSpace: colorSpace)
                ***/
                commandBuffer!.present(currentDrawable!)
                
                commandBuffer!.commit()
                
                //self.bounds = bounds
                //self.frame.size = drawableSize
            } else {
                log.error("Could not get texture")
            }
        } else {
            log.error("No image")
        }
    }
}

extension CGRect {
    func aspectFitInRect(target: CGRect) -> CGRect {
        let scale: CGFloat = {
            let scale = target.width / self.width
            
            return self.height * scale <= target.height ?
                scale :
                target.height / self.height
        }()
        
        let width = self.width * scale
        let height = self.height * scale
        let x = target.midX - width / 2
        let y = target.midY - height / 2
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
