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
import CoreImage


/// `MetalImageView` extends an `MTKView` and exposes an `image` property of type `CIImage` to
/// simplify Metal based rendering of Core Image filters.


class MetalImageView: MTKView
{
    
    var theme = ThemeManager.currentTheme()
    

    /// The image to display. The image will be rendered when this is set
    var image: CIImage? { didSet { renderImage() }
    }
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    // we make the command queue static so that we can share it across views
    static var commandQueue: MTLCommandQueue? = nil
    private static var device: MTLDevice? = nil
    
    lazy var ciContext: CIContext = { [unowned self] in
        return CIContext(mtlDevice: self.device!)
        //return CIContext(mtlDevice: self.device!, options: [ kCIContextUseSoftwareRenderer: false, kCIContextHighQualityDownsample: false ])
        }()
    
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        
        super.init(frame: frameRect, device: device ?? MTLCreateSystemDefaultDevice())
        
        guard super.device != nil else {
            log.error("Device doesn't support Metal")
            return
        }
        
        MetalImageView.device = super.device
        
        if MetalImageView.commandQueue == nil {
            MetalImageView.commandQueue = super.device?.makeCommandQueue()
            if MetalImageView.commandQueue == nil {
                log.error("Could not allocate Metal Command Queue")
            }
        }
        framebufferOnly = false
        //isPaused = true // updated manually (e.g. when a camera frame is available)
    }
    
    
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // reset the command queue.
    public static func reset(){
        MetalImageView.commandQueue = nil
        MetalImageView.commandQueue = MetalImageView.device?.makeCommandQueue()
        if MetalImageView.commandQueue == nil {
            log.error("Could not allocate Metal Command Queue")
        }
    }
    
    func renderImage() {
        guard device != nil else {
            log.error("NIL device")
            return
        }
        
        if let image = image {
            
            if let targetTexture = currentDrawable?.texture {
                
                if let commandBuffer = MetalImageView.commandQueue?.makeCommandBuffer() {
                    
                    let bounds = CGRect(origin: CGPoint.zero, size: drawableSize)
                    
/*** method 1: (having issues with horizontal alignment)
                    var originX = image.extent.origin.x
                    var originY = image.extent.origin.y
                    
                    let scaleX = drawableSize.width / image.extent.width
                    let scaleY = drawableSize.height / image.extent.height
                    // if the view and the image are the same orientation then fill, otherwise fit
                    var scale:CGFloat = 1.0
                    if ((drawableSize.width>=drawableSize.height) && (image.extent.width>=image.extent.height)) ||
                        ((drawableSize.width<drawableSize.height) && (image.extent.width<image.extent.height)) {
                        scale = max(scaleX, scaleY) // aspectFill
                    } else {
                        scale = min(scaleX, scaleY) // aspectFit
                    }
                    
                    if image.extent.width > image.extent.height {
                        // if landscape then move the image up to the top of the drawable (note: this is before scaling, so work in image coordinates)
                        originY = -(drawableSize.height/scale - image.extent.height)
                    } else {
                        // portrait, centre horizontally
                        originX = -(drawableSize.width/scale - image.extent.width)/2.0
                        //DBG
                        log.debug("image:(\(image.extent.width),\(image.extent.height)) " +
                            "drawable:(\(drawableSize.width), \(drawableSize.height)) o:(\(originX), \(originY)) scale:\(scale)")
                    }
                     let scaledImage = image.transformed(by: CGAffineTransform(translationX: -originX, y: -originY))
                     .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
 ***/
                    
/** Method 2: */
                    

                    // if the view and the image are the same orientation then fill, otherwise fit
                    var targetRect:CGRect
                    var scale:CGFloat = 1.0
                    var scaleX:CGFloat = 1.0
                    var scaleY:CGFloat = 1.0

                    if ((drawableSize.width>=drawableSize.height) && (image.extent.width>=image.extent.height)) ||
                        ((drawableSize.width<drawableSize.height) && (image.extent.width<image.extent.height)) {
                        targetRect = Geometry.aspectFillToRect(aspectRatio: image.extent.size, minimumRect: bounds)
                        scaleX = targetRect.width / image.extent.width
                        scaleY = targetRect.height / image.extent.height
                        scale = max(scaleX, scaleY)
                   } else {
                        targetRect = Geometry.aspectFitToRect(aspectRatio: image.extent.size, boundingRect: bounds)
                        scaleX = targetRect.width / image.extent.width
                        scaleY = targetRect.height / image.extent.height
                        scale = min(scaleX, scaleY)
                    }

                    

                    var originX = targetRect.origin.x
                    var originY = targetRect.origin.y
                    
                    if image.extent.width > image.extent.height {
                        // if landscape then move the image up to the top of the drawable
                        originY = fabs(drawableSize.height - targetRect.size.height)
                        //log.debug("Landscape image:(\(image.extent.width),\(image.extent.height)) " +
                        //    "rect:(\(targetRect.size.width),\(targetRect.size.height)) " +
                        //    "drawable:(\(drawableSize.width), \(drawableSize.height)) o:(\(originX), \(originY)) scale:\(scale)")
                   } else {
                        // portrait, centre horizontally

                        originX = (drawableSize.width - targetRect.size.width)/2.0
                        //DBG
                        //log.debug("Portrait image:(\(image.extent.width),\(image.extent.height)) " +
                        //    "rect:(\(targetRect.size.width),\(targetRect.size.height)) " +
                        //    "drawable:(\(drawableSize.width), \(drawableSize.height)) o:(\(originX), \(originY)) scale:\(scale)")
                    }

                     let scaledImage = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                                           .transformed(by: CGAffineTransform(translationX: originX, y: originY))
                    
                    
                    ciContext.render(scaledImage,
                                     to: targetTexture,
                                     commandBuffer: commandBuffer,
                                     bounds: bounds,
                                     colorSpace: colorSpace)
                    
                    commandBuffer.present(currentDrawable!)
                    commandBuffer.commit()
                    
                    self.draw()  // if isPaused is set then we must call this manually to free the drawable 
                    
                } else {
                    log.error("Err getting cmd buf")
                }
                
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
