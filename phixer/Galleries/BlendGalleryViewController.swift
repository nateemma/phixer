//
//  BlendGalleryViewController.swift
//  phixer
//
//  Created by Philip Price on 10/24/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import CoreImage
import Neon
import AVFoundation
import MediaPlayer
import AudioToolbox

import GoogleMobileAds

import Photos

import iCarousel



private var filterList: [String] = []
private var filterCount: Int = 0

// This is the View Controller for displaying and organising filters into categories

class BlendGalleryViewController: FilterBasedController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    // Title View
    fileprivate var titleView:TitleView! = TitleView()

    
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
    fileprivate var blendInput:CIImage? = nil
    
    fileprivate var photosLinkImage:UIImageView! = UIImageView()
    fileprivate var filteredImage:MetalImageView? = nil
    
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
    fileprivate var sampleInput:CIImage? = nil
    
    fileprivate let imagePicker = UIImagePickerController()
    
    fileprivate var filterManager:FilterManager = FilterManager.sharedInstance
    fileprivate var currDescriptor:FilterDescriptor? = nil
    fileprivate var filterList:[String] = []
    fileprivate var currFilterIndex:Int = 0
    fileprivate var currFilterKey:String = ""
    fileprivate var imageSize:CGSize = CGSize(width:96, height:96*3.0/2.0)
    
    fileprivate var showAds : Bool = true
    fileprivate var screenSize : CGRect = CGRect.zero
    fileprivate var displayWidth : CGFloat = 0.0
    fileprivate var displayHeight : CGFloat = 0.0
    
    fileprivate let bannerHeight : CGFloat = 64.0
    fileprivate let buttonSize : CGFloat = 48.0
    fileprivate let statusBarOffset : CGFloat = 2.0
    
    
    var theme = ThemeManager.currentTheme()
    
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        doInit()
    }
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Logging nicety, show that controller has changed:
        print ("\n========== \(String(describing: self)) ==========")

        // load theme here in case it changed
        theme = ThemeManager.currentTheme()

        // get display dimensions
        displayHeight = view.height
        displayWidth = view.width
        
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
        
        
        view.backgroundColor = theme.backgroundColor
        
        
        selectedBlendImageName = ImageManager.getCurrentBlendImageName()
        sampleImageName = ImageManager.getCurrentSampleImageName()
        sampleImage = UIImage(ciImage:ImageManager.getCurrentSampleImage()!)
        //sampleInput = CIImage(image:sampleImage!)
        sampleInput = ImageManager.getCurrentSampleInput()
        //filteredImage = filterManager.getRenderView(key: currFilterKey)
        if (filteredImage == nil) {  filteredImage = MetalImageView() }
      
        
        //set up dimensions
        
        titleView.frame.size.height = bannerHeight * 0.5
        titleView.frame.size.width = displayWidth
        titleView.title = "Select Blend Image"
        titleView.delegate = self

        
        if (showAds){
            adView.frame.size.height = bannerHeight
            adView.frame.size.width = displayWidth
            adView.layer.cornerRadius = 0.0
            adView.layer.borderWidth = 1.0
            adView.layer.borderColor = theme.borderColor.cgColor
        }
        
        infoView.frame.size.height = 4.2 * bannerHeight // TODO: calculate from components
        infoView.frame.size.width = displayWidth
        layoutInfoView()
        view.addSubview(infoView)
        
        if (showAds){
            blendGalleryView.frame.size.height = displayHeight - titleView.frame.size.height - adView.frame.size.height - infoView.frame.size.height
        } else {
            blendGalleryView.frame.size.height = displayHeight - titleView.frame.size.height - infoView.frame.size.height
        }
        blendGalleryView.frame.size.width = displayWidth
        //blendGalleryView.backgroundColor = theme.backgroundColor
        
        
        
        blendGalleryView.delegate = self
        view.addSubview(blendGalleryView)
        
        
        // Note: need to add subviews before modifying constraints
        view.addSubview(titleView)
        if (showAds){
            adView.isHidden = false
            adView.layer.borderColor = theme.borderColor.cgColor
            adView.layer.borderWidth = 1.0
            view.addSubview(adView)
        } else {
            log.debug("Not showing Ads in landscape mode")
            adView.isHidden = true
        }
        
        
        // layout constraints
        titleView.anchorAndFillEdge(.top, xPad: 0, yPad: statusBarOffset/2.0, otherSize: titleView.frame.size.height)
        
        if (showAds){
            adView.align(.underCentered, relativeTo: titleView, padding: 0, width: displayWidth, height: adView.frame.size.height)
            infoView.align(.underCentered, relativeTo: adView, padding: 0, width: displayWidth, height: infoView.frame.size.height)
        } else {
            infoView.align(.underCentered, relativeTo: titleView, padding: 0, width: displayWidth, height: infoView.frame.size.height)
        }
        
        blendGalleryView.align(.underCentered, relativeTo: infoView, padding: 0, width: displayWidth, height: blendGalleryView.frame.size.height)
        
        log.verbose("H: banner:\(titleView.frame.size.height) , ad:\(adView.frame.size.height), info:\(infoView.frame.size.height), gallery:\(blendGalleryView.frame.size.height)")
        
        // add delegates to sub-views (for callbacks)
        //titleView.delegate = self
        
        blendGalleryView.delegate = self
        
        
        
        // update the filtered image
        updateFilteredImage()
        
        // register gesture detection for Filter View
        setGestureDetectors(infoView) // restrict more?!
    }
    
    
    
    
    // layout the info view, which contains previews of the current and proposed selections, link to photos and accept/cancel buttons
    func layoutInfoView(){
        
        // Accept/Cancel Buttons
        for button in [acceptButton, cancelButton] {
            button?.frame.size.height = titleView.frame.size.height - 8
            button?.frame.size.width = 3.0 * (button?.frame.size.height)!
            button?.backgroundColor = theme.buttonColor
            button?.setTitleColor(theme.titleTextColor, for: .normal)
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
            label?.backgroundColor = theme.backgroundColor
            label?.textColor = theme.titleTextColor
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
        for image in [filteredImage, selectedBlendImage, photosLinkImage] as! [UIView]{
            image.frame.size = imageSize
            image.backgroundColor = theme.backgroundColor
            image.layer.cornerRadius = 0.0
            image.layer.borderWidth = 1.0
            image.layer.borderColor = theme.titleTextColor.cgColor
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
        filteredView.addSubview(filteredImage!)
        filteredView.addSubview(filterLabel)
        filteredImage?.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: imageSize.height)
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
        
        imageContainerView.groupInCenter(group: .horizontal, views: [selectedView, photosView, filteredView], padding: 8, width: filteredView.frame.size.width, height: filteredView.frame.size.height)
        imageContainerView.align(.underCentered, relativeTo: helpLabel, padding: 1, width: imageContainerView.frame.size.width, height: filteredView.frame.size.height)
        
        buttonContainerView.groupInCenter(group: .horizontal, views: [acceptButton, cancelButton], padding: 8, width: acceptButton.frame.size.width, height: acceptButton.frame.size.height)
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
     
    
    func exitScreen(){
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            suspend()
            dismiss(animated: true, completion:  { self.delegate?.filterControllerCompleted(tag:self.getTag()) })
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
        
        selectedBlendImageSize = selectedBlendImage.frame.size
        selectedBlendImage?.image = ImageManager.getBlendImage(name:selectedBlendImageName, size: selectedBlendImageSize)
        blendInput  = CIImage(image:(selectedBlendImage?.image)!)
        //blendInput  = ImageManager.getCurrentBlendInput()
        
        currDescriptor = filterManager.getFilterDescriptor(key: currFilterKey)
        //filteredImage = filterManager.getRenderView(key: currFilterKey)
        if (filteredImage == nil) {  filteredImage = MetalImageView() }
        filteredImage!.frame.size = imageSize
        
        filterLabel.text = currDescriptor?.title

        guard (sampleInput != nil) else {
            log.error("NIL Sample Input")
            return
        }
        
        guard (blendInput != nil) else {
            log.error("NIL Blend Input")
            return
        }
        
        guard (currDescriptor != nil) else {
            log.error("NIL Filter Descriptor")
            return
        }
        
        guard (filteredImage != nil) else {
            log.error("NIL RenderView")
            return
        }
        
        filteredImage?.image = currDescriptor?.apply(image: sampleInput, image2: blendInput)
        
        filteredImage?.setNeedsDisplay()
        filteredView.setNeedsDisplay()
        
        //removeTargets()
    }
    
    
    
    /////////////////////////////
    // MARK: - Filter Management
    /////////////////////////////


    override func nextFilter(){
        currFilterIndex = (currFilterIndex + 1) % filterList.count
        currFilterKey = filterList[currFilterIndex]
        updateFilteredImage()
    }
    
    override func previousFilter(){
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
                
            default:
                log.debug("Unhandled gesture direction: \(swipeGesture.direction)")
                break
            }
        }
    }
    
    /////////////////////////////
    // MARK: - Touch Handler(s)
    /////////////////////////////
    
    @objc func backDidPress(){
        log.verbose("Back pressed")
        exitScreen()
    }
    
    
    @objc func acceptDidPress(){
        log.verbose("Accept pressed")
        if (!self.selectedBlendImageName.isEmpty) {
            ImageManager.setCurrentBlendImageName(self.selectedBlendImageName)
        } else {
            log.error("NIL Blend Image Name")
        }
        exitScreen()
    }
    
    @objc func cancelDidPress(){
        log.verbose("Cancel pressed")
        exitScreen()
    }
    
    @objc func filterDidPress(){
        log.verbose("Filter pressed")
        nextFilter()
    }
    
    @objc func photosLinkDidPress(){
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
        /***
        if let imageRefURL = info[UIImagePickerControllerReferenceURL] as? NSURL {
            log.verbose("URL:\(imageRefURL)")
            self.selectedBlendImageName = imageRefURL.absoluteString!
            self.updateSelectedImage()
        } else {
            log.error("Error accessing image URL")
        }
        
        picker.dismiss(animated: true)
        ***/
        if let asset = info[UIImagePickerControllerPHAsset] as? PHAsset {
            let assetResources = PHAssetResource.assetResources(for: asset)
            
            let name = assetResources.first!.originalFilename
            let id = assetResources.first!.assetLocalIdentifier
            
            log.verbose("Picked image:\(name) id:\(id)")
            self.selectedBlendImageName = id
            self.updateSelectedImage()
        } else {
            log.error("Error accessing image data")
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


extension BlendGalleryViewController: TitleViewDelegate {
    func backPressed() {
        backDidPress()
    }
    
    func helpPressed() {
        let vc = HTMLViewController()
        vc.setTitle("Blend Gallery")
        vc.loadFile(name: "BlendGallery")
        present(vc, animated: true, completion: nil)
    }
    
    func menuPressed() {
        // placeholder
    }
}

