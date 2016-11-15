//
//  CameraDisplayView.swift
//  FilterCam
//
//  Created by Philip Price on 9/16/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import GPUImage
import AVFoundation


// Class responsible for laying out the Camera Display View (i.e. what is currently viewed throughthe camera)
class CameraDisplayView: UIView {
    
    var renderView: RenderView? = RenderView()
    var initDone: Bool = false
    //var currFilter: BasicOperation? = nil
    var filterManager = FilterManager.sharedInstance
    var currFilter: FilterDescriptorInterface? = nil
    var camera: Camera? = nil
    var cropFilter: Crop? = nil
    var opacityFilter:OpacityAdjustment? = nil
    var rotateDescriptor: RotateDescriptor? = nil
    var rotateFilter: BasicOperation? = nil
    var blendImage:PictureInput? = nil
    //let blendImageName = "bl_topaz_warm.png"
    
    ///////////////////////////////////
    // MARK: - Setup/teardown
    ///////////////////////////////////
    convenience init(){
        self.init(frame: CGRect.zero)
    }
    
    
    func initViews(){
        
        if (!initDone){
            self.backgroundColor = UIColor.black
            //self.backgroundColor = UIColor.red
            
            renderView?.frame = self.frame
            self.addSubview(renderView!)
            
            renderView?.fillSuperview()
            
            
            // register for change notifications (don't do this before the views are set up)
            filterManager.setFilterChangeNotification(callback: self.filterChanged())
            initDone = true
        }
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if (!initDone){
            initViews()
        }
        
        setupFilterPipeline()

    }
    
    deinit {
        suspend()
    }
    

    ///////////////////////////////////
    // MARK: pipeline setup
    ///////////////////////////////////
    
    // Sets up the filter pipeline. Call when filter, orientation or camera changes
    func setupFilterPipeline(){
        guard (renderView != nil) else {
            log.error("ERR: RenderView not set up")
            return
        }
        
        guard (initDone) else {
            log.error("ERR: not ready for pipeline setup")
            return
        }
        
        if (cropFilter == nil){ // first time through?
            cropFilter = Crop()
            let res = CameraManager.getCaptureResolution()
            cropFilter!.cropSizeInPixels = Size(width: Float(res.width), height: Float(res.height))
            //cropFilter!.locationOfCropInPixels = Position(0,0)
            log.debug("Crop(w:\(res.width), h:\(res.height))")
        }
        
        // reduce opacity of blends by default
        if (opacityFilter == nil){
            opacityFilter = OpacityAdjustment()
            opacityFilter?.opacity = 0.8
        }
        
        /***
         if (rotateFilter == nil){
         // generate a zero rotation transform, just for correcting camera inversions
         rotateDescriptor = RotateDescriptor()
         rotateDescriptor?.setParameter(1, value: 0.0) // zero rotation
         rotateFilter = rotateDescriptor?.filter
         }
         ***/
        camera = CameraManager.getCamera()
        if (camera != nil){
            //log.debug("Resetting filter pipeline")
            camera?.stopCapture()
            camera?.removeAllTargets()
            currFilter?.filter?.removeAllTargets()
            blendImage?.removeAllTargets()
            
            //TODO: figure out how to remove just the previous filter, not all of them because it stops other render views
            
            /** fixed with pull request #70 from morizotter, custom change to Camera.swift
             // GPUImage bug: front facing camera image is flipped
             // Use a zero rotation filter to flip the image
             
             if (camera?.location == PhysicalCameraLocation.frontFacing){
             //log.verbose("Flipping image")
             rotateFilter!.overriddenOutputRotation = Rotation.flipVertically
             } else {
             rotateFilter!.overriddenOutputRotation = Rotation.noRotation
             }
             **/
            
            //TODO: apply aspect ratio to crop filter
            
            // Redirect the camera output through the selected filter (if any)
            //TOFIX: crop filter seems to only work if it's last in the chain before rendering
            
            //currFilter = filterManager.getCurrentFilter()
            
            if (currFilter == nil){
                log.debug("No filter applied, using camera feed")
                //camera! --> rotateFilter! --> cropFilter! --> renderView!
                camera! --> cropFilter! --> renderView!
            } else {
                if (currFilter?.filter != nil){
                    let filter = currFilter?.filter
                    let opType = currFilter?.filterOperationType // wierd Swift unwrapping problem, can't use currFilter?.filterOperationType directly in switch
                    switch (opType!){
                    case .singleInput:
                        log.debug("Using filter: \(currFilter?.key)")
                        //camera! --> filter! --> rotateFilter! --> cropFilter! --> renderView!
                        camera! --> filter! --> cropFilter! --> renderView!
                        break
                    case .blend:
                        log.debug("Using BLEND mode for filter: \(currFilter?.key)")
                        //TOFIX: blend image needs to be resized to fit the render view
                        camera!.addTarget(filter!)
                        //blendImage = PictureInput(imageName:blendImageName)
                        let currBlendImage  = ImageManager.getCurrentBlendImage(size:(renderView?.frame.size)!)
                        blendImage = PictureInput(image:currBlendImage!)
                        blendImage! --> opacityFilter! --> filter!
                        camera! --> filter! --> cropFilter! --> renderView!
                        //camera! --> filter! --> rotateFilter! --> cropFilter! --> renderView!
                        blendImage?.processImage()
                        break
                    }
                    
                } else if (currFilter?.filterGroup != nil){
                    /***
                    log.debug("Using group: \(currFilter?.key)")
                    let group = currFilter?.filterGroup
                    //camera! -->  group! --> rotateFilter! --> cropFilter! --> renderView!
                    camera! -->  group! --> cropFilter! --> renderView!
                    ***/

                    //log.debug("filterGroup: \(currFilter?.key)")
                    let filterGroup = currFilter?.filterGroup
                    log.debug("Run filterGroup: \(currFilter?.key) address:\(Utilities.addressOf(filterGroup))")
                    
                    let opType:FilterOperationType = (currFilter?.filterOperationType)!
                    switch (opType){
                    case .singleInput:
                        log.debug("filterGroup: \(currFilter?.key)")
                        camera! --> filterGroup! --> renderView!
                        break
                    case .blend:
                        //log.debug("Using BLEND mode for group: \(currFilterDescriptor?.key)")
                        //TOFIX: blend image needs to be resized to fit the render view
                        camera!.addTarget(filterGroup!)
                        let currBlendImage  = ImageManager.getCurrentBlendImage(size:(renderView?.frame.size)!)
                        blendImage = PictureInput(image:currBlendImage!)
                        blendImage! --> opacityFilter! --> filterGroup!
                        camera! --> filterGroup! --> cropFilter! --> renderView!
                        blendImage?.processImage()
                        break
                    }
                } else {
                    log.error("!!! Filter (\(currFilter?.title) has no operation assigned !!!")
                }

            }
            // (Re-)start the camera capture
            log.debug("Restarting camera feed")
            camera?.startCapture()
        } else {
            log.warning("No camera active, ignoring")
        }
        
    }
    
    
    
