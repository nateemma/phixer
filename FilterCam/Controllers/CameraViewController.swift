//
//  CameraViewController.swift
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
import AudioToolbox

import GoogleMobileAds



private var filterList: [String] = []
private var filterCount: Int = 0


// This is the View Controller for displaying the camera functionality (without filters) and provides access to various camera controls and settings
class CameraViewController: UIViewController {
    
    // Camera Settings
    var cameraSettingsView: CameraSettingsView! = CameraSettingsView()
    
    // Main Camera View
    var cameraDisplayView: CameraDisplayView! = CameraDisplayView()
    
    // Views for holding the (modal) overlays. Note: must come after CameraDisplayView()
    var cameraInfoView : CameraInfoView! = CameraInfoView()
    
    // the current display mode for the information view
    var currInfoMode:InfoMode = .camera
    
    
    // The Camera controls/options
    var cameraControlsView: CameraControlsView! = CameraControlsView()
    
    
    // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    
    
    
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
        
        // get display dimensions
        displayHeight = view.height
        displayWidth = view.width
        
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        // get orientation
        //isLandscape = UIDevice.current.orientation.isLandscape // doesn't always work properly, especially in simulator
        isLandscape = (displayWidth > displayHeight)
        
        
        // Note: need to add subviews before modifying constraints
        view.addSubview(cameraSettingsView)
        view.addSubview(adView)
        view.addSubview(cameraDisplayView)
        view.addSubview(cameraInfoView) // must come after cameraDisplayView
        view.addSubview(cameraControlsView)
        
        // set up layout based on orientation
        if (isLandscape){
            // left-to-right layout scheme
            cameraSettingsView.frame.size.height = displayHeight
            cameraSettingsView.frame.size.width = bannerHeight
            cameraSettingsView.anchorAndFillEdge(.left, xPad: 0, yPad: 0, otherSize: bannerHeight)
            
            
            adView.frame.size.height = bannerHeight
            adView.frame.size.width = displayWidth - 2 * bannerHeight
            adView.align(.underCentered, relativeTo: cameraSettingsView, padding: 0,
                         width: displayWidth, height: adView.frame.size.height)
            
            cameraControlsView.frame.size.height = displayHeight
            cameraControlsView.frame.size.width = bannerHeight
            cameraControlsView.anchorAndFillEdge(.right, xPad: 0, yPad: 0, otherSize: bannerHeight)
            
            cameraDisplayView.frame.size.height = displayHeight
            cameraDisplayView.frame.size.width = displayWidth - 2 * bannerHeight
            cameraDisplayView.alignBetweenHorizontal(.toTheLeftMatchingTop, primaryView: cameraSettingsView, secondaryView: cameraControlsView, padding: 0, height: displayHeight)
            
            
            // Align Overlay view to bottom of Render View
            cameraInfoView.frame.size.height = bannerHeight / 1.5
            cameraInfoView.frame.size.width = displayWidth - 2 * bannerHeight
            //cameraInfoView.align(.aboveCentered, relativeTo: cameraControlsView, padding: 0, width: displayWidth - 2 * bannerHeight, height: bannerHeight)
            cameraInfoView.alignBetweenHorizontal(.toTheLeftMatchingBottom, primaryView: cameraControlsView, secondaryView: cameraSettingsView, padding: 0, height: bannerHeight)
        } else {
            // Portrait: top-to-bottom layout scheme
            
            cameraSettingsView.frame.size.height = bannerHeight
            cameraSettingsView.frame.size.width = displayWidth
            cameraSettingsView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: bannerHeight)
            
            adView.frame.size.height = bannerHeight
            adView.frame.size.width = displayWidth
            adView.align(.underCentered, relativeTo: cameraSettingsView, padding: 0,
                         width: displayWidth, height: adView.frame.size.height)
            
