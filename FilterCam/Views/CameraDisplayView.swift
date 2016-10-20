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
    var currFilter: FilterDescriptorInterface? = nil
    var camera: Camera? = nil
    var cropFilter: Crop? = nil
    var rotateDescriptor: RotateDescriptor? = nil
    var rotateFilter: BasicOperation? = nil
    var blendImage:PictureInput? = nil
    let blendImageName = "app_icon.png"
    
    convenience init(){
        self.init(frame: CGRect.zero)
    }
    
    
    func initViews(){
        
        if (!initDone){
            //self.backgroundColor = UIColor.black
            self.backgroundColor = UIColor.red
            
            renderView?.frame = self.frame
            self.addSubview(renderView!)
            
            renderView?.fillSuperview()
            
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
        camera?.stopCapture()
    }
    

    
    // Sets up the filter pipeline. Call when filter, orientation or camera changes
    func setupFilterPipeline(){
        do {
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
            
            if (rotateFilter == nil){
                // generate a zero rotation transform, just for correcting camera inversions
                rotateDescriptor = RotateDescriptor()
                rotateDescriptor?.setParameter(1, value: 0.0) // zero rotation
                rotateFilter = rotateDescriptor?.filter
            }
            
            camera = CameraManager.getCamera()
            if (camera != nil){
                //log.debug("Resetting filter pipeline")
                camera?.stopCapture()
                camera?.removeAllTargets()
                
                //TODO: figure out how to remove just the previous filter, not all of them because it stops other render views
                
                // GPUImage bug: front facing camera image is flipped
                // Use a zero rotation filter to flip the image
                
                if (camera?.location == PhysicalCameraLocation.frontFacing){
                    //log.verbose("Flipping image")
                    rotateFilter!.overriddenOutputRotation = Rotation.flipVertically
                } else {
                    rotateFilter!.overriddenOutputRotation = Rotation.noRotation
                }
                
                //TODO: apply aspect ratio to crop filter
                
                // Redirect the camera output through the selected filter (if any)
                //TOFIX: crop filter seems to only work if it's last in the chain before rendering
                if (currFilter == nil){
                    log.debug("No filter applied, using camera feed")
                    camera! --> rotateFilter! --> cropFilter! --> renderView!
                } else {
                    if (currFilter?.filter != nil){
                        log.debug("Using filter: \(currFilter?.key)")
                        let filter = currFilter?.filter
                        let opType = currFilter?.filterOperationType // wierd Swift unwrapping problem, can't use currFilter?.filterOperationType directly in swicth
                        switch (opType!){
                        case .singleInput:
                            camera! --> filter! --> rotateFilter! --> cropFilter! --> renderView!
                            break
                        case .blend:
                            log.debug("Using BLEND mode for filter: \(currFilter?.key)")
                            camera!.addTarget(filter!)
                            blendImage = PictureInput(imageName:blendImageName)
                            /***
                            blendImage?.addTarget(filter!)
                            blendImage?.processImage()
                            blendImage?.addTarget(renderView!)
                            filter?.addTarget(renderView!)
                             ***/
                            camera! --> filter! --> rotateFilter! --> cropFilter! --> renderView!
                            blendImage! --> filter! --> rotateFilter! --> cropFilter!
                            break
                        }
                            
                    } else if (currFilter?.filterGroup != nil){
                        log.debug("Using group: \(currFilter?.key)")
                        let group = currFilter?.filterGroup
                        camera! -->  group! --> rotateFilter! --> cropFilter! --> renderView!
                    } else {
                        log.error("!!! Filter (\(currFilter?.title) has no operation assigned !!!")
                    }
                }
                // (Re-)start the camera capture
                camera?.startCapture()
            } else {
                log.warning("No camera active, ignoring")
            }
            
        } catch {
            log.error("Could not initialize rendering pipeline: \(error)")
        }
    }
    
    // sets the filter to be applied (nil for no filter)
    open func setFilter(_ descriptor: FilterDescriptorInterface?){
        removeTargets(currFilter)
        currFilter = descriptor
        setupFilterPipeline()
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
        do{
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
       
        } catch {
            log.error("Could not save image: \(error)")
        }
    }
 
    // Saves the photo file at the supplied URL to the Camera Roll (asynchronously). Doesn't always work if synchronous
    func saveToPhotoAlbum(_ url:URL){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let image = UIImage(contentsOfFile: url.path)
            UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
        }
    }

    
    
    //MARK: - Handlers for actions on sub-views
    
    
    
}
