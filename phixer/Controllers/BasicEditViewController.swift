//
//  BasicEditViewController.swift
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

class BasicEditViewController: CoordinatedController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    // Main Display View
    var editImageView: EditImageDisplayView! = EditImageDisplayView()
    
    let editControlHeight = 96.0
    
    
    // Custom Menu view
    var menuView: AdornmentView! = AdornmentView()

    // The filter configuration subview
    var filterParametersView: FilterParametersView! = FilterParametersView()
    
    // image picker for changing edit image
    let imagePicker = UIImagePickerController()
    
    
    var currCategory:String? = nil
    var currFilterKey:String? = nil
    
    var currFilterDescriptor:FilterDescriptor? = nil
    var currIndex:Int = 0
    
    // var isLandscape : Bool = false // moved to base class
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    let bannerHeight : CGFloat = 64.0
    let buttonSize : CGFloat = 48.0
    fileprivate let statusBarOffset : CGFloat = 2.0
    
    var topBarHeight: CGFloat = 44.0
 
    // vars related to gestures/touches
    enum touchMode {
        case none
        case gestures
        case filter
        case preview
    }
    
    var currTouchMode:touchMode = .gestures
    
    
    
    /////////////////////////////
    // MARK: - Override Base Class functions
    /////////////////////////////
    
    // return the display title for this Controller
    override public func getTitle() -> String {
        return "Edit"
    }
    
    // return the name of the help file associated with this Controller (without extension)
    override public func getHelpKey() -> String {
        return "BasicEditor"
    }
    
    // do something if a filter was selected
    override func selectFilter(key: String){
        log.verbose("Change filter to: \(key)")
        DispatchQueue.main.async(execute: { () -> Void in
            //self.currFilterKey = ""
            self.changeFilterTo (key)
            self.editImageView.updateImage()
        })
    }
    
    // handle update of the UI
    override func updateDisplays() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.editImageView.updateImage()
        })
    }

    // handle the menu request. Return true if handled, false otherwise (base controller will handle it)
    override func handleMenu() {
        // if menu is hidden then re-layout and show it, otherwise hide it
        if self.menuView.isHidden == true {
            DispatchQueue.main.async(execute: { () -> Void in
                self.layoutMenu()
                self.menuView.isHidden = false
                self.filterParametersView.isHidden = true
            })
        } else {
            //log.debug("Menu active, closing")
            self.menuView.isHidden = true
            self.filterParametersView.isHidden = false
      }
    }

    
    /////////////////////////////
    // INIT
    /////////////////////////////
    

    
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        //doInit()
    }
    
    static var initDone:Bool = false
    
    func doInit(){
        
        // TODO: remeber edits?
        EditManager.reset()
        
        if (currFilterDescriptor == nil){
            currFilterDescriptor = filterManager.getFilterDescriptor(key: FilterDescriptor.nullFilter)
        }
        if currCategory == nil {
            currCategory = filterManager.getCurrentCategory()
        }
        
        if (!BasicEditViewController.initDone){
            BasicEditViewController.initDone = true
            log.verbose("init")
            
            filterManager.setCurrentCategory(FilterManager.defaultCategory)
            currFilterDescriptor = filterManager.getFilterDescriptor(key: FilterDescriptor.nullFilter)
            filterParametersView.setConfirmMode(true)
            filterParametersView.delegate = self
            //filterParametersView.setConfirmMode(false)
            
            filterManager.setCurrentFilterKey(FilterDescriptor.nullFilter)
            //editImageView.setFilter(key: FilterDescriptor.nullFilter)
            BasicEditViewController.initDone = true
            updateCurrentFilter()
            currTouchMode = .gestures
            
            filterParametersView.collapse()
            filterParametersView.isHidden = false
        }
    }
    
    
    open func suspend(){
        editImageView.suspend()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // common setup
        self.prepController()

        // get display dimensions
        displayHeight = view.height
        displayWidth = view.width
        
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        //filterManager.reset()
        doInit()
        
        checkPhotoAuth()

  
        // do layout
        
        menuView.frame.size.height = CGFloat(bannerHeight)
        menuView.frame.size.width = displayWidth
        layoutMenu()

        editImageView.frame.size.width = displayWidth
        editImageView.frame.size.height = displayHeight

        filterParametersView.frame.size.width = displayWidth
        filterParametersView.frame.size.height = bannerHeight // will be adjusted based on selected filter
 
        // Note: need to add subviews before modifying constraints
        view.addSubview(editImageView)
        view.addSubview(menuView)
        view.addSubview(filterParametersView)


        hideModalViews()

        // set layout constraints
        
        //TODO: layout frame so this is already taken into account
        topBarHeight = UIApplication.shared.statusBarFrame.size.height + (Coordinator.navigationController?.navigationBar.frame.height ?? 0.0)

        // top
        menuView.anchorAndFillEdge(.top, xPad: 0, yPad: topBarHeight, otherSize: menuView.frame.size.height)

        
        // main window
        //editImageView.anchorAndFillEdge(.top, xPad: 0, yPad: topBarHeight, otherSize: editImageView.frame.size.height)
        editImageView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: editImageView.frame.size.height)

        // filter parameters
        //filterParametersView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: filterParametersView.frame.size.height)
        filterParametersView.anchorAndFillEdge(.top, xPad: 0, yPad: topBarHeight, otherSize: filterParametersView.frame.size.height)

        // add delegate for image picker
        imagePicker.delegate = self
        
        // set gesture detection for the edit display view
        setGestureDetectors(view: editImageView)
        currTouchMode = .gestures
        
        // listen to key press events
        setVolumeListener()
        
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

 
    // these vars are global scope because they are updated asynchronously
    private var photoThumbnail:UIImage? = nil
    private var blendThumbnail:UIImage? = nil

    // layout the menu panel
    private func layoutMenu() {
        
        // update the photo and blend icons (they can change)
        loadPhotoThumbnail()
        loadBlendThumbnail()
        updateAdornments()
        
        menuView.addAdornments(itemList)
        menuView.delegate = self
        menuView.isHidden = true // start off as hidden
    }

    
    
    // set photo image to the last photo in the camera roll
    func loadPhotoThumbnail(){
        
        let tgtSize = CGSize(width: buttonSize, height: buttonSize)
        
        
        // get most recent photo
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        let last = fetchResult.lastObject
        
        if let lastAsset = last {
            let options = PHImageRequestOptions()
            options.version = .current
            
            PHImageManager.default().requestImage(
                for: lastAsset,
                targetSize: tgtSize,
                contentMode: .aspectFit,
                options: options,
                resultHandler: { image, _ in
                    DispatchQueue.main.async {
                        self.photoThumbnail = image
                    }
            })
        }
    }
    
    private func loadBlendThumbnail(){
        self.blendThumbnail = UIImage(ciImage: ImageManager.getCurrentBlendImage(size:CGSize(width: self.buttonSize, height: self.buttonSize))!)
    }
    
    //////////////////////////////////////
    // MARK: - Menu item handlers
    //////////////////////////////////////
    // build the list of adornments
    
    
    var itemList:[Adornment] = [ ]

    func updateAdornments(){
        
        // hide blend icon if this is not a blend filter
       let showBlend = (filterManager.getCurrentFilterDescriptor()?.filterOperationType == FilterOperationType.blend) ? false : true
        
        itemList = []
        itemList.append (Adornment(key: "photo", text: "photo", icon: "", view: photoThumbnail, isHidden: false))
        itemList.append (Adornment(key: "blend", text: "blend", icon: "", view: blendThumbnail, isHidden: showBlend))
        itemList.append (Adornment(key: "reset", text: "reset", icon: "ic_reset", view: nil, isHidden: false))
        itemList.append (Adornment(key: "undo", text: "undo", icon: "ic_undo", view: nil, isHidden: false))
        itemList.append (Adornment(key: "save", text: "save", icon: "ic_save", view: nil, isHidden: false))
        itemList.append (Adornment(key: "help", text: "help", icon: "ic_help", view: nil, isHidden: false))
    }
    
    func handleSelection(key: String){
        switch (key){
        case "photo":
            imageDidPress()
        case "blend":
            blendDidPress()
        case "reset":
            resetDidPress()
        case "undo":
            undoDidPress()
        case "save":
            saveDidPress()
        case "help":
            helpDidPress()
        default:
            log.error("Unknown key: \(key)")
        }
    }

    @objc func imageDidPress(){
        self.menuView.isHidden = true
        self.changeImage()
     }
    
    @objc func blendDidPress(){
        self.coordinator?.activateRequest(id: .blendGallery)
    }
    
    @objc func saveDidPress(){
        self.menuView.isHidden = true
        DispatchQueue.main.async(execute: { () -> Void in
            self.saveImage()
            log.verbose("Image saved")
            self.showMessage("Image saved to Photos")
        })
    }
    
    @objc func resetDidPress(){
        log.debug("reset")
       self.menuView.isHidden = true
        currFilterDescriptor?.reset()
        EditManager.reset()
        EditManager.addPreviewFilter(currFilterDescriptor)
        DispatchQueue.main.async(execute: { () -> Void in
            self.editImageView.updateImage()
      })
    }
    
    @objc func defaultDidPress(){
        self.menuView.isHidden = true
        currFilterDescriptor?.reset()
        DispatchQueue.main.async(execute: { () -> Void in
            self.editImageView.updateImage()
       })
    }

    @objc func undoDidPress(){
        log.debug("undo")
        // restore saved parameters
        currFilterDescriptor?.restoreParameters()
        EditManager.popFilter()
        DispatchQueue.main.async(execute: { () -> Void in
            self.editImageView.updateImage()
            //self.menuView.isHidden = true
        })
    }

    @objc func helpDidPress(){
        log.debug("help")
        DispatchQueue.main.async(execute: { () -> Void in
            self.coordinator?.helpRequest()
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
    // MARK: - Gesture Detection
    //////////////////////////////////////
    
    
    var gesturesEnabled:Bool = true
    
    func enableGestureDetection(){
        if !gesturesEnabled {
            gesturesEnabled = true
            editImageView.isUserInteractionEnabled = true
            filterParametersView.isHidden = false
            filterParametersView.isUserInteractionEnabled = true
            setTouchMode(.gestures)
        }
    }
    
    func disableGestureDetection(){
        if gesturesEnabled {
            gesturesEnabled = false
            editImageView.isUserInteractionEnabled = false
            filterParametersView.isHidden = true
        }
    }
    
    
    func setGestureDetectors(view: UIView){
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.swiped))
        swipeDown.direction = .down
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.swiped))
        swipeUp.direction = .up
        

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.swiped))
        swipeRight.direction = .right
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.swiped))
         swipeLeft.direction = .left
 
        
        // TODO: zoom/pan gestures

        for gesture in [swipeDown, swipeUp, swipeRight, swipeLeft] {
            gesture.cancelsTouchesInView = false // allows touch to trickle down to subviews
            //view.addGestureRecognizer(gesture)
            view.addGestureRecognizer(gesture)
            gesture.delegate = self
        }

    }
    
    
    @objc func swiped(_ gesture: UIGestureRecognizer) {
        // if gesturesEnabled {
        if currTouchMode == .gestures {
            if let swipeGesture = gesture as? UISwipeGestureRecognizer {
                switch swipeGesture.direction {
                    
                case UISwipeGestureRecognizerDirection.right:
                    //log.verbose("Swiped Right")
                    self.coordinator?.nextItemRequest()
                    break
                    
                case UISwipeGestureRecognizerDirection.left:
                    //log.verbose("Swiped Left")
                    self.coordinator?.previousItemRequest()
                   break
                    
                case UISwipeGestureRecognizerDirection.up:
                    //log.verbose("Swiped Up")
                    showModalViews()
                    //optionsController?.show()
                    //showFilterSettings()
                    break
                    
                case UISwipeGestureRecognizerDirection.down:
                    //hideFilterSettings()
                    hideModalViews()
                    //optionsController?.hide()
                    //log.verbose("Swiped Down")
                    break
                    
                default:
                    log.debug("Unhandled gesture direction: \(swipeGesture.direction)")
                    break
                }
            } else {
                // still allow up/down
                if let swipeGesture = gesture as? UISwipeGestureRecognizer {
                    if swipeGesture.direction == UISwipeGestureRecognizerDirection.up {
                        showFilterSettings()
                    } else if swipeGesture.direction == UISwipeGestureRecognizerDirection.down {
                        hideFilterSettings()
                    }
                }
            }
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
    
    func showMessage(_ msg:String, time:TimeInterval=1.0){
        if !msg.isEmpty {
            DispatchQueue.main.async(execute: { () -> Void in
                let alert = UIAlertController(title: "", message: msg, preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
                Timer.scheduledTimer(withTimeInterval: time, repeats: false, block: { _ in alert.dismiss(animated: true, completion: nil)} )
            })
        }
    }
    
    //////////////////////////////////////
    // Management of modal views
    //////////////////////////////////////
    
    // list of views that have been hidden through user interaction (e.g. swip down)
    
    private var hiddenViewList:[UIView?] = []
    
    // convenience function to hide all modal views
    func hideModalViews(){
        
        self.coordinator?.hideSubcontrollersRequest()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // go through the modal views and hide them if they are not already hidden
        // NOTE: if any more modal views are added, remmber to add them this list
        for view in [ menuView ] {
            if let v = view {
                if !v.isHidden {
                    // add to the list so that they will be restored later
                    hiddenViewList.append(v)
                    v.isHidden = true
                }
            }
        }
        
        filterParametersView.collapse()
        filterParametersView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: filterParametersView.frame.size.height)

    }
    
    
    // function to restore all modal views that were previously hidden
    func showModalViews() {
        
        self.coordinator?.showSubcontrollersRequest()
        self.navigationController?.setNavigationBarHidden(false, animated: false)

        // for other views, use the hidden list
        if hiddenViewList.count > 0 {
            for view in hiddenViewList {
                if let v = view {
                    v.isHidden = false
                }
                hiddenViewList = []
            }
        }
        
        if filterParametersView.numVisibleParams > 0 {
            filterParametersView.expand()
            self.view.bringSubview(toFront: filterParametersView)
            filterParametersView.setNeedsDisplay()
        }
        filterParametersView.anchorAndFillEdge(.top, xPad: 0, yPad: topBarHeight, otherSize: filterParametersView.frame.size.height)

    }
    

    
    //////////////////////////////////////
    // MARK: - Filter Management
    //////////////////////////////////////
    
    
    
    func changeFilterTo(_ key:String){
        //TODO: make user accept changes before applying? (Add buttons to parameter display)
        // setup the filter descriptor
        //if (key != filterManager.getCurrentFilterKey()){
        if (key != currFilterKey){
            log.debug("Filter Selected: \(key)")
            currFilterKey = key
            filterManager.setCurrentFilterKey(key)
            currFilterDescriptor = filterManager.getFilterDescriptor(key:key)
            updateCurrentFilter()
        } else {
            // something other than the filter changed
            self.editImageView.updateImage()
        }
        self.showFilterSettings()
   }
    
    
    func filterChanged(){
        updateCurrentFilter()
    }
    
    // retrive current settings from FilterManager and store locally
    func updateCurrentFilter(){
        if (currFilterKey != nil) {
            editImageView.setFilter(key:currFilterKey!)
            filterParametersView.setFilter(currFilterDescriptor)
        }
    }
    
    
    
    
    // Management of Filter Parameters view
    fileprivate var filterSettingsShown: Bool = false
    
    fileprivate func showFilterSettings(){
        //self.coordinator?.hideSubcontrollersRequest()
        if (currFilterDescriptor != nil) {
            filterParametersView.isHidden = false
            filterParametersView.expand()
        }
    }
    
    fileprivate func hideFilterSettings(){
        self.coordinator?.showSubcontrollersRequest()
        //filterParametersView.isHidden = true
        filterSettingsShown = false
        filterParametersView.collapse()
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
            //InputSource.setCurrent(source: .edit)
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
    // MARK: - Position handling
    //////////////////////////////////////////
    
    
    // Note: general gestures are disabled while position tracking is active. Too confusing if we don't do this
    
    var touchKey:String = ""
    
    func setTouchMode(_ mode:touchMode){
        self.currTouchMode = mode
        if self.currTouchMode == .gestures {
            enableGestureDetection()
        } else {
            disableGestureDetection()
        }
    }
    
    
    func handlePositionRequest(key:String){
        if !key.isEmpty{
            log.verbose("Position Request for parameter: \(key)")
            disableGestureDetection()
            touchKey = key
            setTouchMode(.filter)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.currTouchMode != .gestures {
            if let touch = touches.first {
                let position = touch.location(in: editImageView)
                //log.debug("\(position)")
                let imgPos = editImageView.getImagePosition(viewPos:position)
                if currTouchMode == .filter {
                    currFilterDescriptor?.setPositionParameter(touchKey, position:imgPos!)
                } else if currTouchMode == .preview {
                    editImageView.setSplitPosition(position)
                }
                editImageView.runFilter()
            }
        }
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.currTouchMode != .gestures {
            if let touch = touches.first {
                let position = touch.location(in: editImageView)
                let imgPos = editImageView.getImagePosition(viewPos:position)
                if currTouchMode == .filter {
                    currFilterDescriptor?.setPositionParameter(touchKey, position:imgPos!)
                } else if currTouchMode == .preview {
                    editImageView.setSplitPosition(position)
                }
                editImageView.runFilter()
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.currTouchMode != .gestures {
            if let touch = touches.first {
                let position = touch.location(in: editImageView)
                let imgPos = editImageView.getImagePosition(viewPos:position)
                if currTouchMode == .filter {
                    currFilterDescriptor?.setPositionParameter(touchKey, position:imgPos!)
                } else if currTouchMode == .preview {
                    editImageView.setSplitPosition(position)
                }
                //log.verbose("Touches ended. Final pos:\(position) vec:\(imgPos)")
                editImageView.runFilter()
                
                touchKey = ""
            }
            
            enableGestureDetection()
        }
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
    

    
} // BasicEditViewController
//########################






//////////////////////////////////////////
// MARK: - Delegate methods for sub-views
//////////////////////////////////////////



// Interfaces to the FilterParameters view

extension BasicEditViewController: FilterParametersViewDelegate {

    func commitChanges(key: String) {
        log.verbose("\(self.getTag()): \(key)")
        // make the change permanent
        DispatchQueue.main.async(execute: { () -> Void in
            EditManager.savePreviewFilter()
            self.showMessage("Effect applied", time:0.5)
            self.editImageView.updateImage()
            self.hideModalViews()
            self.coordinator?.showSubcontrollersRequest()
       })
    }
    
    func cancelChanges(key: String) {
        log.verbose("\(self.getTag()): \(key)")
        // restore saved parameters
        currFilterDescriptor?.restoreParameters()
        EditManager.popFilter()
        self.hideModalViews()
        DispatchQueue.main.async(execute: { () -> Void in
            self.editImageView.updateImage()
            self.coordinator?.showSubcontrollersRequest()
         })
    }
    
    
    func settingsChanged(){
        //log.debug("Filter settings changed")
        self.editImageView.updateImage()
    }
    
    func positionRequested(key: String) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.setTouchMode(.filter)
            self.handlePositionRequest(key:key)
        })
    }
    
    func fullScreenRequested() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.editImageView.setDisplayMode(.full)
            self.editImageView.updateImage()
            self.setTouchMode(.gestures)
        })
    }
    
    func splitScreenrequested() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.editImageView.setDisplayMode(.split)
            self.editImageView.updateImage()
            self.setTouchMode(.preview)
        })
    }
    
    func showFiltersRequested() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.editImageView.setFilterMode(.preview)
            self.editImageView.updateImage()
        })
    }
    
    func showOriginalRequested() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.editImageView.setFilterMode(.original)
            self.editImageView.updateImage()
            self.setTouchMode(.gestures)
        })
    }
    
}



// Adornment delegate

extension BasicEditViewController: AdornmentDelegate {
    func adornmentItemSelected(key: String) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.handleSelection(key: key)
        })
    }
}

// gesture tweaking

extension BasicEditViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if let touchedView = touch.view, touchedView.isKind(of: UISlider.self) {
            return false
        }
        
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer)
        -> Bool {
            // If the gesture recognizer's view isn't one of the squares, do not allow simultaneous recognition.
            if gestureRecognizer.view != self.editImageView {
                return false
            }
            // If the gesture recognizers are on diferent views, do not allow simultaneous recognition.
            if gestureRecognizer.view != otherGestureRecognizer.view {
                return false
            }
            // If either gesture recognizer is a long press, do not allow simultaneous recognition.
            if gestureRecognizer is UILongPressGestureRecognizer ||
                otherGestureRecognizer is UILongPressGestureRecognizer {
                return false
            }
            
            return true
    }
}

