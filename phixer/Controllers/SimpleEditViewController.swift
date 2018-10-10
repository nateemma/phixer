//
//  SimpleEditViewController.swift
//  phixer
//
//  Created by Philip Price on 9/6/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import CoreImage
import Neon
import AVFoundation
import MediaPlayer
import AudioToolbox

import GoogleMobileAds



private var filterList: [String] = []
private var filterCount: Int = 0

// This View Controller handles simple editing of a photo

class SimpleEditViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    // Banner/Navigation View (title)
    fileprivate var bannerView: UIView! = UIView()
    fileprivate var backButton:UIButton! = UIButton()
    fileprivate var titleLabel:UILabel! = UILabel()
    
    
    // Main Display View
    var editImageView: EditImageDisplayView! = EditImageDisplayView()
    
    // Views for holding the (modal) overlays. Note: must come after EditImageDisplayView()
    var filterControlsView : FilterControlsView! = FilterControlsView()
    
    // The Edit controls/options
    var editControlsView: EditControlsView! = EditControlsView()
    
    // The filter configuration subview
    var filterSettingsView: FilterParametersView! = FilterParametersView()
    
    // Filter strip
    var filterSelectionView: FilterSelectionView! = FilterSelectionView()
    
    // Category Selection view
    var categorySelectionView: CategorySelectionView! = CategorySelectionView()
    
    let imagePicker = UIImagePickerController()
    
    var filterManager: FilterManager? = FilterManager.sharedInstance
    
    var currCategory:String? = nil
    var currFilterKey:String? = nil
    
    var currFilterDescriptor:FilterDescriptor? = nil
    var currIndex:Int = 0
    
    var isLandscape : Bool = false
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    let bannerHeight : CGFloat = 64.0
    let buttonSize : CGFloat = 48.0
    fileprivate let statusBarOffset : CGFloat = 12.0
    
    let editControlHeight = 64.0
    
    
    
    
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        //doInit()
    }
    
    static var initDone:Bool = false
    
    func doInit(){
        
        if (currFilterDescriptor == nil){
            currFilterDescriptor = filterManager?.getFilterDescriptor(key: "NoFilter")
        }
        
        //if (!SimpleEditViewController.initDone){
            log.verbose("init")
            //filterManager = FilterManager.sharedInstance
            //TODO: set to "No Filter"
            filterManager?.setCurrentCategory("none")
            categorySelectionView.setFilterCategory("none")
            currFilterDescriptor = filterManager?.getFilterDescriptor(key: "NoFilter")
            filterSelectionView.setInputSource(.photo)
            editImageView.setFilter(key: "NoFilter")
            SimpleEditViewController.initDone = true
            populateFilterList()
            updateCurrentFilter()
        //}
    }
    
    open func suspend(){
        editImageView.suspend()
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
        
        //filterManager?.reset()
        doInit()
        
        // Note: need to add subviews before modifying constraints
        view.addSubview(bannerView)
        //view.addSubview(filterInfoView)
        view.addSubview(editImageView)
        view.addSubview(editControlsView)
        
        // hidden views:
        view.addSubview(filterControlsView) // must come after editImageView
        view.addSubview(filterSelectionView)
        view.addSubview(categorySelectionView)
        view.addSubview(filterSettingsView)
        
        
        // set up layout based on orientation
        
        // Banner and filter info view are always at the top of the screen
        bannerView.frame.size.height = bannerHeight * 0.75
        bannerView.frame.size.width = displayWidth
        bannerView.backgroundColor = UIColor.black
        
        
        layoutBanner()
        bannerView.anchorAndFillEdge(.top, xPad: 0, yPad: statusBarOffset/2.0, otherSize: bannerView.frame.size.height)
        
        
        // Only Portrait mode supported (for now)
        
        editImageView.frame.size.width = displayWidth
        editImageView.frame.size.height = displayHeight - 2.5 * bannerHeight
        editImageView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: editImageView.frame.size.height)
        
        //editControlsView.frame.size.height = bannerHeight + 8.0
        editControlsView.frame.size.height = CGFloat(editControlHeight)
        editControlsView.frame.size.width = displayWidth
        editControlsView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: editControlsView.frame.size.height)
        
        filterControlsView.frame.size.height = bannerHeight * 0.5
        filterControlsView.frame.size.width = displayWidth
        filterControlsView.align(.aboveCentered, relativeTo: editControlsView, padding: 0, width: displayWidth, height: filterControlsView.frame.size.height)
        
        filterSelectionView.frame.size.height = 1.7 * bannerHeight
        filterSelectionView.frame.size.width = displayWidth
        filterSelectionView.align(.aboveCentered, relativeTo: filterControlsView, padding: 0, width: filterSelectionView.frame.size.width, height: filterSelectionView.frame.size.height)
        
        categorySelectionView.frame.size.height = 1.7 * bannerHeight
        categorySelectionView.frame.size.width = displayWidth
        categorySelectionView.align(.aboveCentered, relativeTo: filterControlsView, padding: 0, width: categorySelectionView.frame.size.width, height: categorySelectionView.frame.size.height)
        
        filterSettingsView.frame.size.width = displayWidth
        filterSettingsView.frame.size.height = bannerHeight // will be adjusted based on selected filter
        filterSettingsView.align(.aboveCentered, relativeTo: filterControlsView, padding: 4, width: filterSettingsView.frame.size.width, height: filterSettingsView.frame.size.height)
        
        //setFilterIndex(0) // no filter
        
        // add delegates to sub-views (for callbacks)
        editControlsView.delegate = self
        filterControlsView.delegate = self
        filterSelectionView.delegate = self
        categorySelectionView.delegate = self
        imagePicker.delegate = self
        
        
        // set gesture detection for the camera display view
        setGestureDetectors(view: editImageView)
        
        
        // listen to key press events
        setVolumeListener()
        
        
        //TODO: select filter category somehow
        //filterSelectionView.setFilterCategory(String.favorites)
        
        //TODO: remember state?
        hideCategorySelector()
        hideFilterSelector()
        hideFilterControls()
        
        //update filtered image
        editImageView.updateImage()
       
        
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
        //editImageView.setFilter(nil)
        editImageView.setFilter(key:(currFilterDescriptor?.key)!) // forces reset of filter pipeline
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // Autorotate configuration
    
    /*** pre-iOS 10
     override func shouldAutorotate() -> Bool {
     if (UIDevice.current.orientation == UIDeviceOrientation.portrait ||
     UIDevice.current.orientation == UIDeviceOrientation.portraitUpsideDown ||
     UIDevice.current.orientation == UIDeviceOrientation.unknown) {
     return true
     }
     else {
     return false
     }
     }
     
     override func supportedInterfaceOrientations() -> Int {
     return Int(UIInterfaceOrientationMask.portrait.rawValue) | Int(UIInterfaceOrientationMask.portraitUpsideDown.rawValue)
     }
     ***/
    
    //NOTE: only works for iOS 10 and later
    
    override open var shouldAutorotate: Bool {
        return false
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    
    // layout the banner view, with the Back button, title etc.
    func layoutBanner(){
        bannerView.addSubview(backButton)
        bannerView.addSubview(titleLabel)
        
        backButton.frame.size.height = bannerView.frame.size.height - 8
        backButton.frame.size.width = 2.0 * backButton.frame.size.height
        backButton.setTitle("< Back", for: .normal)
        backButton.backgroundColor = UIColor.flatMint
        backButton.setTitleColor(UIColor.white, for: .normal)
        backButton.titleLabel!.font = UIFont.boldSystemFont(ofSize: 20.0)
        backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
        
        titleLabel.frame.size.height = backButton.frame.size.height
        titleLabel.frame.size.width = displayWidth - backButton.frame.size.width
        titleLabel.text = "Edit Photo"
        titleLabel.backgroundColor = UIColor.black
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
        titleLabel.textAlignment = .center
        
        
        backButton.anchorInCorner(.bottomLeft, xPad: 4, yPad: 4, width: backButton.frame.size.width, height: backButton.frame.size.height)
        titleLabel.align(.toTheRightCentered, relativeTo: backButton, padding: 0, width: titleLabel.frame.size.width, height: titleLabel.frame.size.height)
        
        backButton.addTarget(self, action: #selector(self.backDidPress), for: .touchUpInside)
        
    }
    
    
    
    //////////////////////////////////////
    // MARK: - Volume buttons
    //////////////////////////////////////
    
    
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
    
    
    
    //////////////////////////////////////
    // MARK: - Category/Filter Navigation
    //////////////////////////////////////
    
    
    // Note: look up current values each time because they can be changed in multiple ways (so difficult to track)
    
    // TODO: use local list (filterList), since that takes into account whether a filter is shown or not
    
    fileprivate func nextFilter(){
        /***
         var index  = (filterManager?.getCurrentFilterIndex())!
         let category = (filterManager?.getCurrentCategory())!
         let oldIndex = index
         let oldKey = (filterManager?.getFilterKey(category: category, index: index))!
         
         index = (index + 1) % (filterManager?.getFilterCount(category))!
         let key = (filterManager?.getFilterKey(category: category, index: index))!
         **/
        let oldIndex = currIndex
        let oldKey = filterList[currIndex]
        currIndex = (currIndex + 1) % filterList.count
        let key = filterList[currIndex]
        
        log.debug("Changing filter: \(oldKey)(\(oldIndex))->\(key)(\(index))")
        changeFilterTo(key)
    }
    
    
    fileprivate func previousFilter(){
        /**
         var index  = (filterManager?.getCurrentFilterIndex())!
         let category = (filterManager?.getCurrentCategory())!
         let oldIndex = index
         let oldKey = (filterManager?.getFilterKey(category: category, index: index))!
         
         index = index - 1
         if (index < 0) { index = (filterManager?.getFilterCount(category))! - 1 }
         let key = (filterManager?.getFilterKey(category: category, index: index))!
         **/
        
        let oldIndex = currIndex
        let oldKey = filterList[currIndex]
        currIndex = currIndex - 1
        if (currIndex < 0) { currIndex = filterList.count - 1 }
        let key = filterList[currIndex]
        
        log.debug("Changing filter: \(oldKey)(\(oldIndex))->\(key)(\(index))")
        changeFilterTo(key)
    }
    
    fileprivate func nextCategory(){
        var category = (filterManager?.getCurrentCategory())!
        var index = (filterManager?.getCurrentCategoryIndex())!
        index = (index + 1) % (filterManager?.getCategoryCount())!
        category = (filterManager?.getCategory(index: index))!
        changeCategoryTo(category)
    }
    
    fileprivate func previousCategory(){
        var category = (filterManager?.getCurrentCategory())!
        var index = (filterManager?.getCurrentCategoryIndex())!
        index = (index - 1)
        if (index < 0) { index = (filterManager?.getCategoryCount())! - 1 }
        category = (filterManager?.getCategory(index: index))!
        changeCategoryTo(category)
    }
    
    
    //////////////////////////////////////
    // MARK: - Gesture Detection
    //////////////////////////////////////
    
    
    func setGestureDetectors(view: UIView){
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
    
    
    @objc func swiped(_ gesture: UIGestureRecognizer)
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
                previousCategory()
                break
                
            case UISwipeGestureRecognizerDirection.down:
                nextCategory()
                //log.verbose("Swiped Down")
                break
                
            default:
                log.debug("Unhandled gesture direction: \(swipeGesture.direction)")
                break
            }
        }
    }
    
    
    //////////////////////////////////////
    //MARK: - Navigation
    //////////////////////////////////////
    @objc func backDidPress(){
        log.verbose("Back pressed")
        exitScreen()
    }
    
    
    func exitScreen(){
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            suspend()
            dismiss(animated: true, completion:  { })
            return
        }
    }
    
    
    //////////////////////////////////////
    //MARK: - Utility functions
    //////////////////////////////////////
    
    open func saveImage(){
        do{
            let documentsDir = try FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
            //TOFIX: generate filename? Or, just overwrite same file since it's copied to Photos anyway?
            editImageView.saveImage(URL(string:"phixerImage.png", relativeTo:documentsDir)!)
            
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
        
        // get list of filters in the current category
        //if (filterCount==0){
        filterList = []
        let category = filterManager?.getCurrentCategory()
        //filterList = (filterManager?.getFilterList(category!))!
        filterList = (filterManager?.getShownFilterList(category!))!
        filterList.sort(by: { (value1: String, value2: String) -> Bool in return value1 < value2 }) // sort ascending
        filterCount = filterList.count
        //log.debug("Filter list for \(category): \(filterList)")
        
        //}
    }
    
    
    
    //////////////////////////////////////
    // MARK: - Filter/Category Management
    //////////////////////////////////////
    
    func changeCategoryTo(_ category: String){
        currCategory = category
        
        if (category != filterManager?.getCurrentCategory()){
            log.debug("Category Selected: \(category)")
            filterManager?.setCurrentCategory(category)
            currFilterDescriptor = filterManager?.getCurrentFilterDescriptor()
            updateCurrentFilter()
            populateFilterList()
        }
    }
    
    func changeFilterTo(_ key:String){
        currFilterKey = key
        // setup the filter descriptor
        if (key != filterManager?.getCurrentFilterKey()){
            log.debug("Filter Selected: \(key)")
            filterManager?.setCurrentFilterKey(key)
            currFilterDescriptor = filterManager?.getFilterDescriptor(key:key)
            updateCurrentFilter()
        }
    }
    
    
    func categoryChanged(){
        updateCurrentFilter()
    }
    
    func filterChanged(){
        updateCurrentFilter()
    }
    
    // retrive current settings from FilterManager and store locally
    func updateCurrentFilter(){
        /***
        //if let descriptor = filterManager?.getCurrentFilterDescriptor(){
            //log.verbose("Current filter: \(descriptor.key)")
            //if ((currFilterDescriptor == nil) || (descriptor.key != currFilterDescriptor?.key)){
            //log.debug("Filter change: \(descriptor.key)->\(String(describing: currFilterDescriptor?.key))")
            //currFilterDescriptor = descriptor
            editImageView.setFilter(key:(self.currFilterDescriptor?.key)!)
            categorySelectionView.setFilterCategory((filterManager?.getCurrentCategory())!)
            filterSelectionView.setFilterCategory((filterManager?.getCurrentCategory())!)
            //filterSelectionView.update()
            //} else {
            //    log.debug("Ignoring \(currFilterDescriptor?.key)->\(descriptor.key) transition")
            //}
        //} else {
        //    editImageView.setFilter(key:"")
        //}
 ***/
        
        if (currFilterDescriptor != nil){
            if ((currFilterDescriptor?.numParameters)! == 0){
                filterControlsView.setParametersControlState(.disabled)
            } else {
                filterControlsView.setParametersControlState(.hidden)
            }
        }
        if (currFilterKey != nil) { editImageView.setFilter(key:currFilterKey!) }
        if (currCategory != nil) {
            categorySelectionView.setFilterCategory(currCategory!)
            filterSelectionView.setFilterCategory(currCategory!)
        }
    }
    
   
    
    
    // Management of the Filter Controls View

    fileprivate var filterControlsShown: Bool = false

    func hideFilterControls(){
        filterControlsView.isHidden = true
        filterControlsShown = false
    }
    
    
    func showFilterControls(){
        filterControlsView.isHidden = false
        filterControlsShown = true
    }
    
    func toggleFilterControls(){
        if (filterControlsShown){
            hideFilterControls()
        } else {
            showFilterControls()
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
        //updateCurrentFilter()
        categorySelectionView.isHidden = true
        categorySelectorShown = false
        filterControlsView.setCategoryControlState(.hidden)
    }
    
    func showCategorySelector(){
        //updateCurrentFilter()
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
        //updateCurrentFilter()
        filterSelectionView.isHidden = true
        filterSelectorShown = false
        filterControlsView.setFilterControlState(.hidden)
    }
    
    func showFilterSelector(){
        //updateCurrentFilter()
        if (currFilterDescriptor != nil){
            filterSelectionView.isHidden = false
            filterSelectorShown = true
            filterControlsView.setFilterControlState(.shown)
            filterSelectionView.setFilterCategory(currCategory!)
            filterSelectionView.update()
            view.bringSubview(toFront: filterSelectionView)
        } else {
            log.warning("WARN: current filter not set")
        }
    }
  
    
    
    // Management of Filter Parameters view
    fileprivate var filterSettingsShown: Bool = false
    
    fileprivate func showFilterSettings(){
        //updateCurrentFilter()
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
    
    
    
    
    
    //////////////////////////////////////////
    // MARK: - ImagePicker handling
    //////////////////////////////////////////

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let imageRefURL = info[UIImagePickerControllerReferenceURL] as? NSURL {
            log.verbose("Picked URL:\(imageRefURL)")
            //TODO: save image URL to folder
            ImageManager.setCurrentEditImageName(imageRefURL.absoluteString!)
            
            //update filtered image
            self.editImageView.updateImage()
            
        } else {
            log.error("Error accessing image URL")
        }
        picker.dismiss(animated: true)
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    
    
    
    
    
} // SimpleEditViewController
//########################






//////////////////////////////////////////
// MARK: - Delegate methods for sub-views
//////////////////////////////////////////


// EditControlsViewDelegate

fileprivate var callbacksEnabled = true

extension SimpleEditViewController: EditControlsViewDelegate {

    func changeImagePressed(){
        DispatchQueue.main.async(execute: { () -> Void in
            log.debug("imagePreview pressed - launching ImagePicker...")
            // launch an ImagePicker
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .photoLibrary
            
            self.present(self.imagePicker, animated: true, completion: nil)
        })
    }
    
    func changeFilterPressed(){
        toggleFilterControls()
    }
    
    func brightnessPressed(){
        
    }
    
    func exposurePressed(){
        
    }
    
    func warmthPressed(){
        
    }
    
    func whiteBalancePressed(){
        
    }
    
    func contrastPressed(){
        
    }
    
    func shadowsPressed(){
        
    }
    
    func highlightsPressed(){
        
    }
    
    func levelsPressed(){
        
    }
    
    func vibrancePressed(){
        
    }
    
    func saturationPressed(){
        
    }
    
    func sharpnessPressed(){
        
    }
    
    func vignettePressed(){
        
    }
    
    func rotatePressed(){
        
    }
    
    func cropPressed(){
        
    }
    
}




// FilterControlsViewDelegate

extension SimpleEditViewController: FilterControlsViewDelegate {
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

extension SimpleEditViewController: CategorySelectionViewDelegate {
    func categorySelected(_ category:String){
        
        guard (callbacksEnabled) else {
            log.info("Category Selected Callback ignored")
            return
        }
        
        changeCategoryTo(category)
    }
    
}


// FilterSelectionViewDelegate

extension SimpleEditViewController: FilterSelectionViewDelegate{
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
        
        changeFilterTo(key)
    }
}




