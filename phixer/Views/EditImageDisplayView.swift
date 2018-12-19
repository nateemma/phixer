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


// Class responsible for displaying the edited image, with the full stack of filters applied
// Note that filters are not saved to the edit stack, that is the responsibility of the ViewController
class EditImageDisplayView: UIView {
    
    var theme = ThemeManager.currentTheme()
    


    fileprivate var renderView: MetalImageView? = MetalImageView()
    fileprivate var imageView: UIImageView! = UIImageView()
    
    fileprivate var initDone: Bool = false
    fileprivate var layoutDone: Bool = false
    fileprivate var filterManager = FilterManager.sharedInstance
    
    
    fileprivate var currInput:CIImage? = nil
    fileprivate var currBlendInput:CIImage? = nil
    
    fileprivate var currFilterKey:String = ""
    //fileprivate var currFilterDescriptor: FilterDescriptor? = nil

    
    
    ///////////////////////////////////
    // MARK: - Setup/teardown
    ///////////////////////////////////
    convenience init(){
        self.init(frame: CGRect.zero)
        doInit()
    }
    
    
    deinit {
        //suspend()
    }

   
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //log.debug("layout")
       doInit()

        log.debug("layout")
        self.currInput = InputSource.getCurrentImage() // this can change
        renderView?.frame = self.frame
        renderView?.image = self.currInput
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
    
    fileprivate func doInit(){
        

        if (!initDone){
            //log.debug("init")
            self.backgroundColor = theme.backgroundColor
            
            //EditManager.reset()
            self.currInput = ImageManager.getCurrentEditImage()
            EditManager.setInputImage(self.currInput)

            self.layoutDone = false
            initDone = true
            
        }
    }
    


    
    
    
    ///////////////////////////////////
    // MARK: - Accessors
    ///////////////////////////////////
    
   
    open func setFilter(key:String){
        //currFilterKey = filterManager.getSelectedFilter()
        if (!key.isEmpty){
            currFilterKey = key

            EditManager.addPreviewFilter(filterManager.getFilterDescriptor(key: key))
            update()
        } else {
            log.error("Empty key specified")
        }
    }
    
    // saves the filtered image to the camera roll
    public func saveImage(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let ciimage = self.renderView?.image
            if (ciimage != nil){
                let cgimage = ciimage?.generateCGImage()
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
    
    open func updateImage(){
        DispatchQueue.main.async(execute: { () -> Void in
            log.verbose("Updating edit image")
            EditManager.setInputImage(InputSource.getCurrentImage())
            self.currInput = EditManager.outputImage
            if self.currInput == nil {
                log.warning("Edit image not set, using Sample")
                self.currInput = ImageManager.getCurrentSampleInput() // no edit image set, so make sure there is something
            }
            self.update()
        })
    }
    
    
   
    ///////////////////////////////////
    // MARK: pipeline setup
    ///////////////////////////////////
    
    // Sets up the filter pipeline. Call when filter, orientation or camera changes
    open func runFilter(){
        
        if !self.currFilterKey.isEmpty && layoutDone {
            DispatchQueue.main.async(execute: { () -> Void in
                self.renderView?.image = EditManager.outputImage
            })
        }
    }
    
    
    func suspend(){

    }
    
    
    ///////////////////////////////////
    // MARK: - Utilities
    ///////////////////////////////////
    
    
    
}
