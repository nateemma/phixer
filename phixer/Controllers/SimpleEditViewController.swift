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

class SimpleEditViewController: FilterBasedController, FilterBasedControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var theme = ThemeManager.currentTheme()
    
    
    
    // Banner/Navigation View (title)
    fileprivate var bannerView: TitleView! = TitleView()
    
    
    // Main Display View
    var editImageView: EditImageDisplayView! = EditImageDisplayView()
    
    // Views for holding the (modal) overlays. Note: must come after EditImageDisplayView()
    //var filterControlsView : FilterControlsView! = FilterControlsView()
    
    let editControlHeight = 96.0
    
    // child view controller
    var optionsController: EditMainOptionsController? = nil
    
    // Menu view
    var menuView: AdornmentView! = AdornmentView()
    
    // The filter configuration subview
    var filterParametersView: FilterParametersView! = FilterParametersView()
    
    // image picker for changing edit image
    let imagePicker = UIImagePickerController()
    
    var filterManager: FilterManager? = FilterManager.sharedInstance
    
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
 
    // vars related to gestures/touches
    enum touchMode {
        case none
        case gestures
        case filter
        case preview
    }
    
    var currTouchMode:touchMode = .gestures
    
    
    
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        //doInit()
    }
    
    static var initDone:Bool = false
    
    func doInit(){
        
        EditManager.reset()
        
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
            filterParametersView.setConfirmMode(true)
            filterParametersView.delegate = self
            //filterParametersView.setConfirmMode(false)
            editImageView.setFilter(key: "NoFilter")
            SimpleEditViewController.initDone = true
            updateCurrentFilter()
            currTouchMode = .gestures
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
        
        //filterManager?.reset()
        doInit()
        
        checkPhotoAuth()

        
        // set up layout based on orientation
        
        layoutBanner()
        
        
        // Only Portrait mode supported (for now)
        // TODO: add landscape mode
        
        menuView.frame.size.height = CGFloat(bannerHeight)
        menuView.frame.size.width = displayWidth
        layoutMenu()

        editImageView.frame.size.width = displayWidth
        editImageView.frame.size.height = displayHeight - bannerView.frame.size.height

        filterParametersView.frame.size.width = displayWidth
        filterParametersView.frame.size.height = bannerHeight // will be adjusted based on selected filter
 
        // Note: need to add subviews before modifying constraints
        view.addSubview(bannerView)
        view.addSubview(editImageView)
        view.addSubview(menuView)
        view.addSubview(filterParametersView)


        hideModalViews()

        // set layout constraints
        
        // top
        bannerView.anchorAndFillEdge(.top, xPad: 0, yPad: statusBarOffset/2.0, otherSize: bannerView.frame.size.height)
        
        menuView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: menuView.frame.size.height)
        
        // main window
        editImageView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: editImageView.frame.size.height)
        
        filterParametersView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: filterParametersView.frame.size.height)

        // set up the options controller, which provides the modal menus
        optionsController = EditMainOptionsController()
        optionsController?.view.frame = CGRect(origin: CGPoint(x: 0, y: (displayHeight-CGFloat(editControlHeight))), size: CGSize(width: displayWidth, height: CGFloat(editControlHeight)))
        //optionsController?.view.frame = self.view.frame
        optionsController?.delegate = self
        add(optionsController!)

        // add delegate for image picker
        imagePicker.delegate = self
        
        // set gesture detection for the edit display view
        setGestureDetectors(view: editImageView)
        currTouchMode = .gestures
        
        // listen to key press events
        setVolumeListener()
        
    }
    
    /*
     override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
     if ((UIApplication.shared.statusBarOrientation == .landscapeLeft) || (UIApplication.shared.statusBarOrientation == .landscapeRight)) {
     log.verbose("Preparing for transition to Landscape")
     } else {
     log.verbose("Preparing for transition to Portrait")
     }
     }
     */
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if ((UIApplication.shared.statusBarOrientation == .landscapeLeft) || (UIApplication.shared.statusBarOrientation == .landscapeRight)){
            log.verbose("### Detected change to: Landscape")
        } else {
            log.verbose("### Detected change to: Portrait")
            
        }
        //TODO: animate and maybe handle before rotation finishes
        self.viewDidLoad()
        //editImageView.setFilter(nil)
        editImageView.setFilter(key:(currFilterDescriptor?.key)!) // forces reset of filter pipeline
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
        bannerView.title = "Edit Photo"
        bannerView.delegate = self
    }
    

 
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
       let showBlend = (filterManager?.getCurrentFilterDescriptor()?.filterOperationType == FilterOperationType.blend) ? false : true
        
        itemList = []
        itemList.append (Adornment(key: "photo", text: "photo", icon: "", view: photoThumbnail, isHidden: false))
        itemList.append (Adornment(key: "blend", text: "blend", icon: "", view: blendThumbnail, isHidden: showBlend))
        itemList.append (Adornment(key: "reset", text: "reset", icon: "ic_reset", view: nil, isHidden: false))
        itemList.append (Adornment(key: "undo", text: "undo", icon: "ic_undo", view: nil, isHidden: false))
        itemList.append (Adornment(key: "save", text: "save", icon: "ic_save", view: nil, isHidden: false))
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
            defaultDidPress()
        case "save":
            saveDidPress()
        default:
            log.error("Unknown key: \(key)")
        }
    }

    @objc func imageDidPress(){
        self.menuView.isHidden = true
        self.changeImage()
     }
    
    @objc func blendDidPress(){
        self.menuView.isHidden = true
        let vc = BlendGalleryViewController()
        vc.delegate = self
        self.present(vc, animated: true, completion: { })
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
        // restore saved parameters
        currFilterDescriptor?.restoreParameters()
        EditManager.popFilter()
        DispatchQueue.main.async(execute: { () -> Void in
            self.editImageView.updateImage()
            //self.menuView.isHidden = true
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
            view.addGestureRecognizer(gesture)
        }

    }
    
    
    @objc func swiped(_ gesture: UIGestureRecognizer) {
        // if gesturesEnabled {
        if currTouchMode == .gestures {
            if let swipeGesture = gesture as? UISwipeGestureRecognizer {
                switch swipeGesture.direction {
                    
                case UISwipeGestureRecognizerDirection.right:
                    log.verbose("Swiped Right")
                    previousFilter()
                    break
                    
                case UISwipeGestureRecognizerDirection.left:
                    log.verbose("Swiped Left")
                    nextFilter()
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
    
    func showMessage(_ msg:String){
        if !msg.isEmpty {
            DispatchQueue.main.async(execute: { () -> Void in
                let alert = UIAlertController(title: "", message: msg, preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
                Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { _ in alert.dismiss(animated: true, completion: nil)} )
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
        
        // the options controller is always showing something so just hide it
       optionsController?.hide()
        
        // go through the modal views and hide them if they are not already hidden
        // NOTE: if any more modal views are added, remmber to add them this list
        for view in [ menuView, filterParametersView, optionsController?.view ] {
            if let v = view {
                if !v.isHidden {
                    // add to the list so that they will be restored later
                    hiddenViewList.append(v)
                    v.isHidden = true
                }
            }
        }
    }
    
    
    // function to restore all modal views that were previously hidden
    func showModalViews() {
        // the options controller is always showing something so just unhide it
        optionsController?.show()
        
        // for other views, use the hidden list
        if hiddenViewList.count > 0 {
            for view in hiddenViewList {
                if let v = view {
                    v.isHidden = false
                }
                hiddenViewList = []
            }
        }
    }
    

    
    //////////////////////////////////////
    // MARK: - Filter Management
    //////////////////////////////////////
    
    override func previousFilter(){
        optionsController?.previousFilter()
    }
    
    override func nextFilter(){
        optionsController?.nextFilter()
    }
    
    
    func changeFilterTo(_ key:String){
        //TODO: make user accept changes before applying? (Add buttons to parameter display)
        // setup the filter descriptor
        //if (key != filterManager?.getCurrentFilterKey()){
        if (key != currFilterKey){
            log.debug("Filter Selected: \(key)")
            currFilterKey = key
            filterManager?.setCurrentFilterKey(key)
            currFilterDescriptor = filterManager?.getFilterDescriptor(key:key)
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
        optionsController!.view.isHidden = true
        //updateCurrentFilter()
        if (currFilterDescriptor != nil) {
            /***
            // re-layout based on selecetd filter
            filterParametersView.frame.size.height = CGFloat(((currFilterDescriptor?.numParameters)! + 1)) * bannerHeight * 0.75
            filterParametersView.anchorInCorner(.bottomLeft, xPad: 0, yPad: 0, width: filterParametersView.frame.size.width, height: filterParametersView.frame.size.height)
            
            filterParametersView.setFilter(currFilterDescriptor)
            
            //filterParametersView.align(.aboveCentered, relativeTo: filterControlsView, padding: 4, width: filterParametersView.frame.size.width, height: filterParametersView.frame.size.height)
            filterParametersView.isHidden = false
            filterParametersView.delegate = self // can be reset if bouncing between screens
            filterSettingsShown = true
            view.bringSubview(toFront: filterParametersView)
            //filterParametersView.show()
             ***/
            filterParametersView.isHidden = false
        }
    }
    
    fileprivate func hideFilterSettings(){
        optionsController!.view.isHidden = false
        //filterParametersView.dismiss()
        filterParametersView.isHidden = true
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
    
    
    
    //////////////////////////////////////////
    // FilterBasedControllerDelegate(s)
    //////////////////////////////////////////

    
    func filterControllerSelection(key: String) {
        log.verbose("Child selected filter: \(key)")
        DispatchQueue.main.async(execute: { () -> Void in
            self.changeFilterTo(key)
            self.showFilterSettings()
        })
    }
    
    func filterControllerUpdateRequest(tag:String) {
        log.verbose("Child requested update: \(tag)")
        DispatchQueue.main.async(execute: { () -> Void in
            self.editImageView.updateImage()
        })
    }

    
    func filterControllerCompleted(tag:String) {
        log.verbose("Returned from: \(tag)")
        DispatchQueue.main.async(execute: { () -> Void in
            self.editImageView.updateImage()
        })
    }

    
} // SimpleEditViewController
//########################






//////////////////////////////////////////
// MARK: - Delegate methods for sub-views
//////////////////////////////////////////



// TitleViewDelegate
extension SimpleEditViewController: TitleViewDelegate {
    func backPressed() {
        backDidPress()
    }
    
    func helpPressed() {
        let vc = HTMLViewController()
        vc.setTitle("'Simple' Editor")
        vc.loadFile(name: "SimpleEditor")
        present(vc, animated: true, completion: nil)    }
    
    func menuPressed() {
        // if menu is hidden then re-layout and show it, otherwise hide it
        if self.menuView.isHidden == true {
            DispatchQueue.main.async(execute: { () -> Void in
                self.layoutMenu()
                self.menuView.isHidden = false
            })
        } else {
            self.menuView.isHidden = true
        }
    }
}







extension SimpleEditViewController: FilterParametersViewDelegate {

    func commitChanges(key: String) {
        // make the change permanent
        DispatchQueue.main.async(execute: { () -> Void in
            EditManager.savePreviewFilter()
            self.optionsController!.view.isHidden = false
        })
    }
    
    func cancelChanges(key: String) {
        // restore saved parameters
        currFilterDescriptor?.restoreParameters()
        EditManager.popFilter()
        DispatchQueue.main.async(execute: { () -> Void in
            self.editImageView.updateImage()
            self.optionsController!.view.isHidden = false
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

extension SimpleEditViewController: AdornmentDelegate {
    func adornmentItemSelected(key: String) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.handleSelection(key: key)
        })
    }
}

