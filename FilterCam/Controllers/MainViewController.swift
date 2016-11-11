//
//  MainViewController.swift
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

// This is the Main View Controller for FilterCam, and also displays  filters  applied to the direct camera feed

class MainViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SegueHandlerType {
    
    // Filter Info View
    var filterInfoView: FilterInfoView! = FilterInfoView()
    
    // Main Camera View
    var cameraDisplayView: CameraDisplayView! = CameraDisplayView()
    
    // Views for holding the (modal) overlays. Note: must come after CameraDisplayView()
    var filterControlsView : FilterControlsView! = FilterControlsView()
    
    // The Camera controls/options
    var cameraControlsView: CameraControlsView! = CameraControlsView()
    
    // The filter configuration subview
    var filterSettingsView: FilterParametersView! = FilterParametersView()
    
    // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    var showAds:Bool = true
    
    // Filter strip
    var filterSelectionView: FilterSelectionView! = FilterSelectionView()
    
    // Category Selection view
    var categorySelectionView: CategorySelectionView! = CategorySelectionView()
    
    let imagePicker = UIImagePickerController()
    
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
        case categoryManager
    }
    
    
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        //doInit()
    }
    
    static var initDone:Bool = false
    
    func doInit(){
        
        if (!MainViewController.initDone){
            //filterManager = FilterManager.sharedInstance
            filterManager?.setCurrentCategory(FilterManager.CategoryType.quickSelect)
            categorySelectionView.setFilterCategory((filterManager?.getCurrentCategory())!)
            MainViewController.initDone = true
            updateCurrentFilter()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        
        // get display dimensions
        displayHeight = view.height
        displayWidth = view.width
        
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        // get orientation
        //isLandscape = UIDevice.current.orientation.isLandscape // doesn't always work properly, especially in simulator
        isLandscape = (displayWidth > displayHeight)
        
        showAds = (isLandscape == true) ? false : true // don't show in landscape mode, too cluttered
        
        //filterManager?.reset()
        doInit()
        
        // Note: need to add subviews before modifying constraints
        view.addSubview(filterInfoView)
        if (showAds) { view.addSubview(adView) }
        view.addSubview(cameraDisplayView)
        view.addSubview(filterControlsView) // must come after cameraDisplayView
        view.addSubview(cameraControlsView)
        
        // hidden views:
        view.addSubview(filterSelectionView)
        view.addSubview(categorySelectionView)
        view.addSubview(filterSettingsView)
        
        
        // set up layout based on orientation
        
        // filter info view is always at the top of the screen
        filterInfoView.frame.size.height = bannerHeight * 0.75
        filterInfoView.frame.size.width = displayWidth
        filterInfoView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: filterInfoView.frame.size.height)

        if (isLandscape){
            // left-to-right layout scheme, but filter/catgeory/parameter overlays are at the bottom
            
            if (showAds){
                adView.isHidden = false
                adView.frame.size.height = bannerHeight
                adView.frame.size.width = displayWidth - 2 * bannerHeight
                adView.align(.underCentered, relativeTo: filterInfoView, padding: 0, width: displayWidth, height: adView.frame.size.height)
            } else {
                adView.isHidden = true
            }
            
            // Camera Controls at far right, vertically orientated
            cameraControlsView.frame.size.height = displayHeight - filterInfoView.frame.size.height
            cameraControlsView.frame.size.width = bannerHeight
            cameraControlsView.anchorInCorner(.bottomRight, xPad: 0, yPad: 0, width: cameraControlsView.frame.size.width, height: cameraControlsView.frame.size.height)
            
            // filter controls vertical, to the left of camera controls
            filterControlsView.frame.size.height = cameraControlsView.frame.size.height
            filterControlsView.frame.size.width = bannerHeight
            filterControlsView.align(.toTheLeftMatchingBottom, relativeTo: cameraControlsView, padding: 0, width: filterControlsView.frame.size.width, height: filterControlsView.frame.size.height)
            
            // camera display in bottom left corner
            if (showAds){
                cameraDisplayView.frame.size.height = displayHeight - filterInfoView.frame.size.height - adView.frame.size.height
            } else {
                cameraDisplayView.frame.size.height = displayHeight - filterInfoView.frame.size.height
            }
            cameraDisplayView.frame.size.width = displayWidth - cameraControlsView.frame.size.width - filterControlsView.frame.size.width - 8
            cameraDisplayView.anchorInCorner(.bottomLeft, xPad: 0, yPad: 0, width: cameraDisplayView.frame.size.width, height: cameraDisplayView.frame.size.height)
            
            
            // Align Overlay views to bottom of Render View
            filterSelectionView.frame.size.height = 2.0 * bannerHeight
            filterSelectionView.frame.size.width = cameraDisplayView.frame.size.width
            filterSelectionView.anchorInCorner(.bottomLeft, xPad: 0, yPad: 0, width: filterSelectionView.frame.size.width, height: filterSelectionView.frame.size.height)
            
            categorySelectionView.frame.size.height = 2.0 * bannerHeight
            categorySelectionView.frame.size.width = cameraDisplayView.frame.size.width
            categorySelectionView.anchorInCorner(.bottomLeft, xPad: 0, yPad: 0, width: categorySelectionView.frame.size.width, height: categorySelectionView.frame.size.height)
 
            
            filterSettingsView.frame.size.width = cameraDisplayView.frame.size.width
            filterSettingsView.frame.size.height = bannerHeight // will be adjusted based on selected filter
            filterSettingsView.anchorInCorner(.bottomLeft, xPad: 0, yPad: 0, width: filterSettingsView.frame.size.width, height: filterSettingsView.frame.size.height)

        } else {
            // Portrait: top-to-bottom layout scheme
            
            if (showAds){
                adView.frame.size.height = bannerHeight
                adView.frame.size.width = displayWidth
                adView.align(.underCentered, relativeTo: filterInfoView, padding: 0, width: displayWidth, height: adView.frame.size.height)
                cameraDisplayView.frame.size.height = displayHeight - 1.5 * bannerHeight
            } else {
                cameraDisplayView.frame.size.height = displayHeight - 2.5 * bannerHeight
            }
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

            filterSettingsView.frame.size.width = displayWidth
            filterSettingsView.frame.size.height = bannerHeight // will be adjusted based on selected filter
            filterSettingsView.align(.aboveCentered, relativeTo: filterControlsView, padding: 4, width: filterSettingsView.frame.size.width, height: filterSettingsView.frame.size.height)
}
        
        //setFilterIndex(0) // no filter
        
        // add delegates to sub-views (for callbacks)
        filterInfoView.delegate = self
        cameraControlsView.delegate = self
        filterInfoView.delegate = self
        filterControlsView.delegate = self
        filterSelectionView.delegate = self
        categorySelectionView.delegate = self
        imagePicker.delegate = self

        
        // set gesture detction for Filter Settings view
        //setGestureDetectors(view: filterSettingsView)
        
        
        // listen to key press events
        setVolumeListener()
        
        
        //TODO: select filter category somehow
        //filterSelectionView.setFilterCategory(FilterManager.CategoryType.quickSelect)
        
        //TODO: remember state?
        hideCategorySelector()
        hideFilterSelector()
        

        // start Ads
        if (showAds){
            Admob.startAds(view:adView, viewController:self)
        }
        
        //TODO: start timer and update setting display peridodically
        
        // register for change notifications (don't do this before the views are set up)
        filterManager?.setCategoryChangeNotification(callback: categoryChanged())
        filterManager?.setFilterChangeNotification(callback: filterChanged())
        
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
        cameraDisplayView.setFilter(nil)
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
    
    //////////////////////////////////////
    //MARK: - Utility functions
    //////////////////////////////////////
    
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
    
    
    
    //////////////////////////////////////
    // MARK: - Filter/Category Management
    //////////////////////////////////////
    
    func categoryChanged(){
        updateCurrentFilter()
    }
    
    func filterChanged(){
        updateCurrentFilter()
    }
    
    // retrive current settings from FilterManager and store locally
    func updateCurrentFilter(){
        let descriptor = filterManager?.getCurrentFilterDescriptor()
        //log.verbose("Current filter: \(descriptor?.key)")
        //if (descriptor?.key != currFilterDescriptor?.key){
        currFilterDescriptor = descriptor
        cameraDisplayView.setFilter(currFilterDescriptor)
        categorySelectionView.setFilterCategory((filterManager?.getCurrentCategory())!)
        filterSelectionView.setFilterCategory((filterManager?.getCurrentCategory())!)
        filterSelectionView.update()
        filterInfoView.update()
        //} else {
        //    log.debug("Ignoring \(currFilterDescriptor?.key)->\(descriptor?.key) transition")
        //}
        
        if (currFilterDescriptor != nil){
            if ((currFilterDescriptor?.numParameters)! == 0){
                filterControlsView.setParametersControlState(.disabled)
            }
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
        filterControlsView.setCategoryControlState(.hidden)
    }
    
    func showCategorySelector(){
        updateCurrentFilter()
        categorySelectionView.isHidden = false
        categorySelectorShown = true
        filterControlsView.setCategoryControlState(.shown)
        categorySelectionView.update()
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
        filterControlsView.setFilterControlState(.hidden)
    }
    
    func showFilterSelector(){
        updateCurrentFilter()
        if (currFilterDescriptor != nil){
            filterSelectionView.isHidden = false
            filterSelectorShown = true
            filterControlsView.setFilterControlState(.shown)
            view.bringSubview(toFront: filterSelectionView)
        } else {
            log.warning("WARN: current filter not set")
        }
    }
    
    // Management of Filter Parameters view
    fileprivate var filterSettingsShown: Bool = false
    
    fileprivate func showFilterSettings(){
        updateCurrentFilter()
        if ((currFilterDescriptor != nil) && ((currFilterDescriptor?.numParameters)! > 0)){
            // re-layout based on selecetd filter
            filterSettingsView.frame.size.height = CGFloat(((currFilterDescriptor?.numParameters)! + 1)) * bannerHeight * 0.75
            if (isLandscape){
                filterSettingsView.anchorInCorner(.bottomLeft, xPad: 0, yPad: 0, width: filterSettingsView.frame.size.width, height: filterSettingsView.frame.size.height)
            } else {
                filterSettingsView.align(.aboveCentered, relativeTo: filterControlsView, padding: 4, width: filterSettingsView.frame.size.width, height: filterSettingsView.frame.size.height)
            }

            filterSettingsView.setFilter(currFilterDescriptor)

            //filterSettingsView.align(.aboveCentered, relativeTo: filterControlsView, padding: 4, width: filterSettingsView.frame.size.width, height: filterSettingsView.frame.size.height)
            filterSettingsView.isHidden = false
            filterSettingsShown = true
            view.bringSubview(toFront: filterSettingsView)
            filterControlsView.setParametersControlState(.shown)
            //filterSettingsView.show()
        } else {
            log.debug("No parameters to display")
            filterControlsView.setParametersControlState(.disabled)
            hideFilterSettings()
        }
    }
    
    fileprivate func hideFilterSettings(){
        filterSettingsView.dismiss()
        filterSettingsView.isHidden = true
        filterSettingsShown = false
        filterControlsView.setParametersControlState(.hidden)
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
    
    func presentFilterGallery(){
        //launch Category Manager VC
        CameraManager.stopCapture()
        filterSelectionView.suspend()
        callbacksEnabled = false
        
        let gallery = FilterGalleryViewController()
        gallery.delegate = self
        present(gallery, animated: true, completion: nil)
        //self.performSegueWithIdentifier(.categoryManager, sender: self)
    }

    
    
    // generic handler to restart processing once another view controller has finished
    fileprivate func returnFromController(){
        log.debug("Returned from ViewController")
        DispatchQueue.main.async(execute: { () -> Void in
            self.filterManager?.setCurrentCategory((self.filterManager?.getCurrentCategory())!)
            self.viewDidLoad()
            self.cameraDisplayView.setFilter(nil)
            self.cameraDisplayView.setFilter(self.currFilterDescriptor) // forces reset of filter pipeline
        })
        //CameraManager.startCapture()
    }
    
    
    //////////////////////////////////////////
    // MARK: - Blend Gallery handling
    //////////////////////////////////////////
    
    
    func presentBlendGallery(){
        let gallery = BlendGalleryViewController()
        gallery.delegate = self
        present(gallery, animated: true, completion: nil)
    }
    
    
    //////////////////////////////////////////
    // MARK: - ImagePicker handling
    //////////////////////////////////////////
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        log.debug("Image returned: \(info[UIImagePickerControllerMediaURL])")
        //TODO: save image to global location, launch VC to handle it
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            log.verbose("Image returned successfully")
            // copy image to ImageManager storage and launch the Editor ViewController
        } else {
            log.error("Error accessing image")
        }
        
        picker.dismiss(animated: true)
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    
    
    
    /////////////////////////////////
    // Main Menu setup
    /////////////////////////////////
    
    
    fileprivate var optionsController:UIAlertController? = nil
    
     func showMenu(){
        if (optionsController == nil){
            let titleString  = "Options:"
            optionsController = UIAlertController(title: titleString, message: "", preferredStyle: .alert)
 
            let sysFont: UIFont = UIFont.boldSystemFont(ofSize: 22)
            
            var myMutableString = NSMutableAttributedString()
            myMutableString = NSMutableAttributedString(string: titleString as String, attributes: [NSFontAttributeName:sysFont])
            myMutableString.addAttribute(NSForegroundColorAttributeName, value: UIColor.blue, range: NSRange(location:0,length:titleString.characters.count))
            optionsController?.setValue(myMutableString, forKey: "attributedTitle")
            
            let filterGalleryAction =  UIAlertAction(title: "View/Manage Filters", style: .default) { (action:UIAlertAction) in
                log.debug("View/Manage Filters selected")
                self.presentFilterGallery()
            }
            
            let changeBlendAction =  UIAlertAction(title: "Change Blend Image", style: .default) { (action:UIAlertAction) in
                log.debug("Change Blend Image")
                self.presentBlendGallery()
            }
            
            let changeSampleAction =  UIAlertAction(title: "Change Sample Image", style: .default) { (action:UIAlertAction) in
                log.debug("Change Sample Image")
            }
            
            let aboutAction =  UIAlertAction(title: "About FilterCam", style: .default) { (action:UIAlertAction) in
                log.debug("About FilterCam")
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
                log.debug("About FilterCam")
            }

            
            optionsController?.addAction(filterGalleryAction)
            optionsController?.addAction(changeBlendAction)
            optionsController?.addAction(changeSampleAction)
            optionsController?.addAction(aboutAction)
            optionsController?.addAction(cancelAction)
        }
        
        present(optionsController!, animated: true, completion:nil)
    }
    
    
} // MainViewController







//////////////////////////////////////////
// MARK: - Delegate methods for sub-views
//////////////////////////////////////////


// CameraControlsViewDelegate

fileprivate var callbacksEnabled = true
extension MainViewController: CameraControlsViewDelegate {
    func imagePreviewPressed(){
        DispatchQueue.main.async(execute: { () -> Void in
            log.debug("imagePreview pressed - launching ImagePicker...")
            // launch an ImagePicker
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .photoLibrary
            
            self.present(self.imagePicker, animated: true, completion: nil)
        })
    }
    
    func takePicturePressed(){
        log.debug("Take Picture pressed")
        saveImage()
        playCameraSound()
        cameraControlsView.update()
    }
    
    func modePressed(){
        log.debug("Filter Mgr pressed")
        //swapInfoMode()
    }
    
    func settingsPressed(){
        log.debug("Settings pressed")
        
        // display the main menu
        self.showMenu()
    }
}



// FilterInfoViewDelegate

extension MainViewController: FilterInfoViewDelegate {
    
    func swapCameraPressed(){
        log.debug("swapCameraPressed pressed")
        CameraManager.switchCameraLocation()
        cameraDisplayView.setFilter(currFilterDescriptor)
    }
}


// FilterControlsViewDelegate

extension MainViewController: FilterControlsViewDelegate {
    func categoryPressed(){
        log.debug("Show/Hide Categories pressed")
        callbacksEnabled = true
        toggleCategoryState()
    }
    func filterPressed(){
        callbacksEnabled = true
        log.debug("Show/Hide Filters pressed")
        toggleFilterState()
    }
    
    func filterParametersPressed(){
        callbacksEnabled = true
        log.debug("Show/Hide Filter Settings pressed")
        toggleFilterSettings()
    }
}


// CategorySelectionViewDelegate

extension MainViewController: CategorySelectionViewDelegate {
    func categorySelected(_ category:FilterManager.CategoryType){
        
        guard (callbacksEnabled) else {
            log.info("Category Selected Callback ignored")
            return
        }
        log.debug("Category Selected: \(category)")
        filterManager?.setCurrentCategory(category)
    }
    
}


// FilterSelectionViewDelegate

extension MainViewController: FilterSelectionViewDelegate{
    func filterSelected(_ key:String){
        
        guard (filterManager != nil) else {
            return
        }
        
        guard (!key.isEmpty) else {
            return
        }
        
        guard (callbacksEnabled) else {
            log.info("Filter Selected Callback ignored")
            return
        }
        
        // setup the filter descriptor
        currFilterDescriptor = filterManager?.getFilterDescriptor(key:key)
        updateCurrentFilter()
        
        /***
         // only update if filters are currently shown
         if (currInfoMode == .filter){
         cameraDisplayView.setFilter(currFilterDescriptor)
         //filterInfoView.setFilterName(key)
         updateFilterSettings()
         filterSelectionView.update()
         filterInfoView.update()
         }
         ***/
    }
}


// FilterGalleryViewControllerDelegate

extension MainViewController: FilterGalleryViewControllerDelegate {
    internal func filterGalleryCompleted(){
        log.debug("Returned from Filter Gallery")
        callbacksEnabled = true
        self.returnFromController()
    }
}


// BlendGalleryViewControllerDelegate

extension MainViewController: BlendGalleryViewControllerDelegate {
    internal func blendGalleryCompleted(){
        log.debug("Returned from Blend Gallery")
        callbacksEnabled = true
        self.returnFromController()
    }
}


