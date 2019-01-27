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
// Note that only one filter is applied to the image, so this can be used to preview efects
class FilterDisplayView: UIView {
 
    
    var theme = ThemeManager.currentTheme()
    


    fileprivate var renderView: RenderView! = RenderView()
    
    fileprivate var initDone: Bool = false
    fileprivate var layoutDone: Bool = false
    fileprivate var filterManager = FilterManager.sharedInstance
    
    
    fileprivate var currImageInput:CIImage? = nil
    fileprivate var currBlendInput:CIImage? = nil
    
    fileprivate var currFilterKey:String = ""
    fileprivate var currFilterDescriptor: FilterDescriptor? = nil

    
    
    ///////////////////////////////////
    // MARK: - Setup/teardown
    ///////////////////////////////////
    convenience init(){
        self.init(frame: CGRect.zero)
        self.currFilterKey = ""
        self.currFilterDescriptor = nil
        self.layoutDone = false
    }
    
    
    deinit {
        //suspend()
    }

   
    override func layoutSubviews() {
        super.layoutSubviews()
        
        log.debug("layout")
        self.currImageInput = InputSource.getCurrentImage() // this can change
        renderView?.frame = self.frame
        renderView?.image = self.currImageInput
        renderView?.setImageSize(InputSource.getSize())
        renderView?.frame = self.frame
        renderView?.backgroundColor = theme.backgroundColor
        
        self.addSubview(renderView!)
        renderView?.fillSuperview()
       // self.bringSubview(toFront: renderView!)
        
        layoutDone = true
        
        // check to see if filter has already been set. If so update
        
       if !(currFilterKey.isEmpty) {
            update()
        }

    }
    
    
    open func setFilter(key:String){
        //currFilterKey = filterManager.getCurrentFilter()
        if (currFilterKey.isEmpty) || (key != currFilterKey) {
            currFilterKey = key
            currFilterDescriptor = filterManager.getFilterDescriptor(key: currFilterKey)
            EditManager.addPreviewFilter(currFilterDescriptor)
            log.verbose("key: \(key)")
       }
        update()

    }
    
    // saves the filtered image to the camera roll
    public func saveImage(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let ciimage = self.renderView?.image
            if (ciimage != nil){
                let cgimage = ciimage?.generateCGImage(size:(self.renderView?.image?.extent.size)!)
                let image = UIImage(cgImage: cgimage!)
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            } else {
                log.error("Error saving photo")
            }
        }
    }
    
    open func update(){
        if (layoutDone) {
            log.verbose("update requested")
            DispatchQueue.main.async(execute: { () -> Void in
                self.runFilter()
            })
        }
    }
    
    public func getImagePosition(viewPos:CGPoint) -> CIVector?{
        if renderView != nil {
            return renderView?.getImagePosition(viewPos: viewPos)
        } else {
            return CIVector(cgPoint: CGPoint.zero)
        }
    }
    
    fileprivate func doInit(){
        log.debug("init")
        
        
        if (!initDone){
            self.backgroundColor = theme.backgroundColor
            
            
            initDone = true
            
        }
    }
    
    

    
    ///////////////////////////////////
    // MARK: pipeline setup
    ///////////////////////////////////
    
    // Sets up the filter pipeline. Call when filter, orientation or camera changes
    open func runFilter(){
        
        if !self.currFilterKey.isEmpty && layoutDone {
            
            DispatchQueue.main.async(execute: { () -> Void in
                
                log.debug("Running filter: \(self.currFilterKey)")
                
                //self.currImageInput = ImageManager.getCurrentSampleImage()!
                self.currImageInput = InputSource.getCurrentImage()
                self.renderView?.setImageSize(InputSource.getSize())
                
                // get current filter
                //self.currFilterDescriptor = self.filterManager.getFilterDescriptor(key: self.currFilterKey)
                
                // run the filter and update the rendered image
                self.renderView?.image = self.currFilterDescriptor?.apply(image:self.currImageInput)
            })
        }
    }
    
   
    
    func suspend(){
        //self.filterManager.releaseRenderView(key: self.currFilterKey)
    }
    
    
    ///////////////////////////////////
    // MARK: - Utilities
    ///////////////////////////////////
    
    
    
}
