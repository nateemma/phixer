//
//  CroppableImageView.swift
//  phixer
//
//  Created by Philip Price on 2/1/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import CoreImage



// this is a view supports cropping the supplied image
// It uses a combination of CIStraightenFilter to rotate/fill and CICrop to extract a rectangle
// NOTE: unlike many crop approaches, the cropped view remains constant and the background view is moved

class CroppableImageView: UIView {
    
    
    private var originalImage: CIImage? = nil
    private var rotatedImage: CIImage? = nil
    private var croppedImage: CIImage? = nil
    private var currAspectRatio: AspectRatio = .free
    
    private var currAngle: CGFloat = 0.0 // angle in radians
    private var currCropFrame: CGRect = CGRect.zero // note: this is in image (not view) coordinates
    
    private var gridView: GridOverlayView! = GridOverlayView()
    private var gridFrame: CGRect = CGRect.zero
    private var backgroundRenderView: RenderView! = RenderView()
    private var croppedRenderView: RenderView!  = RenderView()
    
    private var theme = ThemeManager.currentTheme()
    
    private var rotateFilter: CIFilter?  = CIFilter(name: "CIStraightenFilter")
    private var cropFilter: CIFilter? = CIFilter(name: "CICrop")
    private var affineFilter: CIFilter? = CIFilter(name: "CIAffineTransform")

    private var layoutDone: Bool = false
    
    //////////////////////
    // MARK: Accessors
    //////////////////////
    
    public enum AspectRatio {
        case free
        case ratio_1_1
        // TODO: add more fixed aspect ratios
    }
    
    
    public var image: CIImage? {
        didSet {
            
            guard let image = image else {
                log.error("NIL image")
                return
            }
            
            log.verbose("image set. extent:\(image.extent)")
            
            originalImage = image
            if originalImage == nil {
                log.error("Could not create input image")
            }
            
            update()
        }
    }

    
    public var aspectRatio: AspectRatio = .free {
        didSet {
            log.verbose("aspect ratio set: \(aspectRatio)")
           currAspectRatio = aspectRatio
            update()
        }
    }
    
    public var angle: CGFloat = 0.0 {
        didSet {
            log.verbose("angle set: \(angle)")
            currAngle = angle
            update()
        }
    }
    
    //////////////////////
    // MARK: View setup
    //////////////////////
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        theme = ThemeManager.currentTheme()
        
        self.backgroundColor = UIColor.clear

        
        self.addSubview(backgroundRenderView)
        backgroundRenderView.fillSuperview()
        
        self.addSubview(croppedRenderView)
        gridFrame = makeFrame(self.frame)
        croppedRenderView.frame = gridFrame
        
        // setup the grid overlay
        //gridView = GridOverlayView()
        self.addSubview(gridView)
        gridView.fillSuperview()
        
        layoutDone = true
        
        if image != nil {
            update()
        }

