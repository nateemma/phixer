//
//  ImageManager.swift
//  FilterCam
//
// Manages the various types of internal images (blends, samples, image under edit etc.)
//
//  Created by Philip Price on 11/7/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import GPUImage
import AVFoundation


protocol ImageManagerDelegate: class {
    func blendImageChanged(name: String)
    func sampleImageChanged(name: String)
    func userImageSaved()
}

class ImageManager {
    
    
        
    
    
    //////////////////////////////////
    // Blend Image/Layer Management
    //////////////////////////////////
    
    private static let _blendNameList:[String] = ["bl_angelic.png", "bl_pools_cool.png", "bl_colour_creation_135.png", "bl_roots.png", "bl_cornered_cool.png", "bl_rusted_rainbow_cool.png",
                                                  "bl_dried_mud_2.png", "bl_sand_31.png", "bl_film_1.png", "bl_shattered_warm.png", "bl_film_inverse_1.png", "bl_snow_bokeh.png",
                                                  "bl_goodness.png", "bl_soul.png", "bl_late_moss_cool.png", "bl_star_13.png", "bl_lava_cool.png", "bl_star_spangled.png",
                                                  "bl_lost_rainbow.png", "bl_sulphur_43.png", "bl_makeup.png", "bl_surface.png", "bl_mudflats_39.png", "bl_texture_202.png",
                                                  "bl_orange_41.png", "bl_tinsel_bokeh_texture.png", "bl_paint_21.png", "bl_vintage.png", "bl_paint_24.png", "bl_vintage_inverse.png",
                                                  "bl_paper_impasto_72.png", "bl_warm_bokeh.png", "bl_party_bokeh.png"
                                                ]
    private static var _currBlendName:String = "bl_texture_202.png"
    
    private static var _currBlendImage: UIImage? = nil
    
    private static var _currBlendImageScaled: UIImage? = nil
    private static var _currBlendSize: CGSize = CGSize(width: 0.0, height: 0.0)
    
    
    
    open static func getBlendImageList()->[String]{
        return _blendNameList
    }
    
    open static func getCurrentBlendImageName()->String {
        return _currBlendName
    }
    
    open static func setCurrentBlendImageName(_ name:String) {
        if (_blendNameList.contains(name)){
            log.debug("Current Blend image set to:\(name)")
            _currBlendName = name
            _currBlendImage = UIImage(named: _currBlendName)
            _currBlendImageScaled = resizeImage(getCurrentBlendImage(), targetSize: _currBlendSize, mode:.scaleAspectFill)
        } else {
            log.warning("Unknown Blend name:\(name)")
        }
    }
    
    open static func getCurrentBlendImage()->UIImage? {
        if (_currBlendImage == nil){
            _currBlendImage = UIImage(named: _currBlendName)
        }
        
        return _currBlendImage
    }
    
    open static func getCurrentBlendImage(size:CGSize)->UIImage? {
        // make sure current blend image has been loaded
        if (_currBlendImage == nil){
            _currBlendImage = UIImage(named: _currBlendName)
        }
        
        // check to see if we have already resized
        if (_currBlendSize != size){
            _currBlendSize = size
            _currBlendImageScaled = resizeImage(getCurrentBlendImage(), targetSize: size, mode:.scaleAspectFill)
        }
        
        return _currBlendImageScaled
    }
    
    
    open static func getBlendImage(name: String, size:CGSize)->UIImage?{
        if (_blendNameList.contains(name)){
            return resizeImage(UIImage(named:name), targetSize:size, mode:.scaleAspectFill)
        } else {
            log.warning("Unknown Blend name:\(name)")
            return nil
        }
    }
    
    
    //////////////////////////////////
    // Utilities
    //////////////////////////////////
    
