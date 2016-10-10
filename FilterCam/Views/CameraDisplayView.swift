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
    var currFilter: BasicOperation? = nil
    var camera: Camera? = nil
    var cropFilter: Crop? = nil
    
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
            
            if (cropFilter == nil){ // first time through?
                cropFilter = Crop()
                let res = CameraManager.getCaptureResolution()
                cropFilter!.cropSizeInPixels = Size(width: Float(res.width), height: Float(res.height))
                cropFilter!.locationOfCropInPixels = Position(0,0)
                log.debug("Crop(w:\(res.width), h:\(res.height))")
            }
            
            camera = CameraManager.getCamera()
            if (camera != nil){
                log.debug("Resetting filter pipeline")
                camera?.stopCapture()
                camera?.removeAllTargets()
                
                // GPUImage bug: front facing camera image is flipped
                // Use crop filter to flip the image, since this is always applied, even to the straight camera feed
                if (camera?.location == PhysicalCameraLocation.frontFacing){
                    log.verbose("Flipping image")
                    cropFilter!.overriddenOutputRotation = Rotation.flipVertically // doesn't seem to work
                    //TEMP HACK: flip filter, if active (remove when Crop is fixed)
                    if (currFilter != nil){
                        currFilter!.overriddenOutputRotation = Rotation.flipVertically
                    }
                    
                } else {
                    cropFilter!.overriddenOutputRotation = Rotation.noRotation
                }
                
                // Redirect the camera output through the selected filter (if any)
                //TOFIX: crop filter seems to only work if it's last in the chain before rendering
                if (currFilter == nil){
                    camera! --> cropFilter! --> renderView!
                } else {
                    camera! --> currFilter! --> cropFilter! --> renderView!
                }
                // (Re-)start the camera capture
                camera?.startCapture()
            }
            
        } catch {
            log.error("Could not initialize rendering pipeline: \(error)")
        }
    }
    
    // sets the filter to be applied (nil for no filter)
    open func setFilter(_ filter: BasicOperation?){
        currFilter?.removeAllTargets()
        currFilter = filter
        setupFilterPipeline()
    }
    
    
    // saves the currently displayed image to the Camera Roll
    open func saveImage(_ url: URL){
        do{
            log.debug("Saving image to URL: \(url.path)")
            try currFilter?.saveNextFrameToURL(url, format:.png)
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