            cameraControlsView.frame.size.height = bannerHeight
            cameraControlsView.frame.size.width = displayWidth
            cameraControlsView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: bannerHeight)
            
            cameraInfoView.frame.size.height = bannerHeight / 1.5
            cameraInfoView.frame.size.width = displayWidth
            cameraInfoView.align(.aboveCentered, relativeTo: cameraControlsView, padding: 0,
                                 width: displayWidth, height: cameraInfoView.frame.size.height)
            
            
            cameraDisplayView.frame.size.height = displayHeight - 3.0 * bannerHeight
            //cameraDisplayView.frame.size.height = displayHeight - 5.5 * bannerHeight
            cameraDisplayView.frame.size.width = displayWidth
            cameraDisplayView.align(.underCentered, relativeTo: adView, padding: 0,
                                    width: displayWidth, height: cameraDisplayView.frame.size.height)
            
        }
        
        //setFilterIndex(0) // no filter
        
        // add delegates to sub-views (for callbacks)
        cameraSettingsView.delegate = self
        cameraControlsView.delegate = self
        //cameraInfoView.delegate = self
        
        // set gesture detction for Filter Settings view
        //setGestureDetectors(view: filterSettingsView)
        
        
        // listen to key press events
        setVolumeListener()
        
        setInfoMode(currInfoMode) // must be after view setup
        
        
        // start Ads
        setupAds()
        
        //TODO: start timer and update setting display peridodically
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
    
    
    
    
    // MARK: - Volume buttons
    
    
    func setVolumeListener() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
        } catch {
            log.error("\(error)")
        }
        audioSession.addObserver(self, forKeyPath: "outputVolume", options: NSKeyValueObservingOptions(), context: nil)
        
        //TODO: hide system volume HUD
        self.view.addSubview(volumeView)
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        log.debug("Key event: \(String(describing: keyPath))")
        if keyPath == "outputVolume" {
            log.debug("Volume Button press detected, taking picture")
            saveImage()
        }
    }
    
    // redefine the volume view so that it isn't really visible to the user
    lazy var volumeView: MPVolumeView = {
        let view = MPVolumeView()
        view.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        view.alpha = 0.000001
        return view
    }()
    
    // MARK: - Ad Framework
    
    fileprivate func setupAds(){
        log.debug("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        adView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        adView.rootViewController = self
        adView.load(GADRequest())
        adView.backgroundColor = UIColor.black
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
    
    fileprivate func playCameraSound(){
        AudioServicesPlaySystemSound(1108) // undocumented iOS feature!
    }
    
    
    //MARK: - Info Mode Management
    
    fileprivate func setInfoMode(_ mode:InfoMode){
        currInfoMode = mode
        
        switch (currInfoMode){
        case .camera:
            
            break
        case .filter:
            
            break
        }
        
        cameraControlsView.setInfoMode(currInfoMode)
    }
    
    
    fileprivate func swapInfoMode(){
        switch (currInfoMode){
        case .camera:
            setInfoMode(.filter)
            break
        case .filter:
            setInfoMode(.camera)
            break
        }
    }
    
    
    
    
}


// MARK: - Delegate methods for sub-views

extension CameraViewController: CameraControlsViewDelegate {
    func imagePreviewPressed(){
        log.debug("imagePreview pressed")
    }
    func takePicturePressed(){
        log.debug("Take Picture pressed")
        saveImage()
        playCameraSound()
        cameraControlsView.update()
    }
    func modePressed(){
        log.debug("Filter Mgr pressed")
        swapInfoMode()
    }
    func settingsPressed(){
        log.debug("Settings pressed")
    }
}

extension CameraViewController: CameraSettingsViewDelegate {
    func flashPressed(){
        log.debug("Flash pressed")
        //TODO: handle Flash options
    }
    
    func gridPressed(){
        log.debug("Grid pressed")
        //TODO: handle Grid options
    }
    
    func aspectPressed(){
        log.debug("Aspect Ratio pressed")
        //TODO: handle Aspect Ratio options
    }
    
    func cameraPressed(){
        log.debug("Camera Options pressed")
        //TODO: handle Camera Exposure options
    }
    
    func timerPressed(){
        log.debug("Timer pressed")
        //TODO: handle Timer options
    }
    
    
    func switchPressed(){
        //log.debug("Switch Cameras pressed")
        CameraManager.switchCameraLocation()
    }
}





