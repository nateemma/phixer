//
//  RenderView.swift
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


/// `RenderView` extends an `MTKView` and exposes an `image` property of type `CIImage` to
/// simplify Metal based rendering of Core Image filters.


class RenderView: MTKView
{
    
    var theme = ThemeManager.currentTheme()
    var angle:CGFloat = 0.0 // rotation of used displayed image relative to original image
    var imageSize:CGSize = CGSize.zero // size of original image (some filters use infinite or zero extent)
    var scale: CGFloat = 1.0
    
    /// The image to display. The image will be rendered when this is set
    public var image: CIImage? {
        didSet { renderImage() }
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
        
        RenderView.device = super.device
        
        if RenderView.commandQueue == nil {
            RenderView.commandQueue = super.device?.makeCommandQueue()
            if RenderView.commandQueue == nil {
                log.error("Could not allocate Metal Command Queue")
            }
        }
        framebufferOnly = false
        //isPaused = true // updated manually (e.g. when a camera frame is available)
        imageSize = CGSize.zero
        
        self.contentScaleFactor = UIScreen.main.nativeScale
    }
    
    
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // reset the command queue.
    public static func reset(){
        RenderView.commandQueue = nil
        RenderView.commandQueue = RenderView.device?.makeCommandQueue()
        if RenderView.commandQueue == nil {
            log.error("Could not allocate Metal Command Queue")
        }
    }
  
    // returns a point in (CI) image coordinates based on a position in UI coordinates relative to the displayed view
    public func getImagePosition(viewPos:CGPoint) -> CIVector{
        //Notes:
        // - UIView coordinate origin is upper left corner, CIImage is lower left
        // - UIView coordinates are pixel offsets to a point in the view, CI coordinates are offsets relative to the original image
        
        var imgPos:CGPoint = CGPoint.zero
        if let image = image {
            if (imageSize.width < 1.0) || (imageSize.height < 1.0) {
                // image size not set. Try setting to image.extent.size if not too big
                if (image.extent.size.width > 1.0) && (image.extent.size.width < 10000.0) {
                    imageSize = image.extent.size
                } else {
                    // invalid extent, try setting to size of current input (bad coupling, I know)
                    // this usually means a filter added an infinite extent and should have been cropped
                    imageSize = InputSource.getSize()
                    log.warning("Unusable extent. Maybe crop image???")
                }
            }
            var isize = imageSize
            if (abs(angle) > 0.01){ // rotated? Flip width/height
                isize.height = imageSize.width
                isize.width = imageSize.height
            }
            
            var x: CGFloat
            var y: CGFloat
            //let x = ((isize.width / drawableSize.width) * (viewPos.x)).clamped(0.0, isize.width)
            //let y = ((isize.height / drawableSize.height) * (isize.height - viewPos.y)).clamped(0.0, isize.height)
            
            var scaleX = isize.width / drawableSize.width
            var scaleY = isize.height / drawableSize.height
 
            let bounds = CGRect(origin: CGPoint.zero, size: drawableSize)
            let dsize:CGSize = drawableSize
            var targetRect: CGRect = CGRect.zero
            
            // Calculate zoom/crop effect. If the view and the image are the same orientation then fill, otherwise fit
            if ((dsize.width>=dsize.height) && (isize.width>=isize.height)) ||
                ((dsize.width<dsize.height) && (isize.width<isize.height)) {
                targetRect = Geometry.aspectFillToRect(aspectRatio: isize, minimumRect: bounds)
                scaleX = isize.width / targetRect.width
                scaleY = isize.width / targetRect.height
                scale = max(scaleX, scaleY)
            } else {
                targetRect = Geometry.aspectFitToRect(aspectRatio: isize, boundingRect: bounds)
                scaleX = isize.width / targetRect.width
                scaleY = isize.width / targetRect.height
                scale = min(scaleX, scaleY)
            }

            let offsetX = targetRect.origin.x
            let offsetY = targetRect.origin.y

            // have to convert view-based position to device-based position
            let vx = viewPos.x * UIScreen.main.scale - offsetX
            let vy = viewPos.y * UIScreen.main.scale - offsetY
            
            if (angle > 0.01){ // drawable is landscape, image is portrait
                x = scale * (targetRect.width - vy)
                y = scale * (targetRect.height - vx)
                
            } else if (angle < -0.01){ // drawable is portrait , image is landscape
                x = scale * (vy)
                y = scale * (vx)
                
            } else { // no rotation
                x = scale * (vx)
                y = scale * (targetRect.height - vy)
            }
            imgPos = CGPoint(x: x.rounded(), y: y.rounded())
//            log.verbose("\nisize:\(isize) dsize:\(drawableSize) self:\(self.frame.size)\n viewPos:\(viewPos) imgPos: \(imgPos)\n" +
//                " scaleX:\(scaleX) scaleY:\(scaleY) angle:\(angle)\n" +
//                " offsetX:\(offsetX) offsetY:\(offsetY) targetRect:\(targetRect)")
       }
        return CIVector(cgPoint: imgPos)
    }
    