    open static func resizeImage(_ image: UIImage?, targetSize: CGSize, mode:UIViewContentMode) -> UIImage? {
        guard (image != nil) else {
            log.error("NIL image provided for resizing")
            return nil
        }
        
        var size = (image?.size)!
        
        // figure out if we need to rotate the image to match the target
        let srcIsLandscape:Bool = (size.width > size.height)
        let tgtIsLandscape:Bool = (targetSize.width > targetSize.height)
        
        var srcImage:UIImage? = image
        var srcSize:CGSize = CGSize.zero
        
        if (srcIsLandscape != tgtIsLandscape){
            //log.warning("Need to rotate src image")
            if (srcIsLandscape) {
               srcImage = rotateImage(image, degrees: -90.0)
            } else {
                srcImage = rotateImage(image, degrees: 90.0)
            }
            srcSize.width = (image?.size.height)!
            srcSize.height = (image?.size.width)!
        } else {
            srcImage = image
            srcSize = size
        }
  
        
        // crop the image to match the aspect ratio of the target size (resize doesn't seem to work)
        let bounds = CGRect(x:0, y:0, width:srcSize.width, height:srcSize.height)
        let rect = AVMakeRect(aspectRatio: targetSize, insideRect: bounds)
        //let rect = fitIntoRect(srcSize: srcSize, targetRect: bounds, withContentMode: .scaleAspectFill)
        
        let cropSize = CGSize(width:rect.width, height:rect.height)
        let croppedImage = cropImage(srcImage, to:cropSize)
        
        // resize to match the target
        let newImage = scaleImage(croppedImage, targetSize:targetSize)
        
        var nsize:CGSize = CGSize.zero
        if (newImage != nil){
            nsize = (newImage?.size)!
        }
        /***
        log.debug("SIZES: image:\(size), targetSize:\(targetSize), srcImage:\(srcSize), cropSize:\(cropSize), nsize:\(nsize)")
        let (r1n, r1d) = ClosestFraction.find(Float(size.width/size.height), maxDenominator:Int(size.height))
        let (r2n, r2d) = ClosestFraction.find(Float(targetSize.width/targetSize.height), maxDenominator:Int(targetSize.height))
        let (r3n, r3d) = ClosestFraction.find(Float(srcSize.width/srcSize.height), maxDenominator:Int(srcSize.height))
        let (r4n, r4d) = ClosestFraction.find(Float(cropSize.width/cropSize.height), maxDenominator:Int(cropSize.height))
        let (r5n, r5d) = ClosestFraction.find(Float(nsize.width/nsize.height), maxDenominator:Int(nsize.height))
        log.debug("RATIOS: image:\(r1n)/\(r1d), targetSize:\(r2n)/\(r2d), srcImage:\(r3n)/\(r3d), cropSize:\(r4n)/\(r4d), nsize:\(r5n)/\(r5d)")
        ***/
        
        return newImage
    }
    
   
    
