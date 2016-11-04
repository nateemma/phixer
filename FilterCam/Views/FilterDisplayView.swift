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
    
/***
    // vars are class-scope so that they stay allocated
    fileprivate var sampleImageFull:UIImage = UIImage(named:"sample_emma_01.png")!
    fileprivate var blendImageFull:UIImage = UIImage(named:"bl_topaz_warm.png")!
    fileprivate var sample:PictureInput? = nil
    fileprivate var blend:PictureInput? = nil
    fileprivate var filteredOutput:PictureOutput? = nil
***/


    fileprivate var filter:BasicOperation? = nil
    fileprivate var filterGroup:OperationGroup? = nil
/***/
    
    
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
        /***
        if (currFilterDescriptor == nil){
            currFilterKey = filterManager.getSelectedFilter()
            currFilterDescriptor = filterManager.getFilterDescriptor(key: currFilterKey)
            if (currFilterDescriptor == nil){
                log.warning("NIL descriptor provided")
            } else {
                if (currFilterDescriptor?.filter != nil){
                    log.debug("descriptor:  \(currFilterDescriptor?.key) (\(Utilities.addressOf(currFilterDescriptor?.filter))")
                }
                if (currFilterDescriptor?.filterGroup != nil){
                    log.debug("descriptor:  \(currFilterDescriptor?.key) (\(Utilities.addressOf(currFilterDescriptor?.filterGroup))")
                }
                
            }
        }
        
***/
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
        
        var sampleImageFull:UIImage = UIImage(named:"sample_emma_01.png")!
        var blendImageFull:UIImage = UIImage(named:"bl_topaz_warm.png")!
        var sampleImageSmall:UIImage? = nil
        var blendImageSmall:UIImage? = nil
        var sample:PictureInput? = nil
        var blend:PictureInput? = nil
        var filteredOutput:PictureOutput? = nil

        currFilterDescriptor = filterManager.getFilterDescriptor(key: currFilterKey)

        
        
        sampleImageFull = UIImage(named:"sample_emma_01.png")!
        blendImageFull = UIImage(named:"bl_topaz_warm.png")!
        
        // create scaled down versions of the sample and blend images
        //TODO: let user choose image
        let size = sampleImageFull.size.applying(CGAffineTransform(scaleX: 0.8, y: 0.8))
        
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        // downsize input images since we really only need thumbnails
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        sampleImageFull.draw(in: CGRect(origin: CGPoint.zero, size: size))
        sampleImageSmall = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        blendImageFull.draw(in: CGRect(origin: CGPoint.zero, size: size))
        blendImageSmall = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        sample = PictureInput(image:sampleImageSmall!)
        blend  = PictureInput(image:blendImageSmall!)

        
        
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
        
        
        // annoyingly, we have to treat single and multiple filters differently
        if (currFilterDescriptor?.filter != nil){ // single filter

            filter = currFilterDescriptor?.filter
            log.debug("Run filter: \((currFilterDescriptor?.key)!) address:\(Utilities.addressOf(filter))")
            
            let opType:FilterOperationType = (currFilterDescriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                log.debug("filter: \((currFilterDescriptor?.key)!) address:\(Utilities.addressOf(filter))")
                sample! --> filter! --> filteredOutput!
                break
            case .blend:
                //log.debug("Using BLEND mode for filter: \(currFilterDescriptor?.key)")
                //TOFIX: blend image needs to be resized to fit the render view
                sample!.addTarget(filter!)
                blend! --> filter!
                sample! --> filter! --> filteredOutput!
                blend?.processImage(synchronously: true)
                break
            }
            
        } else if (currFilterDescriptor?.filterGroup != nil){ // group of filters
            //log.debug("filterGroup: \(currFilterDescriptor?.key)")
            filterGroup = currFilterDescriptor?.filterGroup
            log.debug("Run filterGroup: \(currFilterDescriptor?.key) address:\(Utilities.addressOf(filterGroup))")
            
            let opType:FilterOperationType = (currFilterDescriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                log.debug("filterGroup: \(currFilterDescriptor?.key)")
                sample! --> filterGroup! --> filteredOutput!
                break
            case .blend:
                //log.debug("Using BLEND mode for group: \(currFilterDescriptor?.key)")
                //TOFIX: blend image needs to be resized to fit the render view
                sample!.addTarget(filterGroup!)
                blend! --> filterGroup!
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
        sample?.processImage()
        

    }
    
    
    
    
    fileprivate func runFilterToRender(){
        
        let sampleImageFull:UIImage = UIImage(named:"sample_emma_01.png")!
        let blendImageFull:UIImage = UIImage(named:"bl_topaz_warm.png")!
        var sample:PictureInput? = nil
        var blend:PictureInput? = nil
        //var filteredOutput:PictureOutput? = nil
        var descriptor: FilterDescriptorInterface?
        
        guard (renderView != nil) else {
            log.error("ERR: RenderView not set up")
            return
        }
        
        //sampleImageFull = UIImage(named:"sample_emma_01.png")!
        //blendImageFull = UIImage(named:"bl_topaz_warm.png")!
        sample = PictureInput(image:sampleImageFull)
        blend = PictureInput(image:blendImageFull)
        
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
        
        
        // annoyingly, we have to treat single and multiple filters differently
        if (descriptor?.filter != nil){ // single filter
            filter = descriptor?.filter
            
            log.debug("Run filter: \((descriptor?.key)!) filter:\(Utilities.addressOf(filter)) view:\(Utilities.addressOf(renderView))")
            
            let opType:FilterOperationType = (descriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                //log.debug("filter: \(descriptor?.key) address:\(Utilities.addressOf(filter))")
                //sample! --> filter! --> self.renderView!
                sample! --> filter! --> self.renderView!
                sample?.processImage(synchronously: true)
                break
            case .blend:
                //log.debug("Using BLEND mode for filter: \(descriptor?.key)")
                //TOFIX: blend image needs to be resized to fit the render view
                sample!.addTarget(filter!)
                blend! --> filter!
                sample! --> filter! --> self.renderView!
                blend?.processImage(synchronously: true)
                sample?.processImage(synchronously: true)
                break
            }
            
        } else if (descriptor?.filterGroup != nil){ // group of filters
            filterGroup = descriptor?.filterGroup
            log.debug("Run filterGroup: \(descriptor?.key) group:\(Utilities.addressOf(filterGroup)) view:\(Utilities.addressOf(renderView))")
            
            let opType:FilterOperationType = (descriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                //log.debug("filterGroup: \(descriptor?.key)")
                sample! --> filterGroup! --> self.renderView!
                sample?.processImage(synchronously: true)
                break
            case .blend:
                //log.debug("Using BLEND mode for group: \(descriptor?.key)")
                //TOFIX: blend image needs to be resized to fit the render view
                sample!.addTarget(filterGroup!)
                blend! --> filterGroup!
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
