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
            //renderView.anchorToEdge(.top, padding: 0, width: self.frame.width, height: self.frame.height)
            //renderView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: self.frame.height)
            //renderView.anchorInCenter(self.frame.width, height: self.frame.height)
            
            
            initDone = true
        }
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if (!initDone){
            initViews()
        }
        
        camera = CameraManager.getCamera()
        setupFilterPipeline()

    }
    
    deinit {
        camera?.stopCapture()
    }
    
    
    func setupFilterPipeline(){
        // Redirect the camera output through the selected filter (if any)
        
        do {
            if (renderView != nil){
                if (camera != nil){
                    camera?.stopCapture()
                    camera?.removeAllTargets()
                    log.debug("Resetting pipeline")
                    
                    if (currFilter == nil){
                        camera! --> renderView!
                    } else {
                        camera! --> currFilter! --> renderView!
                    }
                    camera?.startCapture()
                }
            }
        } catch {
            log.error("Could not initialize rendering pipeline: \(error)")
        }
    }
    
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
            saveToPhotoAlbum(url) // save asynchronously
            
            
        } catch {
            log.error("Could not save image: \(error)")
        }
    }
 
    // Saves the photo file at the supplied URL to the Camera Roll (asynchronously). Doesn't always work if synchronous
    func saveToPhotoAlbum(_ url:URL){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let image = UIImage(contentsOfFile: url.path)
            UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
        }
    }

    
    
    //MARK: - Handlers for actions on sub-views
    
    
    
}