    open static func scaleImage(_ image: UIImage?, targetSize:CGSize) -> UIImage? {
        guard (image != nil) else {
            log.error("NIL image provided for scaling")
            return nil
        }
        
        let size = (image?.size)!
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image?.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    
    
    open static func scaleImage(_ image: UIImage?, widthRatio:CGFloat, heightRatio:CGFloat) -> UIImage? {
        guard (image != nil) else {
            log.error("NIL image provided for scaling")
            return nil
        }
        
        let size = (image?.size.applying(CGAffineTransform(scaleX: widthRatio, y: heightRatio)))!
        
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        image?.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
 
    
    
    open static func rotateImage(_ image: UIImage?, degrees: Double) -> UIImage? {
        guard (image != nil) else {
            log.error("NIL image provided for rotation")
            return nil
        }
        
        let radians = CGFloat(degrees*M_PI)/180.0 as CGFloat
        let size = (image?.size)!

        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        let bitmap = UIGraphicsGetCurrentContext()
        bitmap!.translateBy(x: size.width / 2, y: size.height / 2)
        bitmap!.rotate(by: radians)
        bitmap!.scaleBy(x: 1.0, y: -1.0)
        let rect = CGRect(x:-size.width / 2, y:-size.height / 2, width:size.width, height:size.height)
        bitmap!.draw((image?.cgImage)!, in: rect, byTiling: false)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        return newImage
    }
    
 
    
    open static func cropImage(_ image:UIImage?, to:CGSize) -> UIImage? {
        guard (image != nil) else {
            log.error("NIL image provided for rotation")
            return nil
        }
        
        
        let contextSize: CGSize = (image?.size)!
        
        //Set to square
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        let cropAspect: CGFloat = to.width / to.height
        
        var cropWidth: CGFloat = to.width
        var cropHeight: CGFloat = to.height
        
        if to.width > to.height { //Landscape
            cropWidth = contextSize.width
            cropHeight = contextSize.width / cropAspect
            posY = (contextSize.height - cropHeight) / 2
        } else if to.width < to.height { //Portrait
            cropHeight = contextSize.height
            cropWidth = contextSize.height * cropAspect
            posX = (contextSize.width - cropWidth) / 2
        } else { //Square
            if contextSize.width >= contextSize.height { //Square on landscape (or square)
                cropHeight = contextSize.height
                cropWidth = contextSize.height * cropAspect
                posX = (contextSize.width - cropWidth) / 2
            }else{ //Square on portrait
                cropWidth = contextSize.width
                cropHeight = contextSize.width / cropAspect
                posY = (contextSize.height - cropHeight) / 2
            }
        }
        
        let rect: CGRect = CGRect(x:posX, y:posY, width:cropWidth, height:cropHeight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImage = (image?.cgImage)!.cropping(to: rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let cropped: UIImage = UIImage(cgImage: imageRef, scale: (image?.scale)!, orientation: (image?.imageOrientation)!)
        
        UIGraphicsBeginImageContextWithOptions(to, true, (image?.scale)!)
        cropped.draw(in: CGRect(x:0, y:0, width:to.width, height:to.height))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resized
    }
  
    
    
    static func aspectFit(aspectRatio : CGSize, boundingSize: CGSize) -> CGSize {
        let mW = boundingSize.width / aspectRatio.width;
        let mH = boundingSize.height / aspectRatio.height;
        var fitSize: CGSize = boundingSize
        
        if( mH < mW ) {
            fitSize.width = boundingSize.height / aspectRatio.height * aspectRatio.width;
        }
        else if( mW < mH ) {
            fitSize.height = boundingSize.width / aspectRatio.width * aspectRatio.height;
        }
        
        return fitSize;
    }
 
    
    
    static func aspectFill(aspectRatio :CGSize, minimumSize: CGSize) -> CGSize {
        let mW = minimumSize.width / aspectRatio.width;
        let mH = minimumSize.height / aspectRatio.height;
        var fillSize: CGSize = minimumSize
        
        if( mH > mW ) {
            fillSize.width = minimumSize.height / aspectRatio.height * aspectRatio.width;
        }
        else if( mW > mH ) {
            fillSize.height = minimumSize.width / aspectRatio.width * aspectRatio.height;
        }
        
        return fillSize;
    }

    
    open static func fitIntoRect(srcSize:CGSize, targetRect: CGRect, withContentMode contentMode: UIViewContentMode)->CGRect {
        
        var rect:CGRect = CGRect.zero
        
        if !(contentMode == .scaleAspectFit || contentMode == .scaleAspectFill) {
            // Not implemented
            rect.origin.x = 0
            rect.origin.y = 0
            rect.size.width = srcSize.width
            rect.size.height = srcSize.height
            return rect
        }
        
        var scale = targetRect.width / srcSize.width
        
        if contentMode == .scaleAspectFit {
            if srcSize.height * scale > targetRect.height {
                scale = targetRect.height / srcSize.height
            }
        } else if contentMode == .scaleAspectFill {
            if srcSize.height * scale < targetRect.height {
                scale = targetRect.height / srcSize.height
            }
        }
        
        let scaledWidth = srcSize.width * scale
        let scaledHeight = srcSize.height * scale
        let scaledX = targetRect.width / 2 - scaledWidth / 2
        let scaledY = targetRect.height / 2 - scaledHeight / 2
        
        rect.origin.x = scaledX
        rect.origin.y = scaledY
        rect.size.width = scaledWidth
        rect.size.height = scaledHeight
        
        return rect
    }
}
