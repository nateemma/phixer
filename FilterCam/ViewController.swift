//
//  swift
//  Philter
//
//  Created by Philip Price on 9/6/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import GPUImage
import Neon

class ViewController: UIViewController {
    
    // Camera Settings
    var cameraSettingsView: CameraSettingsView! = CameraSettingsView()
    
    // Main Camera View
    var cameraDisplayView: CameraDisplayView! = CameraDisplayView()
    
    // View for holding the (modal) overlays. Note: must come after CameraDisplayView()
    var cameraOverlayView : CameraOverlayView! = CameraOverlayView()
    
    // The Camera controls/options
    var cameraControlsView: CameraControlsView! = CameraControlsView()
    
    
    var isLandscape : Bool = false
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    let bannerHeight : CGFloat = 64.0
    let buttonSize : CGFloat = 48.0
    
    
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            
            // get display dimensions
            displayHeight = view.height
            displayWidth = view.width
            
            log.verbose("h:\(displayHeight) w:\(displayWidth)")
            
            // get orientation
            //isLandscape = UIDevice.current.orientation.isLandscape // doesn't always work properly, especially in simulator
            isLandscape = (displayWidth > displayHeight)
            
            
            view.addSubview(cameraSettingsView)
            view.addSubview(cameraDisplayView)
            view.addSubview(cameraOverlayView) // must come after cameraDisplayView
            view.addSubview(cameraControlsView)
            
            // set up layout based on orientation
            if (isLandscape){
                // left-to-right layout scheme
                cameraSettingsView.frame.size.height = displayHeight
                cameraSettingsView.frame.size.width = bannerHeight
                cameraSettingsView.anchorAndFillEdge(.left, xPad: 0, yPad: 0, otherSize: bannerHeight)
                
                cameraControlsView.frame.size.height = displayHeight
                cameraControlsView.frame.size.width = bannerHeight
                cameraControlsView.anchorAndFillEdge(.right, xPad: 0, yPad: 0, otherSize: bannerHeight)
                
                cameraDisplayView.frame.size.height = displayHeight
                cameraDisplayView.frame.size.width = displayWidth - 2 * bannerHeight
                cameraDisplayView.alignBetweenHorizontal(.toTheRightMatchingTop, primaryView: cameraSettingsView, secondaryView: cameraControlsView, padding: 0, height: displayHeight)
                
                // Align Overlay view to bottom of Render View
                cameraOverlayView.frame.size.height = bannerHeight / 2.0
                cameraOverlayView.frame.size.width = displayWidth - 2 * bannerHeight
                //cameraOverlayView.align(.aboveCentered, relativeTo: cameraControlsView, padding: 0, width: displayWidth - 2 * bannerHeight, height: bannerHeight)
                cameraOverlayView.alignBetweenHorizontal(.toTheLeftMatchingBottom, primaryView: cameraControlsView, secondaryView: cameraSettingsView, padding: 0, height: bannerHeight)
                
            } else {
                // Portrait: top-to-bottom layout scheme
                
                cameraSettingsView.frame.size.height = bannerHeight
                cameraSettingsView.frame.size.width = displayWidth
                cameraSettingsView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: bannerHeight)
                
                cameraControlsView.frame.size.height = bannerHeight
                cameraControlsView.frame.size.width = displayWidth
                cameraControlsView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: bannerHeight)
                
                cameraDisplayView.frame.size.height = displayHeight - 2 * bannerHeight
                cameraDisplayView.frame.size.width = displayWidth
                cameraDisplayView.alignBetweenVertical(.underCentered, primaryView: cameraSettingsView, secondaryView: cameraControlsView, padding: 0, width: displayWidth)
                
                // Align Overlay view to bottom of Render View
                cameraOverlayView.frame.size.height = bannerHeight / 2.0
                cameraOverlayView.frame.size.width = displayWidth
                cameraOverlayView.align(.aboveCentered, relativeTo: cameraControlsView, padding: 0, width: displayWidth, height: bannerHeight)
                
            }
            
            cameraDisplayView.setFilter(filter: SketchFilter()) // TEMP
            
            // add delegates to sub-views
            cameraControlsView.delegate = self
            
            //TODO: start timer and update setting display peridodically
        }
        catch  let error as NSError {
            log.error ("Error detected: \(error.localizedDescription)");
        }
    }
    
    
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        //swift 3
        if UIDevice.current.orientation.isLandscape{
            log.verbose("### Detected change to: Landscape")
        } else {
            log.verbose("### Detected change to: Portrait")
            
        }
        //TODO: animate and maybe handle before rotation finishes
        self.viewDidLoad()
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    open func saveImage(){
        do{
            let documentsDir = try FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
            cameraDisplayView.saveImage(url: URL(string:"TestImage.png", relativeTo:documentsDir)!)//TOFIX: generate filename
        } catch {
            log.error("Error saving image: \(error)")
        }
        
    }
    
}
    

// MARK: - Delegate methods for sub-views

extension ViewController: CameraControlsViewDelegate {
    func imagePreviewPressed(){
        log.debug("imagePreview pressed")
    }
    func takePicturePressed(){
        log.debug("Take Picture pressed")
        saveImage()
    }
    func filterSelectionPressed(){
        log.debug("Filter pressed")
    }
    func settingsPressed(){
        log.debug("Settings pressed")
    }
}

