//
//  FilterDisplayView.swift
//  FilterCam
//
//  Created by Philip Price on 9/16/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import GPUImage
import AVFoundation


// Class responsible for laying out the Camera Display View (i.e. what is currently viewed throughthe camera)
class FilterDisplayView: UIView {
 

    //fileprivate var renderView: RenderView! // only allocate when needed
    fileprivate var renderView: RenderView? = nil
    fileprivate var imageView: UIImageView! = UIImageView()
    fileprivate var useImage:Bool = false
    
    fileprivate var initDone: Bool = false
    fileprivate var filterManager = FilterManager.sharedInstance
    fileprivate var currFilterKey:String = ""
    fileprivate var currFilterDescriptor: FilterDescriptorInterface? = nil
    
    fileprivate var filter:BasicOperation? = nil
    fileprivate var filterGroup:OperationGroup? = nil
    fileprivate var opacityFilter:OpacityAdjustment? = nil

    
    
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
    
    
    open func setFilter(key:String){
        //currFilterKey = filterManager.getSelectedFilter()
        currFilterKey = key
        currFilterDescriptor = filterManager.getFilterDescriptor(key: currFilterKey)
        renderView = filterManager.getRenderView(key: currFilterKey)!
        update()
    }
    
    
    
    open func update(){
        log.verbose("update requested")
        DispatchQueue.main.async(execute: { () -> Void in
            self.doLayout()
            self.runFilter()
        })
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
                self.addSubview(renderView!)
                renderView?.fillSuperview()
                imageView.isHidden = true
                renderView?.isHidden = false
                self.bringSubview(toFront: renderView!)
                renderView?.fillSuperview()
            }
        }
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

        
        if (useImage){
            runFilterToImage()
        } else {
            runFilterToRender()
        }
    }
    
    
    
    fileprivate func runFilterToImage(){
        
        currFilterDescriptor = filterManager.getFilterDescriptor(key: currFilterKey)
        
        
        // get the current blend image and scale it match the sample image
        var sampleImageFull:UIImage? = nil
        var blendImageFull:UIImage? = nil
        var sampleImageSmall:UIImage? = nil
        var blendImageSmall:UIImage? = nil
        var sample:PictureInput? = nil
        var blend:PictureInput? = nil
        var filteredOutput:PictureOutput? = nil

        //sampleImageFull = UIImage(named:"sample_emma_01.png")
        sampleImageFull = ImageManager.getCurrentSampleImage()
        
        let reduceSize:Bool = false // set to true if you need to reduce the image size/resolution
        
        if (reduceSize){
            let size = (sampleImageFull?.size.applying(CGAffineTransform(scaleX: 0.5, y: 0.5)))!
            sampleImageSmall = ImageManager.scaleImage(sampleImageFull, widthRatio: 0.5, heightRatio: 0.5)
            blendImageSmall = ImageManager.getCurrentBlendImage(size:size)
            sample = PictureInput(image:sampleImageSmall!)
            blend  = PictureInput(image:blendImageSmall!)
        } else {
            blendImageFull  = ImageManager.getCurrentBlendImage(size:(sampleImageFull?.size)!)
            sample = PictureInput(image:sampleImageFull!)
            blend  = PictureInput(image:blendImageFull!)
        }
       
        
        guard (sample != nil) else {
            log.error("NIL Sample Input")
            return
        }
        
        guard (blend != nil) else {
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
            opacityFilter?.opacity = 0.8
        }
        
        // annoyingly, we have to treat single and multiple filters differently
        if (currFilterDescriptor?.filter != nil){ // single filter

            filter = currFilterDescriptor?.filter
            //log.debug("Run filter: \((currFilterDescriptor?.key)!) address:\(Utilities.addressOf(filter))")
            
            let opType:FilterOperationType = (currFilterDescriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                log.debug("filter: \((currFilterDescriptor?.key)!) address:\(Utilities.addressOf(filter))")
                sample! --> filter! --> filteredOutput!
                break
            case .blend:
                log.debug("BLEND filter: \(currFilterDescriptor?.key) opacity:\(opacityFilter?.opacity)")
                sample!.addTarget(filter!)
                blend! --> opacityFilter! --> filter!
                sample! --> filter! --> filteredOutput!
                blend?.processImage(synchronously: true)
                break
            }
            
        } else if (currFilterDescriptor?.filterGroup != nil){ // group of filters
            //log.debug("filterGroup: \(currFilterDescriptor?.key)")
            filterGroup = currFilterDescriptor?.filterGroup
            //log.debug("Run filterGroup: \(currFilterDescriptor?.key) address:\(Utilities.addressOf(filterGroup))")
            
            let opType:FilterOperationType = (currFilterDescriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                log.debug("filterGroup: \(currFilterDescriptor?.key)")
                sample! --> filterGroup! --> filteredOutput!
                break
            case .blend:
                log.debug("BLEND filter: \(currFilterDescriptor?.key) opacity:\(opacityFilter?.opacity)")
                sample!.addTarget(filterGroup!)
                blend! --> opacityFilter! --> filterGroup!
                sample! --> filterGroup! --> filteredOutput!
                blend?.processImage(synchronously: true)
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
        sample?.processImage(synchronously: true)
        

    }
    
    
    
    
    fileprivate func runFilterToRender(){
    
/**
        let sampleImageFull:UIImage = UIImage(named:"sample_emma_01.png")!
        let blendImageFull:UIImage = UIImage(named:"bl_topaz_warm.png")!
        var sample:PictureInput? = nil
        var blend:PictureInput? = nil
        //var filteredOutput:PictureOutput? = nil
 **/
        
        
        var descriptor: FilterDescriptorInterface?
        
        guard (renderView != nil) else {
            log.error("ERR: RenderView not set up")
            return
        }
        
        //sampleImageFull = UIImage(named:"sample_emma_01.png")!
        //blendImageFull = UIImage(named:"bl_topaz_warm.png")!
        
        
        
        // get the current blend image and scale it match the sample image
        var sampleImageFull:UIImage? = nil
        var blendImageFull:UIImage? = nil
        //var sampleImageSmall:UIImage? = nil
        //var blendImageSmall:UIImage? = nil
        var sample:PictureInput? = nil
        var blend:PictureInput? = nil
        //var filteredOutput:PictureOutput? = nil
        
        //sampleImageFull = UIImage(named:"sample_emma_01.png")
        sampleImageFull = ImageManager.getCurrentSampleImage() // reload each time because it can change
        
        let size = (sampleImageFull?.size)!
        //sampleImageSmall = ImageManager.scaleImage(sampleImageFull, widthRatio: 0.5, heightRatio: 0.5)

        blendImageFull = ImageManager.getCurrentBlendImage(size: size)
        
        sample = PictureInput(image:sampleImageFull!)
        blend  = PictureInput(image:blendImageFull!)
        
        
        //sample = PictureInput(image:sampleImageFull)
        //blend = PictureInput(image:blendImageFull)
        
        descriptor = filterManager.getFilterDescriptor(key: currFilterKey)
        renderView = filterManager.getRenderView(key: currFilterKey)
        
        guard (sample != nil) else {
            log.error("NIL Sample Input")
            return
        }
        
        guard (blend != nil) else {
            log.error("NIL Blend Input")
            return
        }
        
        guard (descriptor != nil) else {
            log.error("NIL Filter Descriptor")
            return
        }
        
        sample?.removeAllTargets()
        blend?.removeAllTargets()
        
        // reduce opacity of blends by default
        if (opacityFilter == nil){
            opacityFilter = OpacityAdjustment()
            opacityFilter?.opacity = 0.8
        }
        
        // annoyingly, we have to treat single and multiple filters differently
        if (descriptor?.filter != nil){ // single filter
            filter = descriptor?.filter
            filter?.removeAllTargets()
            
            //log.debug("Run filter: \((descriptor?.key)!) filter:\(Utilities.addressOf(filter)) view:\(Utilities.addressOf(renderView))")
            
            let opType:FilterOperationType = (descriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                log.debug("filter: \(descriptor?.key) address:\(Utilities.addressOf(filter))")
                //sample! --> filter! --> self.renderView!
                sample! --> filter! --> self.renderView!
                sample?.processImage(synchronously: true)
                break
            case .blend:
                log.debug("BLEND filter: \(currFilterDescriptor?.key) opacity:\(opacityFilter?.opacity)")
                sample!.addTarget(filter!)
                blend! --> opacityFilter! --> filter!
                sample! --> filter! --> self.renderView!
                blend?.processImage(synchronously: true)
                sample?.processImage(synchronously: true)
                break
            }
            
        } else if (descriptor?.filterGroup != nil){ // group of filters
            filterGroup = descriptor?.filterGroup
            filterGroup?.removeAllTargets()
            //log.debug("Run filterGroup: \(descriptor?.key) group:\(Utilities.addressOf(filterGroup)) view:\(Utilities.addressOf(renderView))")
            
            let opType:FilterOperationType = (descriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                log.debug("filterGroup: \(descriptor?.key)")
                sample! --> filterGroup! --> self.renderView!
                sample?.processImage(synchronously: true)
                break
            case .blend:
                log.debug("BLEND filter: \(currFilterDescriptor?.key) opacity:\(opacityFilter?.opacity)")
                sample!.addTarget(filterGroup!)
                blend! --> opacityFilter! --> filterGroup!
                sample! --> filterGroup! --> self.renderView!
                blend?.processImage(synchronously: true)
                sample?.processImage(synchronously: true)
                break
            }
        } else {
            log.error("ERR!!! shouldn't be here!!!")
        }
        

        self.renderView?.setNeedsDisplay()
        
        sample?.removeAllTargets()
        blend?.removeAllTargets()
        filter?.removeAllTargets()
        filterGroup?.removeAllTargets()
    }
    
    
    func suspend(){
        currFilterDescriptor?.filter?.removeAllTargets()
        currFilterDescriptor?.filterGroup?.removeAllTargets()
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
