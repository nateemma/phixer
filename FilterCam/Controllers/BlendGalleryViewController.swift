//
//  BlendGalleryViewController.swift
//  FilterCam
//
//  Created by Philip Price on 10/24/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import GPUImage
import Neon
import AVFoundation
import MediaPlayer
import AudioToolbox

import GoogleMobileAds

import Photos



// delegate method to let the launching ViewController know that this one has finished
protocol BlendGalleryViewControllerDelegate: class {
    func blendGalleryCompleted()
}


private var filterList: [String] = []
private var filterCount: Int = 0

// This is the View Controller for displaying and organising filters into categories

class BlendGalleryViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // delegate for handling events
    weak var delegate: BlendGalleryViewControllerDelegate?
    
    
    // Banner View (title)
    fileprivate var bannerView: UIView! = UIView()
    fileprivate var backButton:UIButton! = UIButton()
    fileprivate var titleLabel:UILabel! = UILabel()
    
    
    // Advertisements View
    fileprivate var adView: GADBannerView! = GADBannerView()
    
    // View containing previews, buttons etc.Advertisements
    fileprivate var infoView: UIView! = UIView()
    fileprivate var acceptButton:UIButton! = UIButton()
    fileprivate var cancelButton:UIButton! = UIButton()
    
    fileprivate var helpLabel:UILabel! = UILabel()
    fileprivate var selectedLabel:UILabel! = UILabel()
    fileprivate var photosLabel:UILabel! = UILabel()
    fileprivate var filterLabel:UILabel! = UILabel()
    
    fileprivate var selectedBlendImageName: String = ""
    fileprivate var selectedBlendImage:UIImageView! = UIImageView()
    fileprivate var selectedBlendImageSize: CGSize = CGSize.zero
    fileprivate var blendInput:PictureInput? = nil
    
    fileprivate var photosLinkImage:UIImageView! = UIImageView()
    fileprivate var filteredImage:RenderView! = nil
    
    // views used to manage layout of subviews
    fileprivate let buttonContainerView: UIView! = UIView()
    fileprivate let imageContainerView: UIView! = UIView()
    
    //let filteredView:ImageContainerView = ImageContainerView()
    //let selectedView:ImageContainerView = ImageContainerView()
    //let photosView:ImageContainerView = ImageContainerView()
    fileprivate let selectedView:UIView = UIView()
    fileprivate let photosView:UIView = UIView()
    fileprivate let filteredView:UIView = UIView()
    
    // the gallery of Blend options
    fileprivate var blendGalleryView : BlendGalleryView! = BlendGalleryView()
    
    // sample image vars
    fileprivate var sampleImageName: String = ""
    fileprivate var sampleImage:UIImage? = nil
    fileprivate var sampleInput:PictureInput? = nil
    fileprivate var opacityFilter:OpacityAdjustment? = nil
    
    fileprivate let imagePicker = UIImagePickerController()
    
    fileprivate var filterManager:FilterManager = FilterManager.sharedInstance
    fileprivate var currDescriptor:FilterDescriptorInterface? = nil
    fileprivate var filterList:[String] = []
    fileprivate var currFilterIndex:Int = 0
    fileprivate var currFilterKey:String = ""
    fileprivate var imageSize:CGSize = CGSize(width:96, height:96*3.0/2.0)
    
    fileprivate var isLandscape : Bool = false
    fileprivate var showAds : Bool = true
    fileprivate var screenSize : CGRect = CGRect.zero
    fileprivate var displayWidth : CGFloat = 0.0
    fileprivate var displayHeight : CGFloat = 0.0
    
    fileprivate let bannerHeight : CGFloat = 64.0
    fileprivate let buttonSize : CGFloat = 48.0
    fileprivate let statusBarOffset : CGFloat = 12.0
    
    
    
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        doInit()
    }
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get display dimensions
        displayHeight = view.height
        displayWidth = view.width
        
        
        // get orientation
        //isLandscape = UIDevice.current.orientation.isLandscape // doesn't always work properly, especially in simulator
        isLandscape = (displayWidth > displayHeight)
        
        
        doInit()
        
        doLayout()
        
        // start Ads
        if (showAds){
            Admob.startAds(view:adView, viewController:self)
        }
        
    }
    
    
    
    static var initDone:Bool = false
    
    func doInit(){
        
        if (!BlendGalleryViewController.initDone){
            BlendGalleryViewController.initDone = true
        }
    }
    
    
    
    func suspend(){
        removeTargets()
    }
    
    
    func doLayout(){
        
        doInit()
        
        filterList = filterManager.getFilterList("blends")!
        currFilterIndex = 0
        if (filterList.count>0){
            currFilterKey = filterList[currFilterIndex]
        }
        
        displayHeight = view.height
        displayWidth = view.width
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        //showAds = (isLandscape == true) ? false : true // don't show in landscape mode (too cluttered)
        showAds = false // this screen looks bad with ads included...
        
        
        view.backgroundColor = UIColor.black // default seems to be white
        
        
        selectedBlendImageName = ImageManager.getCurrentBlendImageName()
        sampleImageName = ImageManager.getCurrentSampleImageName()
        sampleImage = ImageManager.getCurrentSampleImage()
        //sampleInput = PictureInput(image:sampleImage!)
        sampleInput = ImageManager.getCurrentSampleInput()
        //filteredImage = filterManager.getRenderView(key: currFilterKey)
        if (filteredImage == nil) {  filteredImage = RenderView() }
      
        
        //set up dimensions
        
        bannerView.frame.size.height = bannerHeight * 0.75
        bannerView.frame.size.width = displayWidth
        bannerView.backgroundColor = UIColor.black
        
        
        layoutBanner()
        
        if (showAds){
            adView.frame.size.height = bannerHeight
            adView.frame.size.width = displayWidth
            adView.layer.cornerRadius = 0.0
            adView.layer.borderWidth = 1.0
            adView.layer.borderColor = UIColor.gray.cgColor
        }
        
        infoView.frame.size.height = 4.2 * bannerHeight // TODO: calculate from components
        infoView.frame.size.width = displayWidth
        layoutInfoView()
        view.addSubview(infoView)
        
        if (showAds){
            blendGalleryView.frame.size.height = displayHeight - bannerView.frame.size.height - adView.frame.size.height - infoView.frame.size.height
        } else {
            blendGalleryView.frame.size.height = displayHeight - bannerView.frame.size.height - infoView.frame.size.height
        }
        blendGalleryView.frame.size.width = displayWidth
        //blendGalleryView.backgroundColor = UIColor.black
        
        
        
        blendGalleryView.delegate = self
        view.addSubview(blendGalleryView)
        
        
        // Note: need to add subviews before modifying constraints
        view.addSubview(bannerView)
        if (showAds){
            adView.isHidden = false
            view.addSubview(adView)
        } else {
            log.debug("Not showing Ads in landscape mode")
            adView.isHidden = true
        }
        
        
        // layout constraints
        bannerView.anchorAndFillEdge(.top, xPad: 0, yPad: statusBarOffset/2.0, otherSize: bannerView.frame.size.height)
        
        if (showAds){
            adView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: adView.frame.size.height)
            infoView.align(.underCentered, relativeTo: adView, padding: 0, width: displayWidth, height: infoView.frame.size.height)
        } else {
            infoView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: infoView.frame.size.height)
        }
        
        blendGalleryView.align(.underCentered, relativeTo: infoView, padding: 0, width: displayWidth, height: blendGalleryView.frame.size.height)
        
        log.verbose("H: banner:\(bannerView.frame.size.height) , ad:\(adView.frame.size.height), info:\(infoView.frame.size.height), gallery:\(blendGalleryView.frame.size.height)")
        
        // add delegates to sub-views (for callbacks)
        //bannerView.delegate = self
        
        blendGalleryView.delegate = self
        
        
        
        // update the filtered image
        updateFilteredImage()
        
        // register gesture detection for Filter View
        setGestureDetectors(infoView) // restrict more?!
    }
    
    
    
    // layout the banner view, with the Back button, title etc.
    func layoutBanner(){
        bannerView.addSubview(backButton)
        bannerView.addSubview(titleLabel)
        
        backButton.frame.size.height = bannerView.frame.size.height - 8
        backButton.frame.size.width = 2.0 * backButton.frame.size.height
        backButton.setTitle("< Back", for: .normal)
        backButton.backgroundColor = UIColor.flatMint()
        backButton.setTitleColor(UIColor.white, for: .normal)
        backButton.titleLabel!.font = UIFont.boldSystemFont(ofSize: 20.0)
        backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
        
        titleLabel.frame.size.height = backButton.frame.size.height
        titleLabel.frame.size.width = displayWidth - backButton.frame.size.width
        titleLabel.text = "Blend Image Gallery"
        titleLabel.backgroundColor = UIColor.black
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
        titleLabel.textAlignment = .center
        
        
        backButton.anchorInCorner(.bottomLeft, xPad: 4, yPad: 4, width: backButton.frame.size.width, height: backButton.frame.size.height)
        titleLabel.align(.toTheRightCentered, relativeTo: backButton, padding: 0, width: titleLabel.frame.size.width, height: titleLabel.frame.size.height)
        
        backButton.addTarget(self, action: #selector(self.backDidPress), for: .touchUpInside)
        
    }
    
    
    
    // layout the info view, which contains previews of the current and proposed selections, link to photos and accept/cancel buttons
    func layoutInfoView(){
        
        // Accept/Cancel Buttons
        for button in [acceptButton, cancelButton] {
            button?.frame.size.height = bannerView.frame.size.height - 8
            button?.frame.size.width = 3.0 * (button?.frame.size.height)!
            button?.backgroundColor = UIColor.flatMint()
            button?.setTitleColor(UIColor.white, for: .normal)
            button?.titleLabel!.font = UIFont.boldSystemFont(ofSize: 20.0)
            button?.contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
        }
        acceptButton.setTitle("Accept", for: .normal)
        cancelButton.setTitle("Cancel", for: .normal)
        
        buttonContainerView.addSubview(acceptButton)
        buttonContainerView.addSubview(cancelButton)
        
        buttonContainerView.frame.size.width = displayWidth
        buttonContainerView.frame.size.height = acceptButton.frame.size.height + 4
        
        
        // helpLabel, filterLabel, selectedLabel
        
        for label in [helpLabel, filterLabel, selectedLabel, photosLabel]{
            label?.frame.size.width = displayWidth / 3.0
            label?.frame.size.height = 32.0
            label?.backgroundColor = UIColor.black
            label?.textColor = UIColor.white
            label?.font = UIFont.systemFont(ofSize: 14)
            label?.textAlignment = .center
        }
        helpLabel.text = "Select an image from below or a photo"
        helpLabel.font = UIFont.systemFont(ofSize: 18)
        
        selectedLabel.text = "Selected:"
        photosLabel.text = "Photos:"
        filterLabel.text = "Preview:"
        
        // filteredImage
        // selectedBlendImage
        // photosLinkImage
        for image in [filteredImage, selectedBlendImage, photosLinkImage] as [UIView]{
            image.frame.size = imageSize
            image.backgroundColor = UIColor.black
            image.layer.cornerRadius = 0.0
            image.layer.borderWidth = 1.0
            image.layer.borderColor = UIColor.white.cgColor
            image.clipsToBounds = true
            image.contentMode = .scaleAspectFill
        }
        selectedBlendImage.image = ImageManager.getBlendImage(name: selectedBlendImageName, size: imageSize)
        loadPhotoThumbnail(view:photosLinkImage)
        
        // bundle the images and their labels into container Views
        let viewSize = CGSize(width:(imageSize.width+2), height:(imageSize.height+filterLabel.frame.size.height + 2))
        
        selectedView.frame.size = viewSize
        selectedView.addSubview(selectedBlendImage)
        selectedView.addSubview(selectedLabel)
        selectedBlendImage.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: imageSize.height)
        selectedLabel.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: selectedLabel.frame.size.height)
        
        photosView.frame.size = viewSize
        photosView.addSubview(photosLinkImage)
        photosView.addSubview(photosLabel)
        photosLinkImage.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: imageSize.height)
        photosLabel.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: photosLabel.frame.size.height)
        
        
        filteredView.frame.size = viewSize
        filteredView.addSubview(filteredImage)
        filteredView.addSubview(filterLabel)
        filteredImage.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: imageSize.height)
        filterLabel.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: filterLabel.frame.size.height)
        

        imageContainerView.frame.size.height = filteredView.frame.size.height
        imageContainerView.frame.size.width = infoView.frame.size.width
        
        // add the subviews to infoView
        infoView.addSubview(helpLabel)
        
        imageContainerView.addSubview(selectedView)
        imageContainerView.addSubview(photosView)
        imageContainerView.addSubview(filteredView)
        infoView.addSubview(imageContainerView)
        
        infoView.addSubview(buttonContainerView)
        
        
        // layout the constraints
        
        infoView.addSubview(buttonContainerView)
        
        
        helpLabel.anchorAndFillEdge(.top, xPad: 2.0, yPad: 2.0, otherSize: helpLabel.frame.size.height)
        
        imageContainerView.groupInCenter(.horizontal, views: [selectedView, photosView, filteredView], padding: 8, width: filteredView.frame.size.width, height: filteredView.frame.size.height)
        imageContainerView.align(.underCentered, relativeTo: helpLabel, padding: 1, width: imageContainerView.frame.size.width, height: filteredView.frame.size.height)
        
        buttonContainerView.groupInCenter(.horizontal, views: [acceptButton, cancelButton], padding: 8, width: acceptButton.frame.size.width, height: acceptButton.frame.size.height)
        buttonContainerView.anchorAndFillEdge(.bottom, xPad: 2.0, yPad: 2.0, otherSize: buttonContainerView.frame.size.height)
        
        
        // add touch handlers
        acceptButton.addTarget(self, action: #selector(self.acceptDidPress), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(self.cancelDidPress), for: .touchUpInside)
        
        let filterTap = UITapGestureRecognizer(target: self, action: #selector(filterDidPress))
        filteredView.addGestureRecognizer(filterTap)
        filteredView.isUserInteractionEnabled = true
        
        let photosTap = UITapGestureRecognizer(target: self, action: #selector(photosLinkDidPress))
        photosLinkImage.addGestureRecognizer(photosTap)
        photosLinkImage.isUserInteractionEnabled = true
        
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
            isLandscape = true
        } else {
            log.verbose("### Detected change to: Portrait")
            isLandscape = false
            
        }
        //TODO: animate and maybe handle before rotation finishes
        self.removeSubviews()
        self.doLayout()
        
    }
    
    func removeSubviews(){
        for view in self.view.subviews {
            view.removeFromSuperview()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func exitScreen(){
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            suspend()
            dismiss(animated: true, completion:  { self.delegate?.blendGalleryCompleted() })
            return
        }
    }
    
    func loadPhotoThumbnail(view: UIImageView){
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        let last = fetchResult.lastObject
        
        if let lastAsset = last {
            let options = PHImageRequestOptions()
            options.version = .current
            
            PHImageManager.default().requestImage(
                for: lastAsset,
                targetSize: view.bounds.size,
                contentMode: .aspectFit,
                options: options,
                resultHandler: { image, _ in
                    DispatchQueue.main.async {
                        view.image = image!
                    }
            }
            )
        }
    }
    
    
    
    
    func updateSelectedImage(){
        DispatchQueue.main.async(execute: { () -> Void in
            self.selectedBlendImage.image = ImageManager.getBlendImage(name: self.selectedBlendImageName, size: self.imageSize)
            self.updateFilteredImage()
        })
    }
    
    
    
    
    // updates the filtered image view based on the currently selected blend image
    func updateFilteredImage(){
        
        blendInput?.removeAllTargets()
        selectedBlendImageSize = selectedBlendImage.frame.size
        selectedBlendImage?.image = ImageManager.getBlendImage(name:selectedBlendImageName, size: selectedBlendImageSize)
        blendInput  = PictureInput(image:(selectedBlendImage?.image)!)
        //blendInput  = ImageManager.getCurrentBlendInput()
        
        currDescriptor = filterManager.getFilterDescriptor(key: currFilterKey)
        //filteredImage = filterManager.getRenderView(key: currFilterKey)
        if (filteredImage == nil) {  filteredImage = RenderView() }
        filteredImage.frame.size = imageSize

        let descriptor = currDescriptor
        
        filterLabel.text = descriptor?.key

        guard (sampleInput != nil) else {
            log.error("NIL Sample Input")
            return
        }
        
        guard (blendInput != nil) else {
            log.error("NIL Blend Input")
            return
        }
        
        guard (descriptor != nil) else {
            log.error("NIL Filter Descriptor")
            return
        }
        
        guard (filteredImage != nil) else {
            log.error("NIL RenderView")
            return
        }
        
        //sampleInput?.removeAllTargets()
        //blendInput?.removeAllTargets()
        //descriptor?.filter?.removeAllTargets()
        //descriptor?.filterGroup?.removeAllTargets()
        
        // reduce opacity of blends by default
        if (opacityFilter == nil){
            opacityFilter = OpacityAdjustment()
            opacityFilter?.opacity = 0.8
        }
        
        // annoyingly, we have to treat single and multiple filters differently
        if (descriptor?.filter != nil){ // single filter
            let filter = descriptor?.filter
            filter?.removeAllTargets()
            
            //log.debug("Run filter: \((descriptor?.key)!) filter:\(Utilities.addressOf(filter)) view:\(Utilities.addressOf(renderView))")
            
            let opType:FilterOperationType = (descriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                log.debug("filter: \(descriptor?.key) address:\(Utilities.addressOf(filter))")
                //sampleInput! --> filter! --> self.renderView!
                sampleInput! --> filter! --> filteredImage!
                sampleInput?.processImage(synchronously: true)
                break
            case .blend:
                log.debug("BLEND filter: \(descriptor?.key) opacity:\(opacityFilter?.opacity)")
                sampleInput!.addTarget(filter!)
                blendInput! --> opacityFilter! --> filter!
                sampleInput! --> filter! --> filteredImage!
                blendInput?.processImage(synchronously: true)
                sampleInput?.processImage(synchronously: true)
                break
            }
            
        } else if (descriptor?.filterGroup != nil){ // group of filters
            let filterGroup = descriptor?.filterGroup
            filterGroup?.removeAllTargets()
            //log.debug("Run filterGroup: \(descriptor?.key) group:\(Utilities.addressOf(filterGroup)) view:\(Utilities.addressOf(renderView))")
            
            let opType:FilterOperationType = (descriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                log.debug("filterGroup: \(descriptor?.key)")
                sampleInput! --> filterGroup! --> filteredImage!
                sampleInput?.processImage(synchronously: true)
                break
            case .blend:
                log.debug("BLEND filter: \(descriptor?.key) opacity:\(opacityFilter?.opacity)")
                sampleInput!.addTarget(filterGroup!)
                blendInput! --> opacityFilter! --> filterGroup!
                sampleInput! --> filterGroup! --> filteredImage!
                blendInput?.processImage(synchronously: true)
                sampleInput?.processImage(synchronously: true)
                break
            }
        } else {
            log.error("ERR!!! shouldn't be here!!!")
        }
        
        
        filteredImage?.setNeedsDisplay()
        filteredView.setNeedsDisplay()
        
        //removeTargets()
    }
    
    
    
    /////////////////////////////
    // MARK: - Filter Management
    /////////////////////////////

    private func removeTargets(){
        sampleInput?.removeAllTargets()
        blendInput?.removeAllTargets()
        currDescriptor?.filter?.removeAllTargets()
        currDescriptor?.filterGroup?.removeAllTargets()
        opacityFilter?.removeAllTargets()
    }

    fileprivate func nextFilter(){
        removeTargets()
        currFilterIndex = (currFilterIndex + 1) % filterList.count
        currFilterKey = filterList[currFilterIndex]
        updateFilteredImage()
    }
    
    fileprivate func previousFilter(){
        removeTargets()
        currDescriptor?.filter?.removeAllTargets()
        currDescriptor?.filterGroup?.removeAllTargets()
        currFilterIndex = (currFilterIndex - 1)
        if (currFilterIndex<0) { currFilterIndex = filterList.count - 1 }
        currFilterKey = filterList[currFilterIndex]
        updateFilteredImage()
    }
    
    
    
    //////////////////////////////////////
    // MARK: - Gesture Detection
    //////////////////////////////////////
    
    
    func setGestureDetectors(_ view: UIView){
        
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
                
            default:
                log.debug("Unhandled gesture direction: \(swipeGesture.direction)")
                break
            }
        }
    }
    
    /////////////////////////////
    // MARK: - Touch Handler(s)
    /////////////////////////////
    
    func backDidPress(){
        log.verbose("Back pressed")
        exitScreen()
    }
    
    
    func acceptDidPress(){
        log.verbose("Accept pressed")
        ImageManager.setCurrentBlendImageName(selectedBlendImageName)
        exitScreen()
    }
    
    func cancelDidPress(){
        log.verbose("Cancel pressed")
        exitScreen()
    }
    
    func filterDidPress(){
        log.verbose("Filter pressed")
        nextFilter()
    }
    
    func photosLinkDidPress(){
        log.verbose("Photos pressed")
        DispatchQueue.main.async(execute: { () -> Void in
            // launch an ImagePicker
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .photoLibrary
            self.imagePicker.delegate = self
            self.present(self.imagePicker, animated: true, completion: nil)
        })
    }
    
    
    
    //////////////////////////////////////////
    // MARK: - ImagePicker handling
    //////////////////////////////////////////
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let imageRefURL = info[UIImagePickerControllerReferenceURL] as? NSURL {
            log.verbose("URL:\(imageRefURL)")
            self.selectedBlendImageName = imageRefURL.absoluteString!
            self.updateSelectedImage()
        } else {
            log.error("Error accessing image URL")
        }
        
        picker.dismiss(animated: true)
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    
    
    
}


//////////////////////////////////////////
// MARK: - Delegate methods for sub-views
//////////////////////////////////////////





extension BlendGalleryViewController: BlendGalleryViewDelegate {
    internal func imageSelected(name: String) {
        DispatchQueue.main.async(execute: { () -> Void in
            log.debug("Blend image selected: \(name)")
            self.selectedBlendImageName = name
            self.updateSelectedImage()
        })
    }
}



