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
    
    var renderView: RenderView! = RenderView()
    //var renderView: RenderView? = nil
    
    var initDone: Bool = false
    var filterManager = FilterManager.sharedInstance
    var currFilterDescriptor: FilterDescriptorInterface? = nil
    
/***
    // vars are class-scope so that they stay allocated
    var sampleImageFull:UIImage = UIImage(named:"sample_emma_01.png")!
    var blendImageFull:UIImage = UIImage(named:"bl_topaz_warm.png")!
    var sample:PictureInput? = nil
    var blend:PictureInput? = nil



    var filter:BasicOperation? = nil
    var filterGroup:OperationGroup? = nil
***/
    
    
    ///////////////////////////////////
    // MARK: - Setup/teardown
    ///////////////////////////////////
    convenience init(){
        self.init(frame: CGRect.zero)
    }
    
    
    func initViews(){
        
        if (filterManager == nil) { filterManager = FilterManager.sharedInstance }
        
        if (!initDone){
            self.backgroundColor = UIColor.black
            
            
            initDone = true
        }
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if (!initDone){
            initViews()
        }
        
        if (currFilterDescriptor == nil){
            currFilterDescriptor = filterManager.getSelectedFilter()
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
        
        //renderView = RenderView()
        //renderView.removeFromSuperview()
        renderView?.frame = self.frame
        self.addSubview(renderView!)
        
        renderView?.fillSuperview()
        
        runFilter()
        
        self.setNeedsDisplay()
    }
    
    deinit {
        //stopFilter()
    }
    
    
    open func setFilter(_ descriptor:FilterDescriptorInterface?){
        currFilterDescriptor = descriptor
    }
   
    ///////////////////////////////////
    // MARK: pipeline setup
    ///////////////////////////////////
    
    // Sets up the filter pipeline. Call when filter, orientation or camera changes
    func runFilter(){

        /***/
        // strange, here vars must be class scope
        var sampleImageFull:UIImage = UIImage(named:"sample_emma_01.png")!
        var blendImageFull:UIImage = UIImage(named:"bl_topaz_warm.png")!
        var sample:PictureInput? = nil
        var blend:PictureInput? = nil
        var filter:BasicOperation? = nil
        var filterGroup:OperationGroup? = nil
        /***/

        do {
            guard (renderView != nil) else {
                log.error("ERR: RenderView not set up")
                return
            }
            
            guard (initDone) else {
                log.error("ERR: not ready for pipeline setup")
                return
            }

            //TODO: start rendering in an asynch queue
            
            sampleImageFull = UIImage(named:"sample_emma_01.png")!
            blendImageFull = UIImage(named:"bl_topaz_warm.png")!
            sample = PictureInput(image:sampleImageFull)
            blend = PictureInput(image:blendImageFull)
            
            //currFilterDescriptor?.restoreParameters()
            currFilterDescriptor?.reset()
            
            guard (sample != nil) else {
                log.error("NIL Sample Input")
                return
            }
            
            guard (blend != nil) else {
                log.error("NIL Blend Input")
                return
            }
            
            //sample?.removeAllTargets()
            //blend?.removeAllTargets()
            
            // annoyingly, we have to treat single and multiple filters differently
            if (currFilterDescriptor?.filter != nil){ // single filter
                log.debug("Running filter: \(currFilterDescriptor?.key)")
                filter = currFilterDescriptor?.filter!
                //filter?.removeAllTargets()
                let opType:FilterOperationType = (currFilterDescriptor?.filterOperationType)!
                switch (opType){
                case .singleInput:
                    log.debug("filter: \((currFilterDescriptor?.key)!) address:\(Utilities.addressOf(filter))")
                    sample! --> filter! --> renderView!
                    break
                case .blend:
                    //log.debug("Using BLEND mode for filter: \(currFilterDescriptor.key)")
                    //TOFIX: blend image needs to be resized to fit the render view
                    sample!.addTarget(filter!)
                    blend! --> filter!
                    sample! --> filter! --> renderView!
                    blend?.processImage()
                    break
                }
                
            } else if (currFilterDescriptor?.filterGroup != nil){ // group of filters
                log.debug("Running  filterGroup: \(currFilterDescriptor?.key)")
                filterGroup = currFilterDescriptor?.filterGroup
                //filterGroup?.removeAllTargets()
                let opType:FilterOperationType = (currFilterDescriptor?.filterOperationType)!
                switch (opType){
                case .singleInput:
                    //log.debug("filterGroup: \(currFilterDescriptor?.key)")
                    sample! --> filterGroup! --> renderView!
                    break
                case .blend:
                    //log.debug("Using BLEND mode for group: \(currFilterDescriptor?.key)")
                    //TOFIX: blend image needs to be resized to fit the render view
                    sample!.addTarget(filterGroup!)
                    blend! --> filterGroup!
                    sample! --> filterGroup! --> renderView!
                    blend?.processImage()
                    break
                }
            } else {
                log.error("ERR!!! shouldn't be here!!!")
            }
            
            
            sample?.processImage(synchronously: true)
            
            //renderView?.setNeedsDisplay()
           
            
        } catch {
            log.error("Could not initialize rendering pipeline: \(error)")
        }
    }
    
    
    func stopFilter(){
        currFilterDescriptor?.filter?.removeAllTargets()
        currFilterDescriptor?.filterGroup?.removeAllTargets()
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