    // return the equivalent (CI-)Image-based position in view coordinates (the view here being 'self')
    public func getViewPosition(imagePos:CGPoint) -> CGPoint {
        var viewpos: CGPoint = CGPoint.zero
        
        
        if let image = image {
            if (imageSize.width < 1.0) || (imageSize.height < 1.0) {
                // image size not set. Try setting to image.extent.size if not too big
                if (image.extent.size.width > 1.0) && (image.extent.size.width < 10000.0) {
                    imageSize = image.extent.size
                } else {
                    // this usually means a filter added an infinite extent and should have been cropped
                    imageSize = InputSource.getSize()
                    log.warning("Unusable extent. Maybe crop image???")
                }
            }
            var isize = imageSize
            if (abs(angle) > 0.01){ // rotated? Flip width/height
                isize.height = imageSize.width
                isize.width = imageSize.height
            }
            
            var x: CGFloat
            var y: CGFloat
            //let x = ((isize.width / drawableSize.width) * (viewPos.x)).clamped(0.0, isize.width)
            //let y = ((isize.height / drawableSize.height) * (isize.height - viewPos.y)).clamped(0.0, isize.height)
            
            var scaleX = drawableSize.width / isize.width
            var scaleY = drawableSize.height / isize.height
            let bounds = CGRect(origin: CGPoint.zero, size: drawableSize)
            let dsize:CGSize = drawableSize
            var targetRect: CGRect = CGRect.zero

            // Calculate zoom/crop effect. If the view and the image are the same orientation then fill, otherwise fit
            if ((dsize.width>=dsize.height) && (isize.width>=isize.height)) ||
                ((dsize.width<dsize.height) && (isize.width<isize.height)) {
                targetRect = Geometry.aspectFillToRect(aspectRatio: isize, minimumRect: bounds)
                scaleX = targetRect.width / isize.width
                scaleY = targetRect.height / isize.height
                scale = max(scaleX, scaleY)
            } else {
                targetRect = Geometry.aspectFitToRect(aspectRatio: isize, boundingRect: bounds)
                scaleX = targetRect.width / isize.width
                scaleY = targetRect.height / isize.height
                scale = min(scaleX, scaleY)
            }

            let offsetX = targetRect.origin.x
            let offsetY = targetRect.origin.y
            
            let ix = imagePos.x
            let iy = imagePos.y
            
            if (angle > 0.01){ // drawable is landscape, image is portrait
                x = (isize.width - iy) * scaleX + offsetX
                y = (isize.height - ix) * scaleY + offsetY
                
            } else if (angle < -0.01){ // drawable is portrait , image is landscape
                x = (iy) * scaleY + offsetX
                y = (ix) * scaleX + offsetY
                
            } else { // no rotation
                x = (ix) * scaleX + offsetX
                y = (isize.height - iy) * scaleY + offsetY
            }

            // divide by the screen scale so that we now have pixel values
            x /= UIScreen.main.scale
            y /= UIScreen.main.scale
 

            viewpos = CGPoint(x: x.rounded(), y: y.rounded())
//            log.verbose("\nisize:\(isize) dsize:\(drawableSize) self:\(self.frame.size)\n viewPos:\(viewpos) imgPos: \(imagePos)\n" +
//                " scaleX:\(scaleX) scaleY:\(scaleY) angle:\(angle)\n" +
//                " offsetX:\(offsetX) offsetY:\(offsetY) targetRect:\(targetRect)")
        }
        return viewpos
    }
    
