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
    var currFilterKey:String? = FilterDescriptor.nullFilter
    
    var currFilterDescriptor:FilterDescriptor? = nil
    var currIndex:Int = 0
    
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    
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
        DispatchQueue.main.async { [weak self] in
            //self?.currFilterKey = ""
            self?.changeFilterTo (key)
            self?.editImageView.updateImage()
        }
    }
    
    // handle update of the UI
    override func updateDisplays() {
        log.verbose("updating")
        DispatchQueue.main.async { [weak self] in
            self?.editImageView.updateImage()
            self?.filterParametersView.update()
        }
    }
    
    // handle the menu request. Return true if handled, false otherwise (base controller will handle it)
    override func handleMenu() {
        // if menu is hidden then re-layout and show it, otherwise hide it
        if self.menuView.isHidden == true {
            DispatchQueue.main.async { [weak self] in
                self?.layoutMenu()
                self?.menuView.isHidden = false
                self?.filterParametersView.isHidden = true
            }
        } else {
            //log.debug("Menu active, closing")
            self.menuView.isHidden = true
            self.filterParametersView.isHidden = false
        }
    }
    
    // handle the end request. Check to see if there is anything to save before exiting
    override func end() {
        log.debug("Checking applied filters")
        if EditManager.getAppliedCount() <= 0 {
            self.dismiss()
        } else {
            displayUnsavedFiltersAlert()
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
            editImageView.setFilter(key: FilterDescriptor.nullFilter)
            BasicEditViewController.initDone = true
            updateCurrentFilter()
            currTouchMode = .gestures
            
            filterParametersView.collapse()
            filterParametersView.isHidden = false
            
            FaceDetection.reset()

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
        
        log.verbose("h:\(displayHeight) w:\(displayWidth) frame:\(self.view.frame)")
        
        //filterManager.reset()
        doInit()
        
        checkPhotoAuth()
        
        // TMP DBG
        //ImageManager.listAllAlbums()
        //ImageManager.listPhotoAlbum("All Photos")
        
        // do layout
        
        menuView.frame.size.height = CGFloat(UISettings.panelHeight)
        menuView.frame.size.width = displayWidth
        layoutMenu()
        
        editImageView.frame.size.width = displayWidth
        editImageView.frame.size.height = displayHeight
        
        filterParametersView.frame.size.width = displayWidth
        filterParametersView.frame.size.height = UISettings.panelHeight // will be adjusted based on selected filter
        
        // Note: need to add subviews before modifying constraints
        view.addSubview(editImageView)
        view.addSubview(menuView)
        view.addSubview(filterParametersView)
        
        
        showModalViews()
        
        // set layout constraints
        
        // top
        menuView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: menuView.frame.size.height)
        
        
        // main window
        //editImageView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: editImageView.frame.size.height)
        //editImageView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: editImageView.frame.size.height)
        editImageView.fillSuperview()
        
        // filter parameters
        //filterParametersView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: filterParametersView.frame.size.height)
        filterParametersView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: filterParametersView.frame.size.height)
        
        // add delegate for image picker
        imagePicker.delegate = self
        
        // set gesture detection for the edit display view
        setGestureDetectors(view: editImageView)
        currTouchMode = .gestures
        
        // listen to key press events
        setVolumeListener()
        
        // bit of a hack, but reset face detection if image changes. This allows results to be re-used across filters, which is a very expensive operation
        DispatchQueue.main.async {  [weak self] in
            FaceDetection.reset()
            FaceDetection.detectFaces(on: EditManager.getPreviewImage()!, orientation: ImageManager.getEditImageOrientation(), completion: {})
        }

    }
    
    
    
    private func checkPhotoAuth() {
        //PHPhotoLibrary.shared().register(self)
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization({ (status) in
                if status == .authorized {
                    log.debug("Photo access granted")
                } else {
                    log.warning("Photo access NOT granted")
                }
            })
            
        } else {
            log.verbose("Photo library access OK")
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
        
        let tgtSize = CGSize(width: UISettings.buttonSide, height: UISettings.buttonSide)
        
        
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
        self.blendThumbnail = UIImage(ciImage: ImageManager.getCurrentBlendImage(size:UISettings.buttonSize)!)
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
        itemList.append (Adornment(key: "help", text: "help", icon: "ic_info", view: nil, isHidden: false))
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
        DispatchQueue.main.async { [weak self] in
            if EditManager.isPreviewActive() {
                self?.displayPreviewAlert()
            } else {
                self?.saveImage()
                log.verbose("Image saved")
                self?.showMessage("Image saved to Photos")
            }
        }
    }
    
    @objc func resetDidPress(){
        log.debug("reset")
        self.menuView.isHidden = true
        currFilterDescriptor?.reset()
        EditManager.reset()
        EditManager.addPreviewFilter(currFilterDescriptor)
        DispatchQueue.main.async { [weak self] in
            self?.editImageView.updateImage()
            self?.filterParametersView.update()
            self?.menuView.isHidden = true
        }
    }
    
    @objc func defaultDidPress(){
        self.menuView.isHidden = true
        currFilterDescriptor?.reset()
        DispatchQueue.main.async { [weak self] in
            self?.editImageView.updateImage()
            self?.filterParametersView.update()
            self?.menuView.isHidden = true
        }
    }
    
    @objc func undoDidPress(){
        log.debug("undo")
        // restore saved parameters
        currFilterDescriptor?.restoreParameters()
        EditManager.popFilter()
        DispatchQueue.main.async { [weak self] in
            self?.editImageView.updateImage()
            self?.filterParametersView.update()
            self?.menuView.isHidden = true
        }
    }
    
    @objc func helpDidPress(){
        log.debug("help")
        DispatchQueue.main.async { [weak self] in
            self?.coordinator?.helpRequest()
            self?.menuView.isHidden = true
        }
    }
    
    //////////////////////////////////////
    // MARK: - Volume buttons
    //////////////////////////////////////
    
    
    func setVolumeListener() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.ambient, mode: AVAudioSession.Mode.default, options: [])
            try audioSession.setActive(true, options: [])
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
    // MARK: - Save Applied filters alert processing
    //////////////////////////////////////
    
    
    fileprivate var savePhotoAlert:UIAlertController? = nil
    
    private func displayUnsavedFiltersAlert() {
        
        
        // build the alert if first time
        if (savePhotoAlert == nil){
            savePhotoAlert = UIAlertController(title: "Are You Sure?",
                                               message:"Did you want to save your edited photo before leaving this screen?\n" +
                "If you leave, the filters will be lost",
                                               preferredStyle: .alert)
            
            // add the OK button
            let okAction = UIAlertAction(title: "Leave", style: .default) { (action:UIAlertAction) in
                log.debug("Leaving")
                self.dismiss()
            }
            savePhotoAlert?.addAction(okAction)
            
            // add the Cancel Button
            let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action:UIAlertAction) in
                log.debug("Cancel")
            }
            savePhotoAlert?.addAction(cancelAction)
            
        }
        
        // display the dialog
        DispatchQueue.main.async { [weak self] in
            self?.present((self?.savePhotoAlert)!, animated: true, completion:nil)
        }
        
        
    }
    
    
    
    //////////////////////////////////////
    // MARK: - Apply Preview alert processing
    //////////////////////////////////////
    
    
    fileprivate var applyPreviewAlert:UIAlertController? = nil
    
    private func displayPreviewAlert() {
        
        
        // build the alert if first time
        if (applyPreviewAlert == nil){
            applyPreviewAlert = UIAlertController(title: "Preview Not Applied",
                                                  message:"There is a Preview effect that has not been applied.\n" +
                "Did you want to include this in the Saved image?",
                                                  preferredStyle: .alert)
            
            // add the OK button
            let okAction = UIAlertAction(title: "Apply", style: .default) { (action:UIAlertAction) in
                log.debug("Apply Preview")
                EditManager.savePreviewFilter()
                self.editImageView.updateImage()
                self.saveImage()
            }
            applyPreviewAlert?.addAction(okAction)
            
            // add the Cancel Button
            let cancelAction = UIAlertAction(title: "Ignore", style: .default) { (action:UIAlertAction) in
                log.debug("Ignore")
                EditManager.removePreviewFilter()
                self.editImageView.updateImage()
                self.saveImage()
            }
            applyPreviewAlert?.addAction(cancelAction)
            
        }
        
        // display the dialog
        DispatchQueue.main.async { [weak self] in
            self?.present((self?.applyPreviewAlert)!, animated: true, completion:nil)
        }
        
        
    }
    
    
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
            //filterParametersView.isHidden = true
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
            view.addGestureRecognizer(gesture)
            gesture.delegate = self
        }
        
    }
    
    
    @objc func swiped(_ gesture: UIGestureRecognizer) {
        if !self.editImageView.isZoomed() {
            // if gesturesEnabled {
            if currTouchMode == .gestures {
                if let swipeGesture = gesture as? UISwipeGestureRecognizer {
                    switch swipeGesture.direction {
                        
                    case UISwipeGestureRecognizer.Direction.right:
                        //log.verbose("Swiped Right")
                        self.coordinator?.nextItemRequest()
                        break
                        
                    case UISwipeGestureRecognizer.Direction.left:
                        //log.verbose("Swiped Left")
                        self.coordinator?.previousItemRequest()
                        break
                        
                    case UISwipeGestureRecognizer.Direction.up:
                        //log.verbose("Swiped Up")
                        //showModalViews()
                        toggleModalViews()
                        break
                        
                    case UISwipeGestureRecognizer.Direction.down:
                        //hideModalViews()
                        toggleModalViews()
                        //log.verbose("Swiped Down")
                        break
                        
                    default:
                        log.debug("Unhandled gesture direction: \(swipeGesture.direction)")
                        break
                    }
                } else {
                    // still allow up/down
                    if let swipeGesture = gesture as? UISwipeGestureRecognizer {
                        if (swipeGesture.direction == UISwipeGestureRecognizer.Direction.up) ||
                            (swipeGesture.direction == UISwipeGestureRecognizer.Direction.down) {
                            toggleModalViews()
                        }
                    }
                }
            }
        } else {
            log.verbose("Image zoomed, ignoring swipe gesture")
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
            DispatchQueue.main.async { [weak self] in
                let alert = UIAlertController(title: "", message: msg, preferredStyle: .alert)
                self?.present(alert, animated: true, completion: nil)
                Timer.scheduledTimer(withTimeInterval: time, repeats: false, block: { _ in alert.dismiss(animated: true, completion: nil)} )
            }
        }
    }
    
    //////////////////////////////////////
    // Management of modal views
    //////////////////////////////////////
    
    // list of views that have been hidden through user interaction (e.g. swip down)
    
    private var hiddenViewList:[UIView?] = []
    
    // convenience function to hide all modal views
    func hideModalViews(){
        DispatchQueue.main.async { [weak self] in
            
            self?.coordinator?.hideSubcontrollersRequest()
            self?.navigationController?.setNavigationBarHidden(true, animated: false)
            
            // go through the modal views and hide them if they are not already hidden
            // NOTE: if any more modal views are added, remmber to add them this list
            for view in [ self?.menuView ] {
                if let v = view {
                    if !v.isHidden {
                        // add to the list so that they will be restored later
                        self?.hiddenViewList.append(v)
                        v.isHidden = true
                    }
                }
            }
            
            // collapse filter pamaeters and move to top of screen
            self?.filterParametersView.collapse()
            self?.filterParametersView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: (self?.filterParametersView.frame.size.height)!)
        }
    }
    
    
    // function to restore all modal views that were previously hidden
    func showModalViews() {
        
        DispatchQueue.main.async { [weak self] in
            self?.coordinator?.showSubcontrollersRequest()
            self?.navigationController?.setNavigationBarHidden(false, animated: false)
            
            // for other views, use the hidden list
            if (self?.hiddenViewList.count)! > 0 {
                for view in (self?.hiddenViewList)! {
                    if let v = view {
                        v.isHidden = false
                    }
                    self?.hiddenViewList = []
                }
            }
            
            //if filterParametersView.numVisibleParams > 0 {
            self?.filterParametersView.isHidden = false
            self?.filterParametersView.expand()
            //self?.view.bringSubviewToFront(filterParametersView)
            self?.filterParametersView.setNeedsDisplay()
            self?.filterParametersView.setNeedsLayout()
            //}
            self?.filterParametersView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: (self?.filterParametersView.frame.size.height)!)
            //self?.filterParametersView.logSizes()//debug
            
            self?.view.sendSubviewToBack((self?.editImageView)!)
        }
    }
    
    
    func toggleModalViews() {
        if (self.navigationController?.isNavigationBarHidden)! {
            showModalViews()
        } else {
            hideModalViews()
        }
    }
    
    //////////////////////////////////////
    // MARK: - Filter Management
    //////////////////////////////////////
    
    
    
    func changeFilterTo(_ key:String){
        DispatchQueue.main.async { [weak self] in
            //TODO: make user accept changes before applying? (Add buttons to parameter display)
            // setup the filter descriptor
            //if (key != filterManager.getCurrentFilterKey()){
            if (key != self?.currFilterKey){
                log.debug("Filter Selected: \(key)")
                self?.currFilterKey = key
                self?.filterManager.setCurrentFilterKey(key)
                self?.currFilterDescriptor = self?.filterManager.getFilterDescriptor(key:key)
                self?.updateCurrentFilter()
            } else {
                // something other than the filter changed
                self?.editImageView.updateImage()
            }
            self?.showFilterSettings()
        }
    }
    
    
    func filterChanged(){
        updateCurrentFilter()
    }
    
    // retrive current settings from FilterManager and store locally
    func updateCurrentFilter(){
        if (currFilterKey != nil) {
            DispatchQueue.main.async { [weak self] in
                self?.editImageView.setFilter(key:(self?.currFilterKey)!)
                self?.filterParametersView.setFilter(self?.currFilterDescriptor)
                self?.filterParametersView.delegate = self
            }
        }
    }
    
    
    
    
    // Management of Filter Parameters view
    fileprivate var filterSettingsShown: Bool = false
    
    fileprivate func showFilterSettings(){
        //self?.coordinator?.hideSubcontrollersRequest()
        if (currFilterDescriptor != nil) {
            DispatchQueue.main.async { [weak self] in
                self?.filterParametersView.isHidden = false
                self?.filterParametersView.expand()
            }
        }
    }
    
    fileprivate func hideFilterSettings(){
        DispatchQueue.main.async { [weak self] in
            self?.coordinator?.showSubcontrollersRequest()
            //filterParametersView.isHidden = true
            self?.filterSettingsShown = false
            self?.filterParametersView.collapse()
        }
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
    // MARK: - Filter Stack
    //////////////////////////////////////////
    
    fileprivate var stackView:EditStackView? = nil
    
    fileprivate func showFilterStack(){
        stackView = EditStackView()
        stackView?.frame.size.width = self.view.frame.size.width - 32
        stackView?.frame.size.height = self.view.frame.size.height * 0.7
        stackView?.delegate = self
        
        self.view.addSubview(stackView!)
        stackView?.anchorInCenter(width: (stackView?.frame.size.width)!, height: (stackView?.frame.size.height)!)
    }
    
    fileprivate func closeStackView() {
        stackView?.isHidden = true
        stackView = nil
    }
    
    //////////////////////////////////////////
    // MARK: - ImagePicker handling
    //////////////////////////////////////////
    
    func changeImage(){
        DispatchQueue.main.async { [weak self] in
            log.debug("imagePreview pressed - launching ImagePicker...")
            // launch an ImagePicker
            self?.imagePicker.allowsEditing = false
            self?.imagePicker.sourceType = .photoLibrary
            //self?.imagePicker.modalPresentationStyle = .popover // required after ios12
            self?.imagePicker.delegate = self
            
            self?.present((self?.imagePicker)!, animated: true, completion: {})
        }
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        log.verbose("Image picked")
        if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
            let assetResources = PHAssetResource.assetResources(for: asset)
            let name = assetResources.first!.originalFilename
            let id = assetResources.first!.assetLocalIdentifier
            
            log.verbose("Picked image:\(name) id:\(id)")
            ImageManager.setCurrentEditImageName(id)

            //InputSource.setCurrent(source: .edit)
            DispatchQueue.main.async { [weak self] in
                self?.updateDisplays()
            }
            
            // bit of a hack, but reset face detection if image changes. This allows results to be re-used across filters, which is a very expensive operation
            DispatchQueue.main.async { [weak self] in
                FaceDetection.reset()
                FaceDetection.detectFaces(on: EditManager.getPreviewImage()!, orientation: ImageManager.getEditImageOrientation(), completion: {})
            }
        } else {
            log.error("Error accessing image data")
        }
        picker.dismiss(animated: false, completion: nil)
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        log.verbose("Image Picker cancelled")
        picker.dismiss(animated: false)
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
            hideModalViews()
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
//            if let touch = touches.first {
//                let position = touch.location(in: editImageView)
//                let imgPos = editImageView.getImagePosition(viewPos:position)
//                if currTouchMode == .filter {
//                    currFilterDescriptor?.setPositionParameter(touchKey, position:imgPos!)
//                } else if currTouchMode == .preview {
//                    editImageView.setSplitPosition(position)
//                }
//                //log.verbose("Touches ended. Final pos:\(position) vec:\(imgPos)")
//                editImageView.runFilter()
//                
//            }
            
            touchKey = ""
            showModalViews()
            enableGestureDetection()
        }
    }
    
    
    //////////////////////////////////////////
    // MARK: - Not yet implemented notifier
    //////////////////////////////////////////
    
    func notYetImplemented(){
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: "Oops!", message: "Not yet implemented. Sorry!", preferredStyle: .alert)
            self?.present(alert, animated: true, completion: nil)
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { _ in alert.dismiss(animated: true, completion: nil)} )
        }
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
        DispatchQueue.main.async { [weak self] in
            EditManager.savePreviewFilter()
            self?.showMessage("Effect applied", time:0.5)
            self?.filterParametersView.setFilter(EditManager.getPreviewFilter())
            self?.editImageView.updateImage()
            self?.coordinator?.showSubcontrollersRequest()
            self?.showModalViews()
        }
    }
    
    func cancelChanges(key: String) {
        log.verbose("\(self.getTag()): \(key)")
        // restore saved parameters
        currFilterDescriptor?.restoreParameters()
        EditManager.popFilter()
        DispatchQueue.main.async { [weak self] in
            self?.showModalViews()
            self?.filterParametersView.setFilter(EditManager.getPreviewFilter())
            self?.editImageView.updateImage()
            self?.coordinator?.showSubcontrollersRequest()
        }
    }
    
    
    func settingsChanged(){
        //log.debug("Filter settings changed")
        self.editImageView.updateImage()
    }
    
    func positionRequested(key: String) {
        DispatchQueue.main.async { [weak self] in
            self?.setTouchMode(.filter)
            self?.handlePositionRequest(key:key)
        }
    }
    
    func fullScreenRequested() {
        DispatchQueue.main.async { [weak self] in
            self?.editImageView.setDisplayMode(.full)
            self?.editImageView.updateImage()
            self?.setTouchMode(.gestures)
        }
    }
    
    func splitScreenrequested() {
        DispatchQueue.main.async { [weak self] in
            self?.editImageView.setDisplayMode(.split)
            self?.editImageView.updateImage()
            self?.setTouchMode(.preview)
        }
    }
    
    func showStackRequested() {
        DispatchQueue.main.async { [weak self] in
            self?.showFilterStack()
        }
    }
    
    func showFiltersRequested() {
        DispatchQueue.main.async { [weak self] in
            self?.editImageView.setFilterMode(.preview)
            self?.editImageView.updateImage()
        }
    }
    
    func showOriginalRequested() {
        DispatchQueue.main.async { [weak self] in
            self?.editImageView.setFilterMode(.original)
            self?.editImageView.updateImage()
            self?.setTouchMode(.gestures)
        }
    }
    
}



// Adornment delegate

extension BasicEditViewController: AdornmentDelegate {
    func adornmentItemSelected(key: String) {
        DispatchQueue.main.async { [weak self] in
            self?.handleSelection(key: key)
        }
    }
}

// gesture tweaking

extension BasicEditViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        // give priority to sliders
        if let touchedView = touch.view, touchedView.isKind(of: UISlider.self) {
            return false
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer)
        -> Bool {
            // If the gesture recognizer's view isn't the main edit view, do not allow multiple gestures
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
            
            // don't propagate if image is not zoomed (otherwise swipe becomes a pan etc.)
            if (gestureRecognizer.view == self.editImageView) && (!self.editImageView.isZoomed()) {
                return false
            }

            return true
    }
}

extension BasicEditViewController: EditStackViewDelegate {
    func editStackDismiss() {
        DispatchQueue.main.async { [weak self] in
            self?.closeStackView()
        }
    }
    
    
}
