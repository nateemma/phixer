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
import Photos

import GoogleMobileAds



private var filterList: [String] = []
private var filterCount: Int = 0

// This View Controller handles simple editing of a photo

class SimpleEditViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var theme = ThemeManager.currentTheme()
    
    
    
    // Banner/Navigation View (title)
    fileprivate var bannerView: TitleView! = TitleView()
    
    
    // Main Display View
    var editImageView: EditImageDisplayView! = EditImageDisplayView()
    
    // Views for holding the (modal) overlays. Note: must come after EditImageDisplayView()
    var filterControlsView : FilterControlsView! = FilterControlsView()
    
    // The Edit controls/options
    var editControlsView: EditControlsView! = EditControlsView()
    
    // Accept/Undo controls
    var applyView:UIView! = UIView()
    
    // Image Selection (& save) view
    var imageSelectionView: ImageSelectionView! = ImageSelectionView()
    
    // The filter configuration subview
    var filterParametersView: FilterParametersView! = FilterParametersView()
    
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
        if currCategory == nil {
            currCategory = filterManager?.getCurrentCategory()
        }
        
        if (!SimpleEditViewController.initDone){
            SimpleEditViewController.initDone = true
            log.verbose("init")
            
            filterManager?.setCurrentCategory("none")
            currFilterDescriptor = filterManager?.getFilterDescriptor(key: "NoFilter")
            filterSelectionView.setInputSource(.photo)
            //filterParametersView.setConfirmMode(true)
            filterParametersView.setConfirmMode(false)
            categorySelectionView.setFilterCategory("none")
            editImageView.setFilter(key: "NoFilter")
            SimpleEditViewController.initDone = true
            populateFilterList()
            updateCurrentFilter()
        }
    }
    
    
    open func suspend(){
        editImageView.suspend()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Logging nicety, show that controller has changed:
        print ("\n========== \(String(describing: self)) ==========")

        // load theme here in case it changed
        theme = ThemeManager.currentTheme()
        
        view.backgroundColor = theme.backgroundColor
        
        // get display dimensions
        displayHeight = view.height
        displayWidth = view.width
        
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        // get orientation
        //isLandscape = UIDevice.current.orientation.isLandscape // doesn't always work properly, especially in simulator
        isLandscape = (displayWidth > displayHeight)
        
        //filterManager?.reset()
        doInit()
        
        checkPhotoAuth()

        
        // set up layout based on orientation
        
        layoutBanner()
        
        
        // Only Portrait mode supported (for now)
        // TODO: add landscape mode
        
        layoutAcceptView()
        
        imageSelectionView.frame.size.height = CGFloat(bannerHeight)
        imageSelectionView.frame.size.width = displayWidth

        editImageView.frame.size.width = displayWidth
        editImageView.frame.size.height = displayHeight - bannerView.frame.size.height - CGFloat(editControlHeight)
        
        editControlsView.frame.size.height = CGFloat(editControlHeight)
        editControlsView.frame.size.width = displayWidth

        filterControlsView.frame.size.height = bannerHeight * 0.5
        filterControlsView.frame.size.width = displayWidth
        
        filterSelectionView.frame.size.height = 1.7 * bannerHeight
        filterSelectionView.frame.size.width = displayWidth
        
        categorySelectionView.frame.size.height = 1.7 * bannerHeight
        categorySelectionView.frame.size.width = displayWidth
        
        filterParametersView.frame.size.width = displayWidth
        filterParametersView.frame.size.height = bannerHeight // will be adjusted based on selected filter
        
        
        // Note: need to add subviews before modifying constraints
        view.addSubview(bannerView)
        //view.addSubview(filterInfoView)
        view.addSubview(editImageView)
        view.addSubview(editControlsView)
        view.addSubview(applyView)
        view.addSubview(imageSelectionView)
        
        // hidden views:
        view.addSubview(filterControlsView) // must come after editImageView
        view.addSubview(filterSelectionView)
        view.addSubview(categorySelectionView)
        view.addSubview(filterParametersView)
        
        hideModalViews()

        // set layout constraints
        
        // top
        bannerView.anchorAndFillEdge(.top, xPad: 0, yPad: statusBarOffset/2.0, otherSize: bannerView.frame.size.height)
        
        imageSelectionView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: imageSelectionView.frame.size.height)
        
        applyView.align(.underCentered, relativeTo: imageSelectionView, padding: 0, width: applyView.frame.size.width, height: applyView.frame.size.height)
        
        // main window
        editImageView.align(.underCentered, relativeTo: imageSelectionView, padding: 0, width: displayWidth, height: editImageView.frame.size.height)
        
        // bottom
        editControlsView.anchorToEdge(.bottom, padding: 0, width: displayWidth, height: editControlsView.frame.size.height)
        
        filterControlsView.align(.aboveCentered, relativeTo: editControlsView, padding: 0, width: displayWidth, height: filterControlsView.frame.size.height)
        
        filterSelectionView.align(.aboveCentered, relativeTo: filterControlsView, padding: 0, width: filterSelectionView.frame.size.width, height: filterSelectionView.frame.size.height)
        
        categorySelectionView.align(.aboveCentered, relativeTo: filterControlsView, padding: 0,
                                    width: categorySelectionView.frame.size.width, height: categorySelectionView.frame.size.height)
        
        filterParametersView.align(.aboveCentered, relativeTo: filterControlsView, padding: 4,
                                   width: filterParametersView.frame.size.width, height: filterParametersView.frame.size.height)

        
        // add delegates to sub-views (for callbacks)
        editControlsView.delegate = self
        imageSelectionView.delegate = self
        filterControlsView.delegate = self
        filterSelectionView.delegate = self
        categorySelectionView.delegate = self
        imagePicker.delegate = self
        
        
        // set gesture detection for the edit display view
        setGestureDetectors(view: editImageView)
        
        
        // listen to key press events
        setVolumeListener()
        
        
        //TODO: select filter category somehow
        //filterSelectionView.setFilterCategory(String.favorites)
        
        filterSelectionView.setInputSource(.photo)
        
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
    
    private func checkPhotoAuth() {
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization({ (status) in
                if status == .authorized {
                    log.debug("Photo access granted")
                } else {
                    log.warning("Photo access NOT granted")
                }
            })
            
        }
    }
    
    //////////////////////////////////////
    // MARK: - Sub-View layout
    //////////////////////////////////////

    
    // layout the banner view, with the Back button, title etc.
    func layoutBanner(){
        bannerView.frame.size.height = bannerHeight * 0.75
        bannerView.frame.size.width = displayWidth
        bannerView.title = "\'Simple\' Photo Editor"
        bannerView.delegate = self
    }
    
    func layoutAcceptView() {
        
        let acceptButton: UIButton! = UIButton()
        let undoButton: UIButton! = UIButton()

        let aHeight = CGFloat(bannerHeight)
        
        //applyView.backgroundColor = theme.backgroundColor
        applyView.backgroundColor = UIColor.clear

        applyView.frame.size.width = (displayWidth - 16.0).rounded()
        applyView.frame.size.height = aHeight
        
        for b in [acceptButton, undoButton] {
            b?.backgroundColor = theme.buttonColor.withAlphaComponent(0.75)
            b?.titleLabel?.textColor = theme.textColor
            b?.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            b?.titleLabel?.textAlignment = .center
            b?.frame.size.width = (aHeight*2).rounded()
            b?.frame.size.height = (aHeight*0.75).rounded()
        }
        
        acceptButton.setTitle("Apply", for: .normal)
        undoButton.setTitle("Undo", for: .normal)
        
        
        applyView.addSubview(acceptButton)
        applyView.addSubview(undoButton)
        
        let pad = (applyView.frame.size.height - acceptButton.frame.size.height) / 2
        //applyView.groupAndFill(group: .horizontal, views: [acceptButton, defaultButton, undoButton], padding: pad)
        //applyView.groupAgainstEdge(group: .horizontal, views: [acceptButton, undoButton], againstEdge: .bottom, padding: 0,
        //                            width: acceptButton.frame.size.width, height: acceptButton.frame.size.height)
        applyView.groupInCenter(group: .horizontal, views: [acceptButton, undoButton], padding: pad,
                                width: acceptButton.frame.size.width, height: acceptButton.frame.size.height)

                
        // register handlers for the buttons
        acceptButton.addTarget(self, action: #selector(self.acceptDidPress), for: .touchUpInside)
        undoButton.addTarget(self, action: #selector(self.undoDidPress), for: .touchUpInside)
    }

    
    @objc func acceptDidPress() {
        
        // make the change permanent
        EditManager.savePreviewFilter()
    }
    
    @objc func defaultDidPress(){
        currFilterDescriptor?.reset()
        DispatchQueue.main.async(execute: { () -> Void in
            self.editImageView.updateImage()
        })
   }
    
    @objc func undoDidPress(){
        // restore saved parameters
        currFilterDescriptor?.restoreParameters()
        EditManager.popFilter()
        DispatchQueue.main.async(execute: { () -> Void in
            self.editImageView.updateImage()
        })
   }
    
    
    //////////////////////////////////////
    // MARK: - Volume buttons
    //////////////////////////////////////
    
    
    func setVolumeListener() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryAmbient, mode: AVAudioSessionModeDefault, options: [])
            try audioSession.setActive(true, with: [])
            audioSession.addObserver(self, forKeyPath: "outputVolume", options: NSKeyValueObservingOptions(), context: nil)
        } catch {
            log.error("\(error)")
        }
        
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

        let oldIndex = currIndex
        let oldKey = filterList[currIndex]
        currIndex = (currIndex + 1) % filterList.count
        let key = filterList[currIndex]
        
        log.debug("Changing filter: \(oldKey)(\(oldIndex))->\(key)(\(index))")
        changeFilterTo(key)
    }
    
    
    fileprivate func previousFilter(){
        
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
        editImageView.saveImage()
        playCameraSound()
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
        //TODO: make user accept changes before applying? (Add buttons to parameter display)
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
    
    
    // convenience function to hide all modal views
    func hideModalViews(){
        filterControlsView.isHidden = true
        filterSelectionView.isHidden = true
        categorySelectionView.isHidden = true
        filterParametersView.isHidden = true
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
            if currCategory == nil {
                currCategory = filterManager?.getCurrentCategory()
            }
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
            filterParametersView.frame.size.height = CGFloat(((currFilterDescriptor?.numParameters)! + 1)) * bannerHeight * 0.75
            if (isLandscape){
                filterParametersView.anchorInCorner(.bottomLeft, xPad: 0, yPad: 0, width: filterParametersView.frame.size.width, height: filterParametersView.frame.size.height)
            } else {
                filterParametersView.align(.aboveCentered, relativeTo: filterControlsView, padding: 4, width: filterParametersView.frame.size.width, height: filterParametersView.frame.size.height)
            }
            
            filterParametersView.setFilter(currFilterDescriptor)
            
            //filterParametersView.align(.aboveCentered, relativeTo: filterControlsView, padding: 4, width: filterParametersView.frame.size.width, height: filterParametersView.frame.size.height)
            filterParametersView.isHidden = false
            filterSettingsShown = true
            view.bringSubview(toFront: filterParametersView)
            filterControlsView.setParametersControlState(.shown)
            //filterParametersView.show()
        } else {
            log.debug("No parameters to display")
            filterControlsView.setParametersControlState(.disabled)
            hideFilterSettings()
        }
    }
    
    fileprivate func hideFilterSettings(){
        filterParametersView.dismiss()
        filterParametersView.isHidden = true
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
    
    func changeImage(){
        DispatchQueue.main.async(execute: { () -> Void in
            log.debug("imagePreview pressed - launching ImagePicker...")
            // launch an ImagePicker
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .photoLibrary
            
            self.present(self.imagePicker, animated: true, completion: {
            })
        })
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        if let asset = info[UIImagePickerControllerPHAsset] as? PHAsset {
            let assetResources = PHAssetResource.assetResources(for: asset)
            let name = assetResources.first!.originalFilename
            let id = assetResources.first!.assetLocalIdentifier
            
            log.verbose("Picked image:\(name) id:\(id)")
            ImageManager.setCurrentEditImageName(id)
            DispatchQueue.main.async(execute: { () -> Void in
                self.editImageView.updateImage()
            })
        } else {
            log.error("Error accessing image data")
        }
        picker.dismiss(animated: true)
        
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    
    
    
    //////////////////////////////////////////
    // MARK: - Not yet implemented notifier
    //////////////////////////////////////////
    
    func notYetImplemented(){
        DispatchQueue.main.async(execute: { () -> Void in
            let alert = UIAlertController(title: "Oops!", message: "Not yet implemented. Sorry!", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { _ in alert.dismiss(animated: true, completion: nil)} )
        })
    }
    
    
} // SimpleEditViewController
//########################






//////////////////////////////////////////
// MARK: - Delegate methods for sub-views
//////////////////////////////////////////


// EditControlsViewDelegate

fileprivate var callbacksEnabled = true

extension SimpleEditViewController: EditControlsViewDelegate {
    
    
    func changeFilterPressed(){
        hideModalViews()
        toggleFilterControls()
    }
    
    func brightnessPressed(){
        hideModalViews()
        notYetImplemented()
    }
    
    func exposurePressed(){
        hideModalViews()
        notYetImplemented()
    }
    
    func warmthPressed(){
        hideModalViews()
        notYetImplemented()
    }
    
    func whiteBalancePressed(){
        hideModalViews()
        notYetImplemented()
    }
    
    func contrastPressed(){
        hideModalViews()
        notYetImplemented()
    }
    
    func shadowsPressed(){
        hideModalViews()
        notYetImplemented()
    }
    
    func highlightsPressed(){
        hideModalViews()
        notYetImplemented()
    }
    
    func levelsPressed(){
        hideModalViews()
        notYetImplemented()
    }
    
    func vibrancePressed(){
        hideModalViews()
        notYetImplemented()
    }
    
    
    func saturationPressed(){
        hideModalViews()
        notYetImplemented()
    }
    
    func sharpnessPressed(){
        hideModalViews()
        notYetImplemented()
    }
    
    func vignettePressed(){
        hideModalViews()
        notYetImplemented()
    }
    
    func rotatePressed(){
        hideModalViews()
        notYetImplemented()
    }
    
    func cropPressed(){
        hideModalViews()
        notYetImplemented()
    }
    
}




// FilterControlsViewDelegate

extension SimpleEditViewController: FilterControlsViewDelegate {
    func categoryPressed(){
        log.debug("Show/Hide Categories pressed")
        callbacksEnabled = true
        hideModalViews()
        toggleCategoryState()
    }
    func filterPressed(){
        callbacksEnabled = true
        log.debug("Show/Hide Filters pressed")
        hideModalViews()
        toggleFilterState()
    }
    
    func filterParametersPressed(){
        callbacksEnabled = true
        log.debug("Show/Hide Filter Settings pressed")
        hideModalViews()
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


// TitleViewDelegate
extension SimpleEditViewController: TitleViewDelegate {
    func backPressed() {
        backDidPress()
    }
}

// ImageSelectionViewDelegate
extension SimpleEditViewController: ImageSelectionViewDelegate {
    
    func changeImagePressed(){
        self.changeImage()
        DispatchQueue.main.async(execute: { () -> Void in
            self.imageSelectionView.update()
        })
    }

    func changeBlendPressed() {
        let vc = BlendGalleryViewController()
        vc.delegate = self
        self.present(vc, animated: true, completion: {
            DispatchQueue.main.async(execute: { () -> Void in
                self.imageSelectionView.update()
                log.verbose("Blend image changed")
            })
        })

    }
    
    func savePressed() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.saveImage()
            log.verbose("Image saved")
            self.imageSelectionView.update()
        })
    }
    
}

// BlendGalleryViewControllerDelegate
extension SimpleEditViewController: BlendGalleryViewControllerDelegate {
    func blendGalleryCompleted() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.imageSelectionView.update()
            log.verbose("Blend image changed")
        })
    }
}


