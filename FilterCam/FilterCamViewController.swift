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
import AudioToolbox

import GoogleMobileAds



private var filterList: [String] = []
private var filterCount: Int = 0


class FilterCamViewController: UIViewController, SegueHandlerType {
    
    // Camera Settings
    var cameraSettingsView: CameraSettingsView! = CameraSettingsView()
    
    // Main Camera View
    var cameraDisplayView: CameraDisplayView! = CameraDisplayView()
    
    // Views for holding the (modal) overlays. Note: must come after CameraDisplayView()
    var cameraInfoView : CameraInfoView! = CameraInfoView()
    var filterInfoView : FilterInfoView! = FilterInfoView()
    
    // the current display mode for the information view
    var currInfoMode:InfoMode = .camera
    
    
    // The Camera controls/options
    var cameraControlsView: CameraControlsView! = CameraControlsView()

    // The filter configuration subview
    var filterSettingsView: FilterSettingsView! = FilterSettingsView()
    
    // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    
    // Filter strip
    var filterStrip: FilterCarouselView! = FilterCarouselView()
    

    
    var filterManager: FilterManager? = FilterManager.sharedInstance
    
    var currFilterDescriptor:FilterDescriptorInterface? = nil
 
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
        
        filterManager = FilterManager.sharedInstance

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
            view.addSubview(adView)
            view.addSubview(cameraDisplayView)
            view.addSubview(cameraInfoView) // must come after cameraDisplayView
            view.addSubview(filterInfoView) // must come after cameraDisplayView
            view.addSubview(cameraControlsView)
            
            view.addSubview(filterStrip)
            
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
                
                filterInfoView.frame.size = cameraInfoView.frame.size
                filterInfoView.alignBetweenHorizontal(.toTheLeftMatchingBottom, primaryView: cameraControlsView, secondaryView: cameraSettingsView, padding: 0, height: bannerHeight)
                
                filterStrip.frame.size.height = 2.0 * bannerHeight
                filterStrip.frame.size = cameraInfoView.frame.size
                filterStrip.alignBetweenHorizontal(.toTheLeftMatchingBottom, primaryView: cameraControlsView, secondaryView: cameraSettingsView,
                                                        padding: 0, height: filterStrip.frame.size.height)
                
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
                
                
                filterInfoView.frame.size = cameraInfoView.frame.size
                filterInfoView.align(.aboveCentered, relativeTo: cameraControlsView, padding: 0,
                                     width: displayWidth, height: cameraInfoView.frame.size.height)
              
                cameraDisplayView.frame.size.height = displayHeight - 3.0 * bannerHeight
                //cameraDisplayView.frame.size.height = displayHeight - 5.5 * bannerHeight
                cameraDisplayView.frame.size.width = displayWidth
                cameraDisplayView.align(.underCentered, relativeTo: adView, padding: 0,
                                        width: displayWidth, height: cameraDisplayView.frame.size.height)
                
