//
//  FilterCamViewController.swift
//  FilterCam
//
//  Created by Philip Price on 9/6/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import GPUImage
import Neon
import AVFoundation
import MediaPlayer

class FilterCamViewController: UIViewController, SegueHandlerType {
    
    // Camera Settings
    var cameraSettingsView: CameraSettingsView! = CameraSettingsView()
    
    // Main Camera View
    var cameraDisplayView: CameraDisplayView! = CameraDisplayView()
    
    // View for holding the (modal) overlays. Note: must come after CameraDisplayView()
    var cameraInfoView : CameraInfoView! = CameraInfoView()
    
    // The Camera controls/options
    var cameraControlsView: CameraControlsView! = CameraControlsView()
    
    
    var isLandscape : Bool = false
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    let bannerHeight : CGFloat = 64.0
    let buttonSize : CGFloat = 48.0
    
    
    // the list of segues initiated from this view controller
    enum SegueIdentifier: String {
        case photoBrowser
        case filterManager
        case attributions
        case about
        case preferences
    }
    
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
            
            
            // Note: need to add subviews before modifying constraints
            view.addSubview(cameraSettingsView)
            view.addSubview(cameraDisplayView)
            view.addSubview(cameraInfoView) // must come after cameraDisplayView
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
                cameraDisplayView.alignBetweenHorizontal(.toTheLeftMatchingTop, primaryView: cameraSettingsView, secondaryView: cameraControlsView, padding: 0, height: displayHeight)
                
                
                // Align Overlay view to bottom of Render View
                cameraInfoView.frame.size.height = bannerHeight / 2.0
                cameraInfoView.frame.size.width = displayWidth - 2 * bannerHeight
                //cameraInfoView.align(.aboveCentered, relativeTo: cameraControlsView, padding: 0, width: displayWidth - 2 * bannerHeight, height: bannerHeight)
                cameraInfoView.alignBetweenHorizontal(.toTheLeftMatchingBottom, primaryView: cameraControlsView, secondaryView: cameraSettingsView, padding: 0, height: bannerHeight)
                
            } else {
                // Portrait: top-to-bottom layout scheme
                
                cameraSettingsView.frame.size.height = bannerHeight
                cameraSettingsView.frame.size.width = displayWidth
                cameraSettingsView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: bannerHeight)
                
                cameraControlsView.frame.size.height = bannerHeight
                cameraControlsView.frame.size.width = displayWidth
                cameraControlsView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: bannerHeight)
                
                cameraInfoView.frame.size.height = bannerHeight / 2.0
                cameraInfoView.frame.size.width = displayWidth
                cameraInfoView.align(.aboveCentered, relativeTo: cameraControlsView, padding: 0, width: displayWidth, height: cameraInfoView.frame.size.height)
                
                
                //cameraDisplayView.frame.size.height = displayHeight - 2 * bannerHeight
                cameraDisplayView.frame.size.height = displayHeight - 2.5 * bannerHeight
                cameraDisplayView.frame.size.width = displayWidth
                cameraDisplayView.align(.aboveCentered, relativeTo: cameraInfoView, padding: 0, width: displayWidth, height: cameraDisplayView.frame.size.height)
            }
            
            setFilterIndex(0) // no filter
            
            // add delegates to sub-views
            cameraControlsView.delegate = self
            cameraInfoView.delegate = self
            
            // listen to key press events
            setVolumeListener()
            
            //TODO: start timer and update setting display peridodically
        }
        catch  let error as NSError {
            log.error ("Error detected: \(error.localizedDescription)");
        }
    }
