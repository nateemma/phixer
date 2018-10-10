//
//  FilterDisplayView.swift
//  phixer
//
//  Created by Philip Price on 9/16/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import CoreImage
import AVFoundation


// Class responsible for displaying a filtered version of an image
class FilterDisplayView: UIView {
 


    fileprivate var renderView: MetalImageView? = nil
    
    fileprivate var initDone: Bool = false
    fileprivate var filterManager = FilterManager.sharedInstance
    
    
    fileprivate var currSampleInput:CIImage? = nil
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
        //suspend()
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
        renderView = filterManager.getRenderView(key: currFilterKey)
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

            if (renderView != nil) {
                //renderView = RenderView()
                renderView?.frame = self.frame
                
                setRenderViewSize()
                
                self.addSubview(renderView!)
                renderView?.anchorToEdge(.top, padding: 0, width: (renderView?.frame.size.width)!, height: (renderView?.frame.size.height)!)
                renderView?.isHidden = false
                self.bringSubview(toFront: renderView!)
                //renderView?.fillSuperview()
            }

    }

    
    fileprivate func setRenderViewSize(){
        // maintain aspect ratio and fit inside available space
        
        let srcSize = ImageManager.getCurrentSampleImageSize()
        let tgtRect:CGRect = CGRect(origin: CGPoint.zero, size: self.frame.size)
        let rect = ImageManager.fitIntoRect(srcSize: srcSize, targetRect: tgtRect, withContentMode: .scaleAspectFit)
        renderView?.frame.size.width = rect.width
        renderView?.frame.size.height = rect.height
        log.debug("View:(\(self.frame.size.width), \(self.frame.size.height)) Tgt: (\(srcSize.width),\(srcSize.height)) Rect:(\(rect.width),\(rect.height))")
    }

    
    ///////////////////////////////////
    // MARK: pipeline setup
    ///////////////////////////////////
    
    // Sets up the filter pipeline. Call when filter, orientation or camera changes
    open func runFilter(){
        

        DispatchQueue.main.async(execute: { () -> Void in
            
            self.currSampleInput = ImageManager.getCurrentSampleImage()!

            // get current filter
            self.currFilterDescriptor = self.filterManager.getFilterDescriptor(key: self.currFilterKey)
            self.renderView = self.filterManager.getRenderView(key: self.currFilterKey)

            // run the filter
           self.renderView?.image = self.currFilterDescriptor?.apply(image:self.currSampleInput)

        })
    }
    
   
    
    func suspend(){

    }
    
    
    ///////////////////////////////////
    // MARK: - Utilities
    ///////////////////////////////////
    
    
    
}