    // Suspend all GPUImage-related operations
    open func suspend(){
        camera?.stopCapture()
        currFilter?.filter?.removeAllTargets()
        currFilter?.filterGroup?.removeAllTargets()
        blendImage?.removeAllTargets()
        opacityFilter?.removeAllTargets()
        cropFilter?.removeAllTargets()
        
        currFilter = nil
    }
    
    ///////////////////////////////////
    // MARK: - Utilities
    ///////////////////////////////////

    // sets the filter to be applied (nil for no filter)
    open func setFilter(_ descriptor: FilterDescriptorInterface?){
        if (currFilter?.key != descriptor?.key){
            log.debug("\(currFilter?.key)->\(descriptor?.key)")
            removeTargets(currFilter)
            currFilter = descriptor
            setupFilterPipeline()
        } //else {
        //    log.debug("Ignoring \(currFilter?.key)->\(descriptor?.key) change")
        //}
    }
    
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
    
    // saves the currently displayed image to the Camera Roll
    open func saveImage(_ url: URL){
        log.debug("Saving image to URL: \(url.path)")
        
        /***
         // if no assigned filter, then use the Crop filter that was inserted, otherwise use the filter/filterGroup
         if (currFilter == nil){
         cropFilter?.saveNextFrameToURL(url, format:.png)
         } else {
         if (currFilter?.filter != nil){
         currFilter?.filter?.saveNextFrameToURL(url, format:.png)
         } else if (currFilter?.filterGroup != nil){
         currFilter?.filterGroup?.saveNextFrameToURL(url, format:.png)
         } else {
         log.error("!!! Filter (\(currFilter?.title) has no operation assigned !!!")
         }
         }
         ***/
        
        // use cropFilter to save image because it is (currently) always last in the chain
        cropFilter?.saveNextFrameToURL(url, format:.png)
        saveToPhotoAlbum(url) // saves asynchronously
        
    }
    
    // Saves the photo file at the supplied URL to the Camera Roll (asynchronously). Doesn't always work if synchronous
    func saveToPhotoAlbum(_ url:URL){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let image = UIImage(contentsOfFile: url.path)
            UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
        }
    }

    
    
    ///////////////////////////////////
    //MARK: - Callbacks
    ///////////////////////////////////
    
    func filterChanged(){
        log.verbose("filter changed")
        let descriptor = filterManager.getCurrentFilterDescriptor()
        if (currFilter?.key != descriptor?.key){
            log.debug("\(currFilter?.key)->\(descriptor?.key)")
            removeTargets(currFilter)
            currFilter = descriptor
            setupFilterPipeline()
        } else {
            log.debug("Ignoring \(currFilter?.key)->\(descriptor?.key) change")
        }
    }
 
    
}