                filterStrip.frame.size.height = 1.5 * bannerHeight
                filterStrip.frame.size.width = displayWidth
                filterStrip.align(.aboveCentered, relativeTo: filterInfoView, padding: 0,
                                     width: filterStrip.frame.size.width, height: filterStrip.frame.size.height)
            }
            
            //setFilterIndex(0) // no filter
            
            // add delegates to sub-views (for callbacks)
            cameraSettingsView.delegate = self
            cameraControlsView.delegate = self
            //cameraInfoView.delegate = self
            filterInfoView.delegate = self
            //filterSettingsView.delegate = self
            filterStrip.delegate = self
            
            // set gesture detction for Filter Settings view
            //setGestureDetectors(view: filterSettingsView)

            
            // listen to key press events
            setVolumeListener()
            
            setInfoMode(currInfoMode) // must be after view setup
            
            //TODO: select filter category somehow
            filterStrip.setFilterCategory(FilterCategoryType.quickSelect)
            filterStrip.isHidden = true
     

            
            // start Ads
            setupAds()
           
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
        if UIDevice.current.orientation.isLandscape{
            log.verbose("### Detected change to: Landscape")
        } else {
            log.verbose("### Detected change to: Portrait")
            
        }
        //TODO: animate and maybe handle before rotation finishes
        self.viewDidLoad()
        cameraDisplayView.setFilter(currFilterDescriptor) // forces reset of filter pipeline
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let id = segueIdentifierForSegue(segue)
        log.debug ("Issuing segue: \(id)") // don't really need to do anything, just log which segue was activated
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
        log.debug("Key event: \(keyPath)")
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
    
    // MARK: - Gesture Detection
    
    
    func setGestureDetectors(_ view: UIView){
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.swiped))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.swiped))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.swiped))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.swiped))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
    }
    
    
    func swiped(_ gesture: UIGestureRecognizer)
    {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer
        {
            switch swipeGesture.direction
            {
                
            case UISwipeGestureRecognizerDirection.right:
                //log.verbose("Swiped Right")
                previousFilter()
                break
                
            case UISwipeGestureRecognizerDirection.left:
                //log.verbose("Swiped Left")
                nextFilter()
                break
                
            case UISwipeGestureRecognizerDirection.up:
                //log.verbose("Swiped Up")
                break
                
            case UISwipeGestureRecognizerDirection.down:
                filterSettingsView.dismiss()
                //log.verbose("Swiped Down")
                break
                
            default:
                log.debug("Unhandled gesture direction: \(swipeGesture.direction)")
                break
            }
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

    fileprivate func playCameraSound(){
        AudioServicesPlaySystemSound(1108) // undocumented iOS feature!
    }

    fileprivate func populateFilterList(){
        
        // make sure the FilterManager instance has been loaded
        if (filterManager == nil) {
            log.warning("WARN: FilterManager not allocated. Lazy allocation")
            filterManager = FilterManager.sharedInstance
        }
        
        // get list of filters in the Quick Selection category
        if (filterCount==0){
            filterList = []
            filterList = (filterManager?.getFilterList(FilterCategoryType.quickSelect))!
            filterList.sort(by: { (value1: String, value2: String) -> Bool in return value1 < value2 }) // sort ascending
            filterCount = filterList.count
            log.debug("Filter list: \(filterList)")
            
        }
    }
    
    //MARK: - Info Mode Management
    
    fileprivate func setInfoMode(_ mode:InfoMode){
        currInfoMode = mode
        
        switch (currInfoMode){
        case .camera:
            cameraInfoView.isHidden = false
            filterInfoView.isHidden = true
            filterStrip.isHidden = true
            hideFilterSettings()
            cameraDisplayView.setFilter(nil)
            break
        case .filter:
            cameraDisplayView.setFilter(currFilterDescriptor)
            filterStrip.update()
            
            if let name = currFilterDescriptor?.key {
                log.verbose("Filter: \(name)")
                filterInfoView.setFilterName(name)
                updateFilterSettings()
            } else {
                filterInfoView.setFilterName("No Filter")
            }
            cameraInfoView.isHidden = true
            filterInfoView.isHidden = false
            filterStrip.isHidden = false
            view.bringSubview(toFront: filterStrip)
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
    
    
    // MARK: - Filter Management
    // TEMP: set Filter based on index
    
    var filterIdx:Int = 0
    
    open func setFilterIndex(_ index:Int){
        
        // make sure the FilterManager instance has been loaded
        if (filterManager == nil) {
            log.warning("WARN: FilterManager not allocated. Lazy allocation")
            filterManager = FilterManager.sharedInstance
        }
        
        if (filterCount==0){ populateFilterList() }

        
        // setup the filter descriptor
        if ((index>=0) && (index<filterCount)){
            currFilterDescriptor = filterManager?.getFilterDescriptor(.quickSelect, name:filterList[index])
        } else {
            currFilterDescriptor = nil
            log.error("!!! Unknown index:\(index) No filter")
        }
        
        cameraDisplayView.setFilter(currFilterDescriptor)
        
        if let name = currFilterDescriptor?.key {
            log.verbose("Filter: \(name)")
            filterInfoView.setFilterName(name)
            updateFilterSettings()
            
        } else {
            filterInfoView.setFilterName("No Filter")
        }
    }
    
    
    fileprivate func nextFilter(){
        if (filterCount>0){
            filterIdx = (filterIdx+1)%filterCount
            self.setFilterIndex(filterIdx)
        }
        
    }
    
    
    fileprivate func previousFilter(){
        if (filterCount>0){
            filterIdx =  (filterIdx > 0) ? (filterIdx-1) : (filterCount-1)
            self.setFilterIndex(filterIdx)
        }
    }
    
    
    fileprivate var filterSettingsShown: Bool = false
    
    fileprivate func showFilterSettings(){
        if ((currFilterDescriptor?.numParameters)! > 0){
            self.view.addSubview(filterSettingsView)
            filterSettingsView.setFilter(currFilterDescriptor)
            
            filterSettingsView.align(.aboveCentered, relativeTo: filterInfoView, padding: 4, width: filterSettingsView.frame.size.width, height: filterSettingsView.frame.size.height)
            
            filterSettingsShown = true
            //filterSettingsView.show()
        } else {
            hideFilterSettings()
        }
    }
    
    fileprivate func hideFilterSettings(){
        filterSettingsView.dismiss()
        filterSettingsShown = false
    }

    func toggleFilterSettings(){
        if (filterSettingsShown){
            hideFilterSettings()
        } else {
            showFilterSettings()
        }
        
    }
    
    fileprivate func updateFilterSettings(){
        if (filterSettingsShown){
            //hideFilterSettings()
            showFilterSettings()
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

extension FilterCamViewController: CameraSettingsViewDelegate {
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
        cameraDisplayView.setFilter(currFilterDescriptor) // forces reset of filter pipeline
    }
}

extension FilterCamViewController: FilterInfoViewDelegate {
    func filterPressed(){
        //log.debug("Curr Filter pressed")
        
        
        // get list of filters in the Quick Selection category
        if (filterCount==0){
            populateFilterList()
            //filterIdx = 0
            setFilterIndex(0)
        } else {
            
            //TEMP: cycle through filters when button is pressed
            self.nextFilter()
        }
    }
    
    func filterSettingsPressed(){
        //log.debug("Filter Settings pressed")
        toggleFilterSettings()
    }
}

extension FilterCamViewController: FilterCarouselViewDelegate{
    func filterSelected(_ key:String){
        
        guard (filterManager != nil) else {
            return
        }
        
        guard (!key.isEmpty) else {
            return
        }
        
        // setup the filter descriptor
        currFilterDescriptor = filterManager?.getFilterDescriptor(.quickSelect, name:key)
        
        // only update if filters are currently shown
        if (currInfoMode == .filter){
            cameraDisplayView.setFilter(currFilterDescriptor)
            filterInfoView.setFilterName(key)
            updateFilterSettings()
            filterStrip.update()
        }
    }
}