    func setImageSize(_ size:CGSize){
        self.imageSize = size
    }
    
    
    func renderImage() {
        guard device != nil else {
            log.error("NIL device")
            return
        }
        
        
        if let srcImg = image {
            
            if let targetTexture = currentDrawable?.texture {
                
                if let commandBuffer = RenderView.commandQueue?.makeCommandBuffer() {
                    
                   calculateTransforms()
                    
                    guard let rotation = rotationTransform, let scale = scaleTransform, let translation = translationTransform else {
                        log.error("NIL Transforms")
                        return
                    }
                    
                    let scaledImage = srcImg
                        .transformed(by: rotation)
                        .transformed(by: scale)
                        .transformed(by: translation)
                    
                    
                    
                    let bounds = CGRect(origin: CGPoint.zero, size: drawableSize)
                    
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
                //self.frame.size = dsize
            } else {
                if currentDrawable == nil {
                    log.error("currentDrawable is nil")
                } else {
                    log.error("Could not get texture")
                }
            }
        } else {
            log.error("No image")
        }
    }
    
    ///////////////////////
    // MARK: Transform utilities
    ///////////////////////
    
    // the trasnforms to be applied
    private var rotationTransform: CGAffineTransform? = nil
    private var scaleTransform: CGAffineTransform? = nil
    private var translationTransform: CGAffineTransform? = nil
    
    // the current (really, previous) size of the input image and display buffer
    private var currImgSize:CGSize = CGSize.zero
    private var currDrawSize:CGSize = CGSize.zero
    
    private func calculateTransforms(){
        
        // if the sizes of both the input image and the drawing buffer have not changed, then the transforms can be re-used. Otherwise, re-calculate
        // we do this because most of the time, the sizes will not change for a particular instance
        
        let change: Bool = ( !currImgSize.width.approxEqual((self.image?.extent.size.width)!) ) ||
            ( !currImgSize.height.approxEqual((self.image?.extent.size.height)!) ) ||
            ( !currDrawSize.width.approxEqual(self.drawableSize.width) ) ||
            ( !currDrawSize.height.approxEqual(self.drawableSize.height) )
        
        if change {
            
            //log.verbose("Calculating transforms")
            let bounds = CGRect(origin: CGPoint.zero, size: drawableSize)
            
            // vars that control how the input image is transformed to match the view in which it is displayed
            var originX:CGFloat = 0.0
            var originY:CGFloat = 0.0
            
            if let image = self.image {
                
                // test: orient image to match view
                
                //let orientation = UIDeviceOrientation.portrait
                var isize:CGSize = image.extent.size
                let dsize:CGSize = drawableSize
                
                let iAR = isize.height / isize.width
                let dAR = dsize.height / dsize.width
                
                if (dAR<1.0) && (iAR>1.0) { // drawable is landscape, image is portrait
                    //log.debug("portrait->landscape")
                    angle = .pi / 2.0
                    isize.height = image.extent.size.width
                    isize.width = image.extent.size.height
                    
                } else if (dAR>1.0) && (iAR<1.0) { // drawable is portrait, image is landscape
                    //log.debug("landscape->portrait")
                    angle = -(.pi / 2.0)
                    isize.height = image.extent.size.width
                    isize.width = image.extent.size.height
                }
                //log.debug("(\(image.extent.width),\(image.extent.height))->(\(isize.width),\(isize.height))")
                
                var targetRect:CGRect
                var scaleX:CGFloat = 1.0
                var scaleY:CGFloat = 1.0
                
                // if the view and the image are the same orientation then fill, otherwise fit
                if ((dsize.width>=dsize.height) && (isize.width>=isize.height)) ||
                    ((dsize.width<dsize.height) && (isize.width<isize.height)) {
                    targetRect = Geometry.aspectFillToRect(aspectRatio: isize, minimumRect: bounds)
                    scaleX = targetRect.width / isize.width
                    scaleY = targetRect.height / isize.height
                    scale = max(scaleX, scaleY)
                } else {
                    targetRect = Geometry.aspectFitToRect(aspectRatio: isize, boundingRect: bounds)
                    scaleX = targetRect.width / isize.width
                    scaleY = targetRect.height / isize.height
                    scale = min(scaleX, scaleY)
                }
                
                
                
                originX = targetRect.origin.x
                originY = targetRect.origin.y
                
                if isize.width > isize.height {
                    // landscape, move the image up to the top of the drawable
                    originY = abs(dsize.height - targetRect.size.height)
//                    log.debug("Landscape image:(\(isize.width),\(isize.height)) " +
//                        "rect:(\(targetRect.size.width),\(targetRect.size.height)) " +
//                        "drawable:(\(dsize.width), \(dsize.height)) o:(\(originX), \(originY)) scale:\(scale) angle:\(angle)")
                } else {
                    // portrait or square, centre horizontally
                    
                    originX = (dsize.width - targetRect.size.width)/2.0
                    if abs(angle) > 0.01 { // if image was rotated, coordinate system is different
                        originY = dsize.height
                    }
                    //DBG
//                    log.debug("Portrait image:(\(isize.width),\(isize.height)) " +
//                        "rect:(\(targetRect.size.width),\(targetRect.size.height)) " +
//                        "drawable:(\(dsize.width), \(dsize.height)) o:(\(originX), \(originY)) scale:\(scale) angle:\(angle)")
                }
                
                // save the transforms
                rotationTransform =  CGAffineTransform(rotationAngle: angle)
                scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
                translationTransform = CGAffineTransform(translationX: originX, y: originY)
                
            }
            
            // save the sizes for next time through
            currImgSize = (self.image?.extent.size)!
            currDrawSize = self.drawableSize
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
