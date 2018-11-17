//
//  EditImageDisplayView.swift
//  phixer
//
//  Created by Philip Price on 9/16/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import CoreImage
import AVFoundation


// Class responsible for displaying the edited image, with standard filters applied
class EditImageDisplayView: UIView {
    
    var theme = ThemeManager.currentTheme()
    


    fileprivate var renderView: MetalImageView? = MetalImageView()
    fileprivate var imageView: UIImageView! = UIImageView()
    
    fileprivate var initDone: Bool = false
    fileprivate var filterManager = FilterManager.sharedInstance
    
    
    fileprivate var currPhotoInput:CIImage? = nil
    fileprivate var currBlendInput:CIImage? = nil
    
    fileprivate var currFilterKey:String = ""
    fileprivate var currFilterDescriptor: FilterDescriptor? = nil

    
    
    ///////////////////////////////////
    // MARK: - Setup/teardown
    ///////////////////////////////////
    convenience init(){
        self.init(frame: CGRect.zero)
    }
    
    
    deinit {
        suspend()
    }

   
    override func layoutSubviews() {
        super.layoutSubviews()
        
        log.debug("layout")
       
        doLayout()
        
        // don't do anything else until filter has been set
        //update()
        

    }
    
    fileprivate func doInit(){
        log.debug("init")
        
        
        if (!initDone){
            self.backgroundColor = theme.backgroundColor
            
            
            initDone = true
            
        }
    }
    
    
    
    
    fileprivate func doLayout(){
        
        if (renderView != nil) {
            renderView?.frame = self.frame
            self.addSubview(renderView!)
            renderView?.fillSuperview()

            //renderView?.fillSuperview()
            //renderView?.anchorToEdge(.top, padding: 0, width: (renderView?.frame.size.width)!, height: (renderView?.frame.size.height)!)
            //renderView?.anchorInCenter((renderView?.frame.size.width)!, height: (renderView?.frame.size.height)!)
            imageView.isHidden = true
            renderView?.isHidden = false
            self.bringSubview(toFront: renderView!)
        } else {
            log.error("NIL render view")
        }
    }

    
    fileprivate func setRenderViewSize(){
        // maintain aspect ratio and fit inside available space
        
        var srcSize = ImageManager.getCurrentEditImageSize()
        
        //HACK: if there was an issue with the edit image, then the size wil be zero
        if (srcSize.width<0.01) || (srcSize.height<0.01) {
            srcSize = self.frame.size
        }
        
        var tgtRect:CGRect
        tgtRect = CGRect(origin: CGPoint.zero, size: self.frame.size)
        
        let rect = ImageManager.fitIntoRect(srcSize: srcSize, targetRect: tgtRect, withContentMode: .scaleAspectFit)
        renderView?.frame.size.width = rect.width
        renderView?.frame.size.height = rect.height
        log.debug("View:(\(self.frame.size.width), \(self.frame.size.height)) Tgt: (\(srcSize.width),\(srcSize.height)) Rect:(\(rect.width),\(rect.height))")
    }

    
    
    
    ///////////////////////////////////
    // MARK: - Accessors
    ///////////////////////////////////
    
    open func saveImage(_ url:URL){
        //lastFilter?.saveNextFrameToURL(url, format:.png)
        saveToPhotoAlbum(url) // saves asynchronously
    }
    
    
    // Saves the photo file at the supplied URL to the Camera Roll (asynchronously). Doesn't always work if synchronous
    fileprivate func saveToPhotoAlbum(_ url:URL){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let image = UIImage(contentsOfFile: url.path)
            if (image != nil){
                UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
            } else {
                log.error("Error saving photo")
            }
        }
    }
   
    open func setFilter(key:String){
        //currFilterKey = filterManager.getSelectedFilter()
        if (!key.isEmpty){
            currFilterKey = key
            currFilterDescriptor = filterManager.getFilterDescriptor(key: currFilterKey)
            //renderView = filterManager.getRenderView(key: currFilterKey)!
            update()
        } else {
            log.error("Empty key specified")
        }
    }
    
    open func updateImage(){
        DispatchQueue.main.async(execute: { () -> Void in
            self.filterManager.releaseRenderView(key: self.currFilterKey)
            self.currPhotoInput = ImageManager.getCurrentEditInput()
            if self.currPhotoInput == nil {
                self.currPhotoInput = ImageManager.getCurrentSampleInput()
            }
            self.update()
        })
    }
    
    open func update(){
        log.verbose("update requested")
        DispatchQueue.main.async(execute: { () -> Void in
            self.doLayout()
            self.runFilter()
        })
    }
    
   
    ///////////////////////////////////
    // MARK: pipeline setup
    ///////////////////////////////////
    
    // Sets up the filter pipeline. Call when filter, orientation or camera changes
    open func runFilter(){

        DispatchQueue.main.async(execute: { () -> Void in
            
            // only run if the edit image has been set
            if (self.currPhotoInput != nil){
                self.currFilterDescriptor = self.filterManager.getFilterDescriptor(key: self.currFilterKey)
                /***
                //self.renderView = self.filterManager.getRenderView(key: self.currFilterKey)
                if (self.renderView != nil) {
                    //self.setRenderViewSize()
                    self.addSubview(self.renderView!)
                    self.renderView?.fillSuperview()
                   self.renderView?.anchorToEdge(.top, padding: 0, width: (self.renderView?.frame.size.width)!, height: (self.renderView?.frame.size.height)!)
                }
                 ***/
                self.renderView?.image = self.currFilterDescriptor?.apply(image: self.currPhotoInput)
            } else {
                log.debug("Edit image not set, ignoring")
            }
        })
    }
    
    
    func suspend(){

    }
    
    
    ///////////////////////////////////
    // MARK: - Utilities
    ///////////////////////////////////
    
    
    
}
