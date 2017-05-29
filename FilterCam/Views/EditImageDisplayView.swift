//
//  EditImageDisplayView.swift
//  FilterCam
//
//  Created by Philip Price on 9/16/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import GPUImage
import AVFoundation


// Class responsible for displaying the edited image, with standard filters applied
class EditImageDisplayView: UIView {
 

    //fileprivate var renderView: RenderView! // only allocate when needed
    fileprivate var renderView: RenderView? = nil
    fileprivate var imageView: UIImageView! = UIImageView()
    fileprivate var useImage:Bool = false
    
    fileprivate var initDone: Bool = false
    fileprivate var filterManager = FilterManager.sharedInstance
    
    
    fileprivate var currPhotoInput:PictureInput? = nil
    fileprivate var currBlendInput:PictureInput? = nil
    
    fileprivate var currFilterKey:String = ""
    fileprivate var currFilterDescriptor: FilterDescriptorInterface? = nil
    
    fileprivate var filter:BasicOperation? = nil
    fileprivate var filterGroup:OperationGroup? = nil
    fileprivate var opacityFilter:OpacityAdjustment? = nil
    fileprivate var lastFilter:OpacityAdjustment? = nil

    
    
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
            self.backgroundColor = UIColor.black
            
            
            initDone = true
            
        }
    }
    
    
    
    
    fileprivate func doLayout(){
        if (useImage){
            imageView?.frame = self.frame
            self.addSubview(imageView!)
            imageView?.fillSuperview()
            imageView.isHidden = false
            if (renderView != nil) { renderView?.isHidden = true }
            self.bringSubview(toFront: imageView)
            imageView.fillSuperview()
        } else {
            if (renderView != nil) {
                //renderView = RenderView()
                renderView?.frame = self.frame
                
                setRenderViewSize()
                
                self.addSubview(renderView!)
                //renderView?.fillSuperview()
                renderView?.anchorToEdge(.top, padding: 0, width: (renderView?.frame.size.width)!, height: (renderView?.frame.size.height)!)
                //renderView?.anchorInCenter((renderView?.frame.size.width)!, height: (renderView?.frame.size.height)!)
                imageView.isHidden = true
                renderView?.isHidden = false
                self.bringSubview(toFront: renderView!)
                //renderView?.fillSuperview()
            }
        }
    }

    
    fileprivate func setRenderViewSize(){
        // maintain aspect ratio and fit inside available space
        
        let srcSize = ImageManager.getCurrentEditImageSize()
        let tgtRect:CGRect = CGRect(origin: CGPoint.zero, size: self.frame.size)
        let rect = ImageManager.fitIntoRect(srcSize: srcSize, targetRect: tgtRect, withContentMode: .scaleAspectFit)
        renderView?.frame.size.width = rect.width
        renderView?.frame.size.height = rect.height
        log.debug("View:(\(self.frame.size.width), \(self.frame.size.height)) Tgt: (\(srcSize.width),\(srcSize.height)) Rect:(\(rect.width),\(rect.height))")
    }

    
    
    
    ///////////////////////////////////
    // MARK: - Accessors
    ///////////////////////////////////
    
    open func saveImage(_ url:URL){
        lastFilter?.saveNextFrameToURL(url, format:.png)
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
            renderView = filterManager.getRenderView(key: currFilterKey)!
            update()
        } else {
            log.error("Empty key specified")
        }
    }
    
    open func updateImage(){
        DispatchQueue.main.async(execute: { () -> Void in
            self.filterManager.releaseRenderView(key: self.currFilterKey)
            self.currPhotoInput = ImageManager.getCurrentEditInput()
            self.currPhotoInput?.removeAllTargets()
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
        
        
        // cleanup - needed?!
        //filter?.removeAllTargets()
        //filterGroup?.removeAllTargets()
        //sample?.removeAllTargets()
        //blend?.removeAllTargets()

        DispatchQueue.main.async(execute: { () -> Void in
            
            // only run if the edit image has been set
            if (self.currPhotoInput != nil){
                if (self.useImage){
                    self.runFilterToImage()
                } else {
                    self.runFilterToRender()
                }
            } else {
                log.debug("Edit image not set, ignoring")
            }
        })
    }
    
    
    
    fileprivate func runFilterToImage(){
        
        currFilterDescriptor = filterManager.getFilterDescriptor(key: currFilterKey)
        
        
        // get the current blend image and scale it match the sample image
        var editImageFull:UIImage? = nil
        var blendImageFull:UIImage? = nil
        var editImageSmall:UIImage? = nil
        var blendImageSmall:UIImage? = nil
        //var sample:PictureInput? = nil
        //var blend:PictureInput? = nil
        var filteredOutput:PictureOutput? = nil

        editImageFull = ImageManager.getCurrentEditImage()
        
        let reduceSize:Bool = false // set to true if you need to reduce the image size/resolution
        
        if (reduceSize){
            let size = (editImageFull?.size.applying(CGAffineTransform(scaleX: 0.5, y: 0.5)))!
            editImageSmall = ImageManager.scaleImage(editImageFull, widthRatio: 0.5, heightRatio: 0.5)
            blendImageSmall = ImageManager.getCurrentBlendImage(size:size)
            currPhotoInput = PictureInput(image:editImageSmall!)
            currBlendInput  = PictureInput(image:blendImageSmall!)
        } else {
            blendImageFull  = ImageManager.getCurrentBlendImage(size:(editImageFull?.size)!)
            currPhotoInput = ImageManager.getCurrentEditInput()
            currBlendInput = ImageManager.getCurrentBlendInput()
        }
       
        
        guard (currPhotoInput != nil) else {
            log.error("NIL Edit Input")
            return
        }
        
        guard (currBlendInput != nil) else {
            log.error("NIL Blend Input")
            return
        }
        
        guard (currFilterDescriptor != nil) else {
            log.error("NIL Filter Descriptor")
            return
        }
       
        // set up the output variable
        filteredOutput = PictureOutput()
        filteredOutput?.encodedImageFormat = .png
        //filteredOutput?.onlyCaptureNextFrame = true
        filteredOutput?.onlyCaptureNextFrame = false
        
        
        // reduce opacity of blends by default
        if (opacityFilter == nil){
            opacityFilter = OpacityAdjustment()
            opacityFilter?.opacity = 0.7
        }
        
        // annoyingly, we have to treat single and multiple filters differently
        if (currFilterDescriptor?.filter != nil){ // single filter

            filter = currFilterDescriptor?.filter
            //log.debug("Run filter: \((currFilterDescriptor?.key)!) address:\(Utilities.addressOf(filter))")
            
            let opType:FilterOperationType = (currFilterDescriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                log.debug("filter: \((currFilterDescriptor?.key)!) address:\(Utilities.addressOf(filter))")
                currPhotoInput! --> filter! --> filteredOutput!
                break
            case .blend:
                log.debug("BLEND filter: \(String(describing: currFilterDescriptor?.key)) opacity:\(String(describing: opacityFilter?.opacity))")
                currPhotoInput!.addTarget(filter!)
                currBlendInput! --> opacityFilter! --> filter!
                currPhotoInput! --> filter! --> filteredOutput!
                currBlendInput?.processImage(synchronously: true)
                break
            }
            
        } else if (currFilterDescriptor?.filterGroup != nil){ // group of filters
            //log.debug("filterGroup: \(currFilterDescriptor?.key)")
            filterGroup = currFilterDescriptor?.filterGroup
            //log.debug("Run filterGroup: \(currFilterDescriptor?.key) address:\(Utilities.addressOf(filterGroup))")
            
            let opType:FilterOperationType = (currFilterDescriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                log.debug("filterGroup: \(String(describing: currFilterDescriptor?.key))")
                currPhotoInput! --> filterGroup! --> filteredOutput!
                break
            case .blend:
                log.debug("BLEND filter: \(String(describing: currFilterDescriptor?.key)) opacity:\(String(describing: opacityFilter?.opacity))")
                currPhotoInput!.addTarget(filterGroup!)
                currBlendInput! --> opacityFilter! --> filterGroup!
                currPhotoInput! --> filterGroup! --> filteredOutput!
                currBlendInput?.processImage(synchronously: true)
                break
            }
        } else {
            log.error("ERR!!! shouldn't be here!!!")
        }
        
        filteredOutput?.imageAvailableCallback = { filteredImage in
            self.imageView.image = filteredImage
            self.imageView.setNeedsDisplay()
            log.verbose ("Image processed: \((self.currFilterDescriptor?.key)!)")
        }
        currPhotoInput?.processImage(synchronously: true)
        

    }
    
    
    
    
    fileprivate func runFilterToRender(){
    
        
        var descriptor: FilterDescriptorInterface?
        
        //guard (renderView != nil) else {
        //    log.error("ERR: RenderView not set up")
        //    return
        //}
        
        //editImageFull = UIImage(named:"sample_9989.png")!
        //blendImageFull = UIImage(named:"bl_topaz_warm.png")!
        
        
        
        // get the current blend image and scale it match the sample image
        var editImageFull:UIImage? = nil
        var blendImageFull:UIImage? = nil

        editImageFull = ImageManager.getCurrentEditImage() // reload each time because it can change
        
        let size = ImageManager.getCurrentEditImageSize()
        //editImageSmall = ImageManager.scaleImage(editImageFull, widthRatio: 0.5, heightRatio: 0.5)

        blendImageFull = ImageManager.getCurrentBlendImage(size: size)
        
        // sample and blend images can change, so load each time through
        // TODO: track name, only load if they change
        currPhotoInput = ImageManager.getCurrentEditInput()
        currBlendInput  = PictureInput(image: blendImageFull!)
        
        currPhotoInput?.removeAllTargets()
        currBlendInput?.removeAllTargets()
        
        descriptor = filterManager.getFilterDescriptor(key: currFilterKey)
        renderView = filterManager.getRenderView(key: currFilterKey)
        if (renderView != nil) {
            setRenderViewSize()
            self.addSubview(renderView!)
            renderView?.anchorToEdge(.top, padding: 0, width: (renderView?.frame.size.width)!, height: (renderView?.frame.size.height)!)
            //renderView?.fillSuperview()
        }
        
        guard (currPhotoInput != nil) else {
            log.error("NIL Edit Input")
            return
        }
        
        guard (currBlendInput != nil) else {
            log.error("NIL Blend Input")
            return
        }
        
        guard (descriptor != nil) else {
            log.error("NIL Filter Descriptor")
            return
        }
        
        
        // reduce opacity of blends by default
        if (opacityFilter == nil){
            opacityFilter = OpacityAdjustment()
            opacityFilter?.opacity = 0.7
        }
        
        // annoyingly, we have to treat single and multiple filters differently
        if (descriptor?.filter != nil){ // single filter
            filter = descriptor?.filter
            filter?.removeAllTargets()
            
            //log.debug("Run filter: \((descriptor?.key)!) filter:\(Utilities.addressOf(filter)) view:\(Utilities.addressOf(renderView))")

            
            let opType:FilterOperationType = (descriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                log.debug("filter: \(String(describing: descriptor?.key)) address:\(Utilities.addressOf(filter))")
                //sample! --> filter! --> self.renderView!
                currPhotoInput! --> filter! --> self.renderView!
                currPhotoInput?.processImage(synchronously: true)
                break
            case .blend:
                log.debug("BLEND filter: \(String(describing: currFilterDescriptor?.key)) opacity:\(String(describing: opacityFilter?.opacity))")
                log.debug("Edit:(\((editImageFull?.size.width)!),\((editImageFull?.size.height)!)) Blend:(\((blendImageFull?.size.width)!),\((blendImageFull?.size.height)!))")
                //currPhotoInput!.addTarget(filter!)
                currBlendInput! --> opacityFilter! --> filter!
                currPhotoInput! --> filter! --> self.renderView!
                currBlendInput?.processImage(synchronously: true)
                currPhotoInput?.processImage(synchronously: true)
                break
            }
/***
            let targets = filter?.targets
            for (target, index) in targets! {
                filter?.transmitPreviousImage(to: target, atIndex: index)
            }
 ***/
            
        } else if (descriptor?.filterGroup != nil){ // group of filters
            filterGroup = descriptor?.filterGroup
            filterGroup?.removeAllTargets()
            //log.debug("Run filterGroup: \(descriptor?.key) group:\(Utilities.addressOf(filterGroup)) view:\(Utilities.addressOf(renderView))")
            
            // TEMP DEBUG:
            if (descriptor is PresetDescriptor){
                let preset:PresetDescriptor = descriptor as! PresetDescriptor
                preset.logParameters()
            }
            
            let opType:FilterOperationType = (descriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                log.debug("filterGroup: \(String(describing: descriptor?.key))")
                currPhotoInput! --> filterGroup! --> self.renderView!
                currPhotoInput?.processImage(synchronously: true)
                break
            case .blend:
                log.debug("BLEND filter: \(String(describing: currFilterDescriptor?.key)) opacity:\(String(describing: opacityFilter?.opacity))")
                //currPhotoInput!.addTarget(filterGroup!)
                currBlendInput! --> opacityFilter! --> filterGroup!
                currPhotoInput! --> filterGroup! --> self.renderView!
                currBlendInput?.processImage(synchronously: true)
                currPhotoInput?.processImage(synchronously: true)
                break
            }
            //currPhotoInput?.processImage() // run twice for group filters
/***
            let targets = filterGroup?.targets
            for (target, index) in targets! {
                filterGroup?.transmitPreviousImage(to: target, atIndex: index)
            }
 ***/

        } else {
            log.error("ERR!!! shouldn't be here!!!")
        }
        

        //self.renderView?.setNeedsDisplay()
        //self.renderView?.setNeedsLayout()
        
        //currPhotoInput?.removeAllTargets()
        //currBlendInput?.removeAllTargets()
        //filter?.removeAllTargets()
        //filterGroup?.removeAllTargets()
    }
    
    
    func suspend(){
        //currFilterDescriptor?.filter?.removeAllTargets()
        //currFilterDescriptor?.filterGroup?.removeAllTargets()
        //if (currFilterDescriptor != nil){
        //    filterManager.releaseFilterDescriptor(key: (currFilterDescriptor?.key)!)
        //    filterManager.releaseRenderView(key: (currFilterDescriptor?.key)!)
        //}
        opacityFilter?.removeAllTargets()
        currBlendInput?.removeAllTargets()
        currPhotoInput?.removeAllTargets()
        //sample?.removeAllTargets()
        //blend?.removeAllTargets()
    }
    
    
    ///////////////////////////////////
    // MARK: - Utilities
    ///////////////////////////////////
    
    
    fileprivate func removeTargets(_ from: FilterDescriptorInterface?){
        guard (from != nil) else {
            return
        }
        
        if (from?.filter != nil){
            log.debug("Removing targets from filter")
            from?.filter?.removeAllTargets()
        }
        
        if (from?.filterGroup != nil){
            log.debug("Removing targets from filter group")
            from?.filterGroup?.removeAllTargets()
        }
    }
    
    
}
