//
//  FilterDetailsViewController.swift
//  phixer
//
//  Created by Philip Price on 10/27/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation

import UIKit
import CoreImage
import Neon
import AVFoundation
import MediaPlayer
import AudioToolbox
import Photos

import GoogleMobileAds
import Cosmos


// delegate method to let the launcing ViewController know that this one has finished
protocol FilterDetailsViewControllerDelegate: class {
    func onCompletion(key:String)
    func prevFilterRequest()
    func nextFilterRequest()
}



// This is the View Controller for displaying a filter with a sample image and exposing the controls (if any)

class FilterDetailsViewController: CoordinatedController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    open var currFilterKey: String = ""
    
    
    // Advertisements View
    //var adView: GADBannerView! = GADBannerView()
    
    // Main Filtered Output View
    //fileprivate var editImageView: FilterDisplayView! = FilterDisplayView()
    fileprivate var editImageView: EditImageDisplayView! = EditImageDisplayView()

    
    
    // The filter configuration subview
    fileprivate var filterParametersView: FilterParametersView! = FilterParametersView()
    
    // Overlay/Navigation help views
    fileprivate var overlayView: UIView! = UIView()
    
    // image picker for changing edit image
    let imagePicker = UIImagePickerController()

    fileprivate var currCategory: String = ""
    fileprivate var currFilterDescriptor:FilterDescriptor? = nil
    fileprivate var currFilterIndex:Int = -1
    fileprivate var currFilterCount:Int = 0
    

    fileprivate var displayWidth : CGFloat = 0.0
    fileprivate var displayHeight : CGFloat = 0.0
    
    
    fileprivate var initDone:Bool = false
    
    
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
        return "Filter Preview"
    }
    
    // return the name of the help file associated with this Controller (without extension)
    override public func getHelpKey() -> String {
        return "FilterPreview"
    }
    
  

    ///////////////////////
    //MARK: Init
    ///////////////////////

    convenience init(){
        self.init(nibName:nil, bundle:nil)
        doInit()
    }
    
    
    deinit{
        suspend()
    }
    
    
    
    func doInit(){
        
        if (!initDone){
            initDone = true
        }
    }
    
  
    ///////////////////////
    //MARK: Accessors
    ///////////////////////


    override func updateDisplays() {
        update()
    }

    override func selectFilter(key: String){
        loadFilterInfo(category: currCategory, key: key)
    }

    
    public func suspend(){
        self.editImageView.suspend()
    }
    
    public func update(){
        DispatchQueue.main.async(execute: { () -> Void in
            self.doLayout()
            self.editImageView.update()
            self.overlayView.setNeedsLayout()
        })
    }
    
  
    public func saveImage(){
        editImageView.saveImage()
    }


    
    
    ///////////////////////
    //MARK: Top level logic
    ///////////////////////

    func loadFilterInfo(category: String, key: String){
        
        guard (key.isEmpty != true) else {
            // ignore
            log.verbose("NIL key supplied")
            return
        }
        
        if (!currFilterKey.isEmpty) && (key != currFilterKey) {
            releaseCurrentFilter()
        }
        
        currFilterKey = key
        currCategory = category
        currFilterIndex = filterManager.getFilterIndex(category: category, key: key)
        currFilterDescriptor = filterManager.getFilterDescriptor(key: key)
        currFilterCount = filterManager.getFilterCount(category)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // common setup
        self.prepController()

        log.verbose("currFilterKey:\(currFilterKey)")
        
        // get display dimensions
        displayHeight = view.height
        displayWidth = view.width
        
        
       
        log.verbose("h:\(displayHeight) w:\(displayWidth) landscape:\(UISettings.isLandscape)")
        
        doInit()
        
        loadFilterInfo(category: filterManager.getCurrentCategory(), key: filterManager.getCurrentFilterKey())
        
        guard  (currFilterDescriptor != nil) else {
            log.error("!!! No descriptor provided !!!")
            return
        }
        

        doLayout()
        self.overlayView.setNeedsLayout()
        
        
        // start Advertisements
        //startAds()
        
        
        setTouchMode(.gestures)
        assignTouchHandlers()
        
        editImageView.setFilter(key: currFilterKey)

        
        // that's it, rendering is handled by the FilterDisplayView and FilterControlsView classes
        
    }
    
    
    fileprivate func doLayout(){
        // Note: need to add subviews before modifying constraints
 
        // get display dimensions
        displayHeight = view.height
        displayWidth = view.width
        
        //view.addSubview(adView)
        setupDisplay()
        //setupAdornments()
        setupAdditionalPanel()
        
        setupConstraints()
        editImageView.setFilter(key: currFilterKey)
        filterParametersView.setFilter(currFilterDescriptor)
        positionParameterView()

        filterParametersView.delegate = self
    }
    
 
    
    fileprivate func setupDisplay(){
        //editImageView = FilterDisplayView()
        editImageView = EditImageDisplayView()
    }
   
    
    
    fileprivate func setupConstraints(){
        
        view.addSubview(editImageView)
        view.addSubview(overlayView)
        view.addSubview(filterParametersView)
        
        // Portrait: top-to-bottom layout scheme
        
        // Parameters on the bottom
        
        if (currFilterDescriptor != nil) {
            //filterParametersView.frame.size.height = fmin((CGFloat(((currFilterDescriptor?.numParameters)! + 1)) * UISettings.panelHeight * 0.75), (displayHeight*0.75))
            filterParametersView.frame.size.height = fmin((CGFloat(((currFilterDescriptor?.getNumDisplayableParameters())! + 1)) * UISettings.panelHeight * 0.75), (displayHeight*0.75))
        } else {
            filterParametersView.frame.size.height = (displayHeight - 2.0 * UISettings.panelHeight) * 0.3
        }
        
        filterParametersView.frame.size.width = displayWidth
        filterParametersView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 1, otherSize: filterParametersView.frame.size.height)
        view.bringSubviewToFront(filterParametersView)
        
        // Filter display takes the rest of the screen
        //editImageView.frame.size.height = displayHeight - UISettings.topBarHeight - filterParametersView.frame.size.height - 4
        editImageView.frame.size.height = displayHeight - UISettings.topBarHeight
        editImageView.frame.size.width = displayWidth
        log.verbose("FilterDisplay: (w:\(editImageView.frame.size.width), h:\(editImageView.frame.size.height))")
        
        editImageView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: editImageView.frame.size.height)

        
        
        // prev/next navigation (same for both layouts)

        log.debug("Overlaying navigation buttons")
        
        
        // resize overlayView to match the display view (minus the parameters view)
        overlayView.frame.size.width  = editImageView.frame.size.width
        overlayView.frame.size.height  = editImageView.frame.size.height - filterParametersView.frame.size.height
        overlayView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: overlayView.frame.size.height)

        view.bringSubviewToFront(overlayView)
        //overlayView.setNeedsDisplay() // for some reason it doesn't display the first time through

        
        layoutAdornments() // same for either rotation
    }
    
    private func positionParameterView(){
        // the size of the parameter view changes with each filter, so it's tricky to position. This routine positions it after it has been sized etc.
        if (UISettings.isLandscape){
            filterParametersView.anchorInCorner(.bottomRight, xPad: 0, yPad: 0, width: filterParametersView.frame.size.width, height: filterParametersView.frame.size.height)
        } else {
            filterParametersView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 1, otherSize: filterParametersView.frame.size.height)
        }
    }

    
    // modal setup for overlay panels
    private func setupAdditionalPanel(){
        // if this is showing samples, then display ratings, else display change photo/save etc.
        if InputSource.getCurrent() == .sample {
            overlayView.isHidden = false
            setupAdornments()
        }
    }
    
    
    // setup the adornments (favourites, show/hide, ratings etc.) for the current filter
    
    // individual adornments
    fileprivate var showAdornment: UIImageView = UIImageView()
    fileprivate var favAdornment: UIImageView = UIImageView()
    fileprivate var ratingAdornment: UIImageView = UIImageView()
    
    fileprivate func setupAdornments() {
        
        guard (self.currFilterDescriptor != nil)  else {
            log.error ("NIL descriptor")
            return
        }
        
        overlayView.frame = self.editImageView.frame
        
        // set size of adornments
        //let dim: CGFloat = overlayView.frame.size.height / 8.0
        let dim: CGFloat = UISettings.buttonSide
        let adornmentSize = CGSize(width: dim, height: dim)
        
        let key = (self.currFilterDescriptor?.key)!

        // show/hide
        let showAsset: String =  (self.filterManager.isHidden(key: key) == true) ? "ic_reject" : "ic_accept"
        showAdornment.image = UIImage(named: showAsset)?.imageScaled(to: adornmentSize)
        
        
        // favourite
        var favAsset: String =  "ic_heart_outline"
        if self.filterManager.isFavourite(key: key){
            favAsset = "ic_heart_filled"
        }
        favAdornment.image = UIImage(named: favAsset)?.imageScaled(to: adornmentSize)
        
        // rating
        var ratingAsset: String =  "ic_star"
        switch (self.filterManager.getRating(key: key)){
        case 1:
            ratingAsset = "ic_star_filled_1"
        case 2:
            ratingAsset = "ic_star_filled_2"
        case 3:
            ratingAsset = "ic_star_filled_3"
        default:
            break
        }
        ratingAdornment.image = UIImage(named: ratingAsset)?.imageScaled(to: adornmentSize)
        
        
        // add a little background so that you can see the icons
        showAdornment.backgroundColor = theme.secondaryColor.withAlphaComponent(0.5)
        showAdornment.layer.cornerRadius = 2.0
        
        favAdornment.backgroundColor = showAdornment.backgroundColor
        favAdornment.alpha = showAdornment.alpha
        favAdornment.layer.cornerRadius = showAdornment.layer.cornerRadius
        
        ratingAdornment.backgroundColor = showAdornment.backgroundColor
        ratingAdornment.alpha = showAdornment.alpha
        ratingAdornment.layer.cornerRadius = showAdornment.layer.cornerRadius
        
        
        // add icons to the overlay view
        overlayView.addSubview(showAdornment)
        overlayView.addSubview(favAdornment)
        overlayView.addSubview(ratingAdornment)
        overlayView.setNeedsDisplay()
    }
    
    
    fileprivate func layoutAdornments(){
        let dim: CGFloat = overlayView.frame.size.height / 16.0
        let pad: CGFloat = 2.0
        showAdornment.anchorInCorner(.topLeft, xPad:pad, yPad:pad, width: dim, height: dim)
        ratingAdornment.anchorInCorner(.topRight, xPad:pad, yPad:pad, width: dim, height: dim)
        favAdornment.anchorToEdge(.top, padding:pad, width:dim, height:dim)
        view.bringSubviewToFront(overlayView)
        
        // add touch handlers for the adornments
        log.verbose("Adding adornment touch handlers")
        showAdornment.isUserInteractionEnabled = true
        favAdornment.isUserInteractionEnabled = true
        ratingAdornment.isUserInteractionEnabled = true
        overlayView.isUserInteractionEnabled = true
        
        
        let showRecognizer = UITapGestureRecognizer(target: self, action: #selector(showTouched))
        let favRecognizer = UITapGestureRecognizer(target: self, action: #selector(favTouched))
        let ratingRecognizer = UITapGestureRecognizer(target: self, action: #selector(ratingTouched))
        
        showAdornment.addGestureRecognizer(showRecognizer)
        favAdornment.addGestureRecognizer(favRecognizer)
        ratingAdornment.addGestureRecognizer(ratingRecognizer)
    }
    

    
    
    /////////////////////////////
    // MARK: - Ad Framework
    /////////////////////////////
    /*
     fileprivate func startAds(){
     log.debug("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
     adView.adUnitID = admobID
     adView.rootViewController = self
     adView.load(GADRequest())
     adView.backgroundColor = theme.backgroundColor
     }
     */
  
    
    // go to the next filter
    func gotoNextFilter(){
        releaseCurrentFilter()
        currFilterIndex = (currFilterIndex + 1) % currFilterCount
        let key = filterManager.getFilterKey(category: currCategory, index: currFilterIndex)
        loadFilterInfo(category: currCategory, key: key)
    }
    
    // go to the previous filter
    func gotoPreviousFilter(){
        releaseCurrentFilter()
        currFilterIndex = (currFilterIndex - 1)
        if (currFilterIndex < 0) { currFilterIndex = currFilterCount - 1 }
        let key = filterManager.getFilterKey(category: currCategory, index: currFilterIndex)
        loadFilterInfo(category: currCategory, key: key)
    }
    
    
    func releaseCurrentFilter() {
        if currFilterDescriptor != nil {
            if !currFilterKey.isEmpty {
                log.verbose("Release: \(currFilterKey)")
                filterManager.releaseFilterDescriptor(key: currFilterKey)
                filterManager.releaseRenderView(key: currFilterKey)
            }
        }
    }

    /////////////////////////////
    // MARK: - Touch Handler(s)
    /////////////////////////////
    
    func assignTouchHandlers(){
        
        setGestureDetectors(overlayView)
    
    }

    @objc func backDidPress(){
        log.verbose("Back pressed")
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            suspend()
            self.dismiss()
            return
        }
    }

    @objc func prevDidPress(){
        if gesturesEnabled {
            log.verbose("Previous Filter pressed")
            suspend()
            gotoPreviousFilter()
            update()
        }
    }
    
    @objc func nextDidPress(){
        if gesturesEnabled {
            log.verbose("Next Filter pressed")
            suspend()
            gotoNextFilter()
            update()
        }
    }
    
    func showParameters(){
        filterParametersView.isHidden = false
        filterParametersView.setNeedsDisplay()
    }
    
    func hideParameters(){
        filterParametersView.isHidden = true
    }
    
    // handles touch of the show/hide icon
    @objc func showTouched(){
        log.verbose("hide/show touched")
        //TODO: confirmation dialog?
        let hidden =  self.filterManager.isHidden(key: self.currFilterKey) ? false : true
        self.filterManager.setHidden(key: self.currFilterKey, hidden: hidden)
        self.update()
    }
    
    @objc func favTouched(){
        log.verbose("favourite touched")
        //TODO: confirmation dialog?
        if self.filterManager.isFavourite(key: self.currFilterKey){
            log.verbose ("Removing from Favourites: \(self.currFilterKey)")
            self.filterManager.removeFromFavourites(key: self.currFilterKey)
        } else {
            log.verbose ("Adding to Favourites: \(self.currFilterKey)")
            self.filterManager.addToFavourites(key: self.currFilterKey)
        }
        self.update()
    }
    
    @objc func ratingTouched(){
        log.verbose("rating touched")
        self.currRatingKey = self.currFilterKey
        self.currRating = self.filterManager.getRating(key: self.currRatingKey)
        displayRating()
        //self.update()
    }
    
    //////////////////////////////////////
    // MARK: - Rating Popup
    //////////////////////////////////////
    
    fileprivate var ratingAlert:UIAlertController? = nil
    fileprivate var currRating: Int = 0
    fileprivate var currRatingKey: String = ""
    fileprivate static var starView: CosmosView? = nil
    
    fileprivate func displayRating(){
        
        
        // build the rating stars display based on the current rating
        // I'm using the 'Cosmos' class to do this
        if (FilterDetailsViewController.starView == nil){
            FilterDetailsViewController.starView = CosmosView()
            
            FilterDetailsViewController.starView?.settings.fillMode = .full // Show only fully filled stars
            //starView?.settings.starSize = 30
            FilterDetailsViewController.starView?.settings.starSize = Double(displayWidth / 16.0) - 2.0
            //starView?.settings.starMargin = 5
            
            // Set the colours
            FilterDetailsViewController.starView?.settings.totalStars = 3
            FilterDetailsViewController.starView?.backgroundColor = UIColor.clear
            FilterDetailsViewController.starView?.settings.filledColor = UIColor.flatYellow
            FilterDetailsViewController.starView?.settings.emptyBorderColor = UIColor.flatGrayDark
            FilterDetailsViewController.starView?.settings.filledBorderColor = UIColor.flatBlack
            
            FilterDetailsViewController.starView?.didFinishTouchingCosmos = { rating in
                self.currRating = Int(rating)
                FilterDetailsViewController.starView?.anchorInCenter(width: self.displayWidth / 4.0, height: self.displayWidth / 16.0) // re-centre
            }
        }
        FilterDetailsViewController.starView?.rating = Double(currRating)
        
        // igf not already done, build the alert
        if (ratingAlert == nil){
            // setup the basic info
            ratingAlert = UIAlertController(title: "Rating", message: " ", preferredStyle: .alert)
            
            // add the OK button
            let okAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                self.filterManager.setRating(key: self.currRatingKey, rating: self.currRating)
                log.debug("OK")
            }
            ratingAlert?.addAction(okAction)
            
            // add the Cancel Button
            let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action:UIAlertAction) in
                log.debug("Cancel")
            }
            ratingAlert?.addAction(cancelAction)
            
            
            // add the star rating view
            ratingAlert?.view.addSubview(FilterDetailsViewController.starView!)
        }
        
        FilterDetailsViewController.starView?.anchorInCenter(width: displayWidth / 4.0, height: displayWidth / 16.0)
        
        // launch the Alert. Need to get the Controller to do this though, since we are calling from a View
        DispatchQueue.main.async(execute: { () -> Void in
            self.present(self.ratingAlert!, animated: true, completion:{ [weak self] in
                self?.update()
            })
        })
    }

    
    //////////////////////////////////////
    // MARK: - Gesture Detection
    //////////////////////////////////////
    
    var gesturesEnabled:Bool = true
    
    func enableGestureDetection(){
        if !gesturesEnabled {
            gesturesEnabled = true
            setTouchMode(.gestures)
            overlayView.isHidden = false
            overlayView.isUserInteractionEnabled = true
            editImageView.isUserInteractionEnabled = true
            showParameters()
        }
   }
    
    func disableGestureDetection(){
        if gesturesEnabled {
            gesturesEnabled = false
            overlayView.isHidden = true
            overlayView.isUserInteractionEnabled = false
            editImageView.isUserInteractionEnabled = false
            hideParameters()
        }
    }

    func setGestureDetectors(_ view: UIView){
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.swiped))
        swipeRight.direction = .right
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.swiped))
        swipeLeft.direction = .left
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.swiped))
        swipeUp.direction = .up
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.swiped))
        swipeDown.direction = .down
        
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
                    
                case UISwipeGestureRecognizer.Direction.right:
                    //log.verbose("Swiped Right")
                    prevDidPress()
                    break
                    
                case UISwipeGestureRecognizer.Direction.left:
                    //log.verbose("Swiped Left")
                    nextDidPress()
                    break
                    
                case UISwipeGestureRecognizer.Direction.up:
                    //log.verbose("Swiped Up")
                    showParameters()
                    break
                    
                case UISwipeGestureRecognizer.Direction.down:
                    hideParameters()
                    //log.verbose("Swiped Down")
                    break
                    
                default:
                    log.debug("Unhandled gesture direction: \(swipeGesture.direction)")
                    break
                }
            } else {
                // still allow up/down
                if let swipeGesture = gesture as? UISwipeGestureRecognizer {
                    if swipeGesture.direction == UISwipeGestureRecognizer.Direction.up {
                        showParameters()
                    } else if swipeGesture.direction == UISwipeGestureRecognizer.Direction.down {
                        hideParameters()
                    }
                }
            }
        }
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
    // MARK: - ImagePicker handling
    //////////////////////////////////////////

    func changeImage(){
        DispatchQueue.main.async(execute: { () -> Void in
            log.debug("imagePreview pressed - launching ImagePicker...")
            // launch an ImagePicker
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .photoLibrary
            self.imagePicker.delegate = self
            
            self.present(self.imagePicker, animated: true, completion: {
            })
        })
    }
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
         if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
            let assetResources = PHAssetResource.assetResources(for: asset)
            let name = assetResources.first!.originalFilename
            let id = assetResources.first!.assetLocalIdentifier
            
            log.verbose("Picked image:\(name) id:\(id)")
            ImageManager.setCurrentEditImageName(id)
            DispatchQueue.main.async(execute: { () -> Void in
                self.update()
            })
        } else {
            log.error("Error accessing image data")
        }
        picker.dismiss(animated: true)
        
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    

    
} // FilterDetailsViewController class

//////////////////////////////////////////
// MARK: - Delegate methods for sub-views
//////////////////////////////////////////



extension FilterDetailsViewController: FilterParametersViewDelegate {
    
    
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
    
    
    func showStackRequested() {
        // ignore
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
    
    
    func commitChanges(key: String) {
        // ignore
    }
    
    func cancelChanges(key: String) {
        backDidPress()
    }
    
    
    func settingsChanged(){
        //log.debug("Filter settings changed")
        self.editImageView.updateImage()
    }
    
    func positionRequested(key: String) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.handlePositionRequest(key:key)
        })
    }
}



////////////////////////////////////////////
// MARK: - UIAlertController
////////////////////////////////////////////
/***/
// why do we have to do this?! when AlertController is set up, re-position the stars
extension UIAlertController {
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // TODO: figure out sizes
        FilterDetailsViewController.starView?.anchorInCenter(width: 128, height: 32)
    }
}
/***/