        // don't do anything else until image has been set
    }

    
    private func update() {
        
        guard originalImage != nil else {
            log.error("Input image is NIL")
            return
        }
        
        if layoutDone {
            DispatchQueue.main.async {
                
                self.backgroundRenderView.setImageSize((self.originalImage?.extent.size)!)
                self.backgroundRenderView.image = self.originalImage

                // setup the grid overlay
                self.gridFrame = self.makeFrame(self.frame) // creates frame with curent aspect ratio
                self.gridView.setGridFrame(self.gridFrame)
                

                // rotate and fill
                self.rotateFilter?.setValue(self.originalImage, forKey: "inputImage")
                self.rotateFilter?.setValue(self.currAngle, forKey: "inputAngle")
                self.rotatedImage = self.rotateFilter?.outputImage?
                    .clampedToExtent()
                    .cropped(to: (self.originalImage?.extent)!)

                if self.rotatedImage == nil {
                    log.error("Rotated image is NIL. Angle:\(self.currAngle)")
                }
                
                // display the images (blur the background a litle so the cropped area stands out)
                self.backgroundRenderView.image = self.rotatedImage?
                    .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 15.0])
                    .clampedToExtent()
                    .cropped(to: (self.originalImage?.extent)!)
                    .applyingFilter("OpacityFilter", parameters: ["inputOpacity": 0.8])

                // crop

                // translate grid frame to (CG)image coordinates
                self.currCropFrame = self.imageBasedRect(viewrect: self.gridFrame)
                
                log.verbose("gridFrame:\(self.gridFrame) cropFrame:\(self.currCropFrame)")
                self.croppedRenderView.frame = self.gridFrame

                let vector = CIVector(cgRect: self.currCropFrame)
                self.cropFilter?.setValue(self.rotatedImage, forKey: "inputImage")
                self.cropFilter?.setValue(vector, forKey: "inputRectangle")
                self.croppedImage = (self.cropFilter?.outputImage)
                if self.croppedImage == nil {
                    log.error("Cropped image is NIL. vector:\(vector)")
                }
                
                
                // the cropped image still has an offset applied, need to remove that
                let translation = CGAffineTransform(translationX: -(self.croppedImage?.extent.origin.x)!, y: -(self.croppedImage?.extent.origin.y)!)
                let translatedImage = self.croppedImage?.transformed(by: translation)
                
                self.croppedRenderView.image = translatedImage
                
                log.verbose("frames:\noriginal:\(self.originalImage?.extent)\n bgndRV:\(self.backgroundRenderView.frame)\n" +
                    " grid:\(self.gridView.frame)\n cropRV:\(self.croppedRenderView.frame)\n rotateImg:\(self.rotatedImage?.extent)\n" +
                    " cropImg:\(self.croppedImage?.extent)\n")
                log.verbose("croppedRenderView:\(self.croppedRenderView.frame) croppedImage:\(self.croppedImage?.extent)")
            }
        } else {
            log.warning("Layout not done yet")
        }
    }
    
    //////////////////////
    // MARK: Utilities
    //////////////////////



    // create a frame based on the supplied bounds and with the current aspect ratio
    private func makeFrame(_ frame:CGRect) -> CGRect {
        var f: CGRect
        
        f = frame
        switch currAspectRatio {
        case .free:
            f = frame
            
        case .ratio_1_1:
            let side:CGFloat = min(frame.size.width, frame.size.height)
            f = CGRect(x: (frame.size.width - side)/2.0, y: (frame.size.height - side)/2.0, width: side, height: side)
            
        default:
            log.error("Unexpected AspectRatio: \(currAspectRatio)")
        }
        
        log.verbose("AR:\(currAspectRatio) inframe: \(frame) outframe:\(f)")
        return f
    }

    
    // convert a view-based rectangle into image coordinates (based on backgroundRenderView)
    private func imageBasedRect(viewrect: CGRect) -> CGRect {
        var irect: CGRect
        irect = viewrect
        
        // in view-based coordinates, origin is top-left, y increasing down. In CG-based coordinates, origin is bottom left, y increasing up
        let vbtmleft = CGPoint(x: viewrect.origin.x, y: viewrect.origin.y + viewrect.size.height)
        let vtopright  = CGPoint(x: viewrect.origin.x + viewrect.size.width, y: viewrect.origin.y)
        
        let itopright = backgroundRenderView?.getImagePosition(viewPos: vtopright).cgPointValue
        irect.origin = (backgroundRenderView?.getImagePosition(viewPos: vbtmleft).cgPointValue)!
        irect.size.width = (itopright?.x)! - irect.origin.x
        irect.size.height = (itopright?.y)! - irect.origin.y
/***
       irect.origin.x = viewrect.origin.x
        irect.origin.y = (backgroundRenderView?.frame.size.height)! - viewrect.origin.y - viewrect.size.height
        irect.size = viewrect.size
         ***/

        return irect
    }
}


