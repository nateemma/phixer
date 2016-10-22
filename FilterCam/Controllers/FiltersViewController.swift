//
//  FiltersViewController.swift
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

// This is the View Controller for displaying the filters functionality applied to the direct camera feed

class FiltersViewController: UIViewController, SegueHandlerType {
    
    // Filter Info View
    var filterInfoView: FilterInfoView! = FilterInfoView()
    
    // Main Camera View
    var cameraDisplayView: CameraDisplayView! = CameraDisplayView()
    
    // Views for holding the (modal) overlays. Note: must come after CameraDisplayView()
    var filterControlsView : FilterControlsView! = FilterControlsView()
    
    // the current display mode for the information view
    var currInfoMode:InfoMode = .filter
    
    
    // The Camera controls/options
    var cameraControlsView: CameraControlsView! = CameraControlsView()

    // The filter configuration subview
    var filterSettingsView: FilterParametersView! = FilterParametersView()
    
    // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    
    // Filter strip
    var filterSelectionView: FilterSelectionView! = FilterSelectionView()
    
    // Category Selection view
    var categorySelectionView: CategorySelectionView! = CategorySelectionView()
    
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
        doInit()
    }

    static var initDone:Bool = false

    func doInit(){
        
        if (!FiltersViewController.initDone){
            filterManager = FilterManager.sharedInstance
            filterManager?.setCurrentCategory(FilterCategoryType.quickSelect)
            FiltersViewController.initDone = true
            updateCurrentFilter()
        }
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
            
            doInit()
           
            // Note: need to add subviews before modifying constraints
            view.addSubview(filterInfoView)
            view.addSubview(adView)
            view.addSubview(cameraDisplayView)
            view.addSubview(filterControlsView) // must come after cameraDisplayView
            view.addSubview(cameraControlsView)
            
            // hidden views:
            view.addSubview(filterSelectionView)
            view.addSubview(categorySelectionView)
            
            
            // set up layout based on orientation
            if (isLandscape){
                // left-to-right layout scheme
                filterInfoView.frame.size.height = displayHeight
                filterInfoView.frame.size.width = bannerHeight / 1.5
                filterInfoView.anchorAndFillEdge(.left, xPad: 0, yPad: 0, otherSize: bannerHeight)
                
                
                adView.frame.size.height = bannerHeight
                adView.frame.size.width = displayWidth - 2 * bannerHeight
                adView.align(.underCentered, relativeTo: filterInfoView, padding: 0,
                             width: displayWidth, height: adView.frame.size.height)
                
                cameraControlsView.frame.size.height = displayHeight
                cameraControlsView.frame.size.width = bannerHeight
                cameraControlsView.anchorAndFillEdge(.right, xPad: 0, yPad: 0, otherSize: bannerHeight)
                
                cameraDisplayView.frame.size.height = displayHeight
                cameraDisplayView.frame.size.width = displayWidth - 2 * bannerHeight
                cameraDisplayView.alignBetweenHorizontal(.toTheLeftMatchingTop, primaryView: filterInfoView, secondaryView: cameraControlsView, padding: 0, height: displayHeight)
                
                
                // Align Overlay view to bottom of Render View
                filterControlsView.frame.size.height = bannerHeight / 1.5
                filterControlsView.frame.size.width = displayWidth - 2 * bannerHeight
                filterControlsView.alignBetweenHorizontal(.toTheLeftMatchingBottom, primaryView: cameraControlsView, secondaryView: filterInfoView, padding: 0, height: bannerHeight)
                
                filterSelectionView.frame.size.height = 2.0 * bannerHeight
                filterSelectionView.frame.size = filterInfoView.frame.size
                filterSelectionView.alignBetweenHorizontal(.toTheLeftMatchingBottom, primaryView: cameraControlsView, secondaryView: filterInfoView,
                                                           padding: 0, height: filterSelectionView.frame.size.height)
                
                categorySelectionView.frame.size.height = 2.0 * bannerHeight
                categorySelectionView.frame.size = filterInfoView.frame.size
                categorySelectionView.alignBetweenHorizontal(.toTheLeftMatchingBottom, primaryView: cameraControlsView, secondaryView: filterInfoView,
                                                           padding: 0, height: categorySelectionView.frame.size.height)
                
            } else {
                // Portrait: top-to-bottom layout scheme
                
                filterInfoView.frame.size.height = bannerHeight * 0.75
                filterInfoView.frame.size.width = displayWidth
                filterInfoView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: filterInfoView.frame.size.height)
                
                adView.frame.size.height = bannerHeight
                adView.frame.size.width = displayWidth
                adView.align(.underCentered, relativeTo: filterInfoView, padding: 0, width: displayWidth, height: adView.frame.size.height)
                
                
                cameraDisplayView.frame.size.height = displayHeight - 2.5 * bannerHeight
                //cameraDisplayView.frame.size.height = displayHeight - 5.5 * bannerHeight
                cameraDisplayView.frame.size.width = displayWidth
                cameraDisplayView.align(.underCentered, relativeTo: adView, padding: 0, width: displayWidth, height: cameraDisplayView.frame.size.height)

                cameraControlsView.frame.size.height = bannerHeight
                cameraControlsView.frame.size.width = displayWidth
                cameraControlsView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: bannerHeight)
                
                filterControlsView.frame.size.height = bannerHeight * 0.75
                filterControlsView.frame.size.width = displayWidth
                filterControlsView.align(.aboveCentered, relativeTo: cameraControlsView, padding: 0, width: displayWidth, height: filterInfoView.frame.size.height)
                
                filterSelectionView.frame.size.height = 1.7 * bannerHeight
                filterSelectionView.frame.size.width = displayWidth
                filterSelectionView.align(.aboveCentered, relativeTo: filterControlsView, padding: 0, width: filterSelectionView.frame.size.width, height: filterSelectionView.frame.size.height)
                
                categorySelectionView.frame.size.height = 1.7 * bannerHeight
                categorySelectionView.frame.size.width = displayWidth
                categorySelectionView.align(.aboveCentered, relativeTo: filterControlsView, padding: 0, width: categorySelectionView.frame.size.width, height: categorySelectionView.frame.size.height)
            }
            
            //setFilterIndex(0) // no filter
            
            // add delegates to sub-views (for callbacks)
            filterInfoView.delegate = self
            cameraControlsView.delegate = self
            //cameraInfoView.delegate = self
            filterInfoView.delegate = self
            filterControlsView.delegate = self
            //filterSettingsView.delegate = self
            filterSelectionView.delegate = self
            
            // set gesture detction for Filter Settings view
            //setGestureDetectors(view: filterSettingsView)

            
            // listen to key press events
            setVolumeListener()
            
            setInfoMode(currInfoMode) // must be after view setup
            
            //TODO: select filter category somehow
            //filterSelectionView.setFilterCategory(FilterCategoryType.quickSelect)
            //filterSelectionView.isHidden = true
            //filterSelectionView.isHidden = false // TEMP
            
            //TODO: remeber state?
            hideCategorySelector()
            hideFilterSelector()
     

            
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
                break
                
            case UISwipeGestureRecognizerDirection.left:
                //log.verbose("Swiped Left")
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
            let category = filterManager?.getCurrentCategory()
            filterList = (filterManager?.getFilterList(category!))!
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
            //TODO: sitch to Camera view
            break
        case .filter:
            updateCurrentFilter()
            cameraDisplayView.setFilter(currFilterDescriptor)
            filterSelectionView.update()
            filterInfoView.update()
            filterInfoView.isHidden = false
            filterSelectionView.isHidden = false
            view.bringSubview(toFront: filterSelectionView)
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
    
    //////////////////////////////////////
    // MARK: - Filter/Category Management
    //////////////////////////////////////


    // retriev current settings from FilterManager and store locally
    func updateCurrentFilter(){
        let descriptor = filterManager?.getCurrentFilterDescriptor()
        if (descriptor?.key != currFilterDescriptor?.key){
            currFilterDescriptor = descriptor
            cameraDisplayView.setFilter(currFilterDescriptor)
            filterSelectionView.setFilterCategory((filterManager?.getCurrentCategory())!)
            filterSelectionView.update()
            filterInfoView.update()
        }
    }
    
    
    // Management of Category Selection view
    fileprivate var categorySelectorShown: Bool = false
    
    func toggleCategoryState(){
        if (categorySelectorShown){
            hideCategorySelector()
        } else {
            showCategorySelector()
        }
    }
    
    func hideCategorySelector(){
        updateCurrentFilter()
        categorySelectionView.isHidden = true
        categorySelectorShown = false
    }
    
    func showCategorySelector(){
        updateCurrentFilter()
        categorySelectionView.isHidden = false
        categorySelectorShown = true
        view.bringSubview(toFront: categorySelectionView)
    }
    
    
    // Management of Filter Selection view
    fileprivate var filterSelectorShown: Bool = false
    
    func toggleFilterState(){
        if (filterSelectorShown){
            hideFilterSelector()
        } else {
            showFilterSelector()
        }
    }
    
    func hideFilterSelector(){
        updateCurrentFilter()
        filterSelectionView.isHidden = true
        filterSelectorShown = false
    }
    
    func showFilterSelector(){
        updateCurrentFilter()
        if (currFilterDescriptor != nil){
            filterSelectionView.isHidden = false
            filterSelectorShown = true
            view.bringSubview(toFront: filterSelectionView)
        }
    }
    
    // Management of Filter Parameters view
    fileprivate var filterSettingsShown: Bool = false
    
    fileprivate func showFilterSettings(){
        updateCurrentFilter()
        if ((currFilterDescriptor != nil) && ((currFilterDescriptor?.numParameters)! > 0)){
            self.view.addSubview(filterSettingsView)
            filterSettingsView.setFilter(currFilterDescriptor)
            
            filterSettingsView.align(.aboveCentered, relativeTo: filterControlsView, padding: 4, width: filterSettingsView.frame.size.width, height: filterSettingsView.frame.size.height)
            filterSettingsView.isHidden = false
            filterSettingsShown = true
            view.bringSubview(toFront: filterSettingsView)
            //filterSettingsView.show()
        } else {
            log.debug("No parameters to display")
            hideFilterSettings()
        }
    }
    
    fileprivate func hideFilterSettings(){
        filterSettingsView.dismiss()
        filterSettingsView.isHidden = true
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

//////////////////////////////////////////
// MARK: - Delegate methods for sub-views
//////////////////////////////////////////

extension FiltersViewController: CameraControlsViewDelegate {
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



extension FiltersViewController: FilterInfoViewDelegate {   
    func swapCameraPressed(){
        log.debug("swapCameraPressed pressed")
        CameraManager.switchCameraLocation()
    }
}


extension FiltersViewController: FilterControlsViewDelegate {
    func categoryPressed(){
        log.debug("Show/Hide Categories pressed")
        toggleCategoryState()
    }
    func filterPressed(){
        log.debug("Show/Hide Filters pressed")
        toggleFilterState()
    }
    
    func filterSettingsPressed(){
        log.debug("Show/Hide Filter Settings pressed")
        toggleFilterSettings()
    }
}

extension FiltersViewController: FilterSelectionViewDelegate{
    func filterSelected(_ key:String){
        
        guard (filterManager != nil) else {
            return
        }
        
        guard (!key.isEmpty) else {
            return
        }
        
        // setup the filter descriptor
        let category = filterManager?.getCurrentCategory()
        currFilterDescriptor = filterManager?.getFilterDescriptor(category!, name:key)
        
        // only update if filters are currently shown
        if (currInfoMode == .filter){
            cameraDisplayView.setFilter(currFilterDescriptor)
            //filterInfoView.setFilterName(key)
            updateFilterSettings()
            filterSelectionView.update()
            filterInfoView.update()
        }
    }
}



