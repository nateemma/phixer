//
//  CameraDisplayView.swift
//  phixer
//
//  Created by Philip Price on 9/16/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import CoreImage
import AVFoundation


// Class responsible for laying out the Camera Display View (i.e. what is currently viewed throughthe camera)
class CameraDisplayView: UIView {
    
    //var renderView: RenderView? = RenderView()
    fileprivate var renderView: MetalImageView? = MetalImageView()
    fileprivate var currFilter: FilterDescriptor? = nil
    fileprivate var cameraImage:CIImage? = nil
    var initDone: Bool = false
    //var currFilter: FilterDescriptor? = nil
    var filterManager = FilterManager.sharedInstance
    var camera: CameraCaptureHelper? = nil
    //var cropFilter: Crop? = nil
    //var opacityFilter:OpacityAdjustment? = nil
    //var rotateDescriptor: RotateDescriptor? = nil
    //var rotateFilter: FilterDescriptor? = nil
    var blendImage:CIImage? = nil
    
    ///////////////////////////////////
    // MARK: - Setup/teardown
    ///////////////////////////////////
    convenience init(){
        self.init(frame: CGRect.zero)
    }
    
    /***
    func initViews(){
        
        if (!initDone){
            initDone = true
           //self.backgroundColor = UIColor.black
            //self.backgroundColor = UIColor.red

           
        }
    }
    ***/
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //if (!initDone){
        //    initViews()
        //}
        
        self.backgroundColor = UIColor.darkGray // DEBUG
        renderView?.frame = self.frame
        self.addSubview(renderView!)
        renderView?.fillSuperview()
        
        initDone = true
        updateDisplay()
        
    }
    
    deinit {
        suspend()
    }
    
    
    ///////////////////////////////////
    // MARK: pipeline setup
    ///////////////////////////////////
    
    // Sets up the filter pipeline. Call when filter, orientation or camera changes
    fileprivate func updateDisplay(){
        guard (renderView != nil) else {
            log.error("ERR: RenderView not set up")
            return
        }
        
        guard (initDone) else {
            log.error("ERR: not ready for pipeline setup")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateDisplay()
            }
            return
        }
        
        //renderView?.fillSuperview()
         if (camera == nil){
            //camera = CameraCaptureHelper(cameraPosition: AVCaptureDevice.Position.back)
            camera = CameraCaptureHelper() // just use default device, or whatever was already set up
            camera?.register(delegate:self, key:#file)   
            camera?.start()
        }
        
        if (camera != nil){
            
            if (currFilter == nil){
                log.debug("No filter applied, using direct camera feed")
                renderView?.image = cameraImage
            } else {
                renderView?.image = currFilter?.apply(image:cameraImage)
            }
        } else {
            log.warning("No camera active, ignoring")
        }
    }
    
    
    // Suspend all operations
    public func suspend(){
        log.debug("suspend()")
        camera?.stop()
        currFilter = nil
        //camera?.delegate = self
        camera?.deregister()

    }
    
    ///////////////////////////////////
    // MARK: - Utilities
    ///////////////////////////////////
    
    // sets the filter to be applied (nil for no filter)
    public func setFilter(_ descriptor: FilterDescriptor?){
        if (currFilter?.key != descriptor?.key){
            log.debug("\(String(describing: currFilter?.key))->\(String(describing: descriptor?.key))")
            currFilter = descriptor
            updateDisplay()
            if (camera != nil) { camera?.start() }
        } //else {
        //    log.debug("Ignoring \(currFilter?.key)->\(descriptor?.key) change")
        //}
    }
    
    
    
    public func takePhoto(){
        camera?.takePhoto()
    }
    
    
    // saves the currently displayed image to the Camera Roll
    public func saveImage(_ url: URL){
        log.debug("Saving image to URL: \(url.path)")
        saveToPhotoAlbum(url) // saves asynchronously
        
    }
    
    // Saves the photo file at the supplied URL to the Camera Roll (asynchronously). Doesn't always work if synchronous
    func saveToPhotoAlbum(_ url:URL){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let image = UIImage(contentsOfFile: url.path)
            if (image != nil){
                UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
            } else {
                log.error("Error saving photo")
            }
        }
    }
    
    // toggle camera (front<->back)
    public func switchCameraLocation(){
       camera?.switchCameraLocation()
    }
    
    ///////////////////////////////////
    //MARK: - Callbacks
    ///////////////////////////////////
    
    func filterChanged(){
        log.verbose("filter changed")
        let descriptor = filterManager.getCurrentFilterDescriptor()
        if (currFilter?.key != descriptor?.key){
            log.debug("\(String(describing: currFilter?.key))->\(String(describing: descriptor?.key))")
            currFilter = descriptor
            updateDisplay()
        } else {
            log.debug("Ignoring \(String(describing: currFilter?.key))->\(String(describing: descriptor?.key)) change")
        }
    }
    
}


///////////////////////////////////
//MARK: - Extensions
///////////////////////////////////



extension CameraDisplayView: CameraCaptureHelperDelegate {
    func photoTaken() {
        log.debug("Photo taken")
        // any need to do something...?
    }
    
    func newCameraImage(_ cameraCaptureHelper: CameraCaptureHelper, image: CIImage){
        //DispatchQueue.main.async(execute: { () -> Void in
        self.cameraImage = image
        self.updateDisplay()
        //})
    }
}