/*
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.current.orientation.isLandscape {
            log.verbose("Preparing for transition to Landscape")
        } else {
            log.verbose("Preparing for transition to Portrait")
        }
    }
*/
    
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let id = segueIdentifierForSegue(segue)
        log.debug ("Issuing segue: \(id)") // don't really need to do anything, just log which segue was activated
    }
    
    
    
    // handle the pressing of a physical button
    
    
    func setVolumeListener() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
        } catch {
            log.error("\(error)")
        }
        audioSession.addObserver(self, forKeyPath: "outputVolume", options: NSKeyValueObservingOptions(), context: nil)
        //TODO: hide system volume HUD
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        log.debug("Key event: \(keyPath)")
        if keyPath == "outputVolume" {
            log.debug("Volume Button press detected, taking picture")
            saveImage()
        }
    }
    
    
    //MARK: - Utility functions
    
    open func saveImage(){
        do{
            let documentsDir = try FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
            //TOFIX: generate filename? Or, just overwrite same file since it's copied to Photos anyway?
            cameraDisplayView.saveImage(URL(string:"FilterCamImage.png", relativeTo:documentsDir)!)
            
        } catch {
            log.error("Error saving image: \(error)")
        }
        
    }
    
    // TEMP: set Filter based on index
    open func setFilterIndex(_ index:Int){
        switch (index){
        case 0:
            cameraDisplayView.setFilter(nil)
            log.verbose("No filter")
            cameraInfoView.setFilterName("(None)")
            break
        case 0:
            cameraDisplayView.setFilter(SketchFilter())
            log.verbose("Filter: Sketch")
            cameraInfoView.setFilterName("Sketch")
            break
        case 1:
            cameraDisplayView.setFilter(Crosshatch())
            log.verbose("Filter: Crosshatch")
            cameraInfoView.setFilterName("Crosshatch")
            break
        case 2:
            cameraDisplayView.setFilter(Posterize())
            log.verbose("Filter: Posterize")
            cameraInfoView.setFilterName("Posterize")
            break
        case 3:
            cameraDisplayView.setFilter(Halftone())
            log.verbose("Filter: Halftone")
            cameraInfoView.setFilterName("Halftone")
            break
        case 4:
            cameraDisplayView.setFilter(AmatorkaFilter())
            log.verbose("Filter: Amatorka")
            cameraInfoView.setFilterName("Amatorka")
            break
        case 5:
            cameraDisplayView.setFilter(MissEtikateFilter())
            log.verbose("Filter: MissEtikate")
            cameraInfoView.setFilterName("MissEtikate")
            break
        case 6:
            cameraDisplayView.setFilter(MonochromeFilter())
            log.verbose("Filter: Monochrome")
            cameraInfoView.setFilterName("Monochrome")
            break
        case 7:
            cameraDisplayView.setFilter(SepiaToneFilter())
            log.verbose("Filter: SepiaTone")
            cameraInfoView.setFilterName("SepiaTone")
           break
        case 8:
            cameraDisplayView.setFilter(Pixellate())
            log.verbose("Filter: Pixellate")
            cameraInfoView.setFilterName("Pixellate")
            break
        case 9:
            cameraDisplayView.setFilter(PolarPixellate())
            log.verbose("Filter: PolarPixellate")
            cameraInfoView.setFilterName("PolarPixellate")
            break
        case 10:
            cameraDisplayView.setFilter(PolkaDot())
            log.verbose("Filter: PolkaDot")
            cameraInfoView.setFilterName("PolkaDot")
            break
        case 11:
            cameraDisplayView.setFilter(ThresholdSketchFilter())
            log.verbose("Filter: ThresholdSketch")
            cameraInfoView.setFilterName("ThresholdSketch")
            break
        case 12:
            cameraDisplayView.setFilter(ToonFilter())
            log.verbose("Filter: ToonFilter")
            cameraInfoView.setFilterName("ToonFilter")
            break
        case 13:
            cameraDisplayView.setFilter(GlassSphereRefraction())
            log.verbose("Filter: GlassSphereRefraction")
            cameraInfoView.setFilterName("GlassSphereRefraction")
            break
        default:
            cameraDisplayView.setFilter(nil)
            log.verbose("Unknown index. No filter")
            log.verbose("(None)")
            break
        }
    }
    
}


// MARK: - Delegate methods for sub-views

extension FilterCamViewController: CameraControlsViewDelegate {
    func imagePreviewPressed(){
        log.debug("imagePreview pressed")
    }
    func takePicturePressed(){
        log.debug("Take Picture pressed")
        saveImage()
        cameraControlsView.update()
    }
    func filterSelectionPressed(){
        log.debug("Filter Mgr pressed")
    }
    func settingsPressed(){
        log.debug("Settings pressed")
    }
}


var filterIndex:Int = 0

extension FilterCamViewController: CameraInfoViewDelegate {
    func filterPressed(){
        let numFilters = 14
        //log.debug("Curr Filter pressed")
        
        //TEMP: cycle through filters when button is pressed
        filterIndex = (filterIndex+1)%numFilters
        self.setFilterIndex(filterIndex)
        
    }
}


