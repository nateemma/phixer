//
//  StyleTransferGalleryViewController.swift
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
import Photos

import GoogleMobileAds
//import Kingfisher



private var filterList: [String] = []
private var filterCount: Int = 0

// This is the View Controller for displaying Style Transfer models

class StyleTransferGalleryViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var theme = ThemeManager.currentTheme()
    
    // delegate for handling events
    weak var delegate: GalleryViewControllerDelegate?
    
    // operating mode, OK to set externally
    public var mode:GalleryControllerMode = .displaySelection

    
    // Banner View (title)
    var bannerView: TitleView! = TitleView()
    
    
    // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    
    // Image Selection (& save) view
    var imageSelectionView: ImageSelectionView! = ImageSelectionView()

    // Gallery of styled images
    var styleGalleryView : StyleTransferGalleryView! = StyleTransferGalleryView()
    
    
    // image picker for changing edit image
    let imagePicker = UIImagePickerController()

    // controller for displaying full screen version of filtered image
    fileprivate var filterDetailsViewController:FilterDetailsViewController? = nil
    
    var filterManager:FilterManager = FilterManager.sharedInstance
    
    
    var isLandscape : Bool = false
    var showAds : Bool = true
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    let bannerHeight : CGFloat = 64.0
    let buttonSize : CGFloat = 48.0
    let statusBarOffset : CGFloat = 2.0
    
    var currInputName:String = ""
    
    
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
        
        styleGalleryView.delegate = self

        // get orientation
        //isLandscape = UIDevice.current.orientation.isLandscape // doesn't always work properly, especially in simulator
        isLandscape = (displayWidth > displayHeight)
        
        doInit()
        
        currInputName = InputSource.getCurrentName()
        
        doLayout()
        
        // start Ads
        if (showAds){
            Admob.startAds(view:adView, viewController:self)
        }
        
        
    }
    
    
    
    static var initDone:Bool = false
    
    
    
    func doInit(){
        
        if (!StyleTransferGalleryViewController.initDone){
            StyleTransferGalleryViewController.initDone = true
        }
    }
    
    
    
    func suspend(){
        DispatchQueue.main.async(execute: { () -> Void in
            self.styleGalleryView.suspend()
        })
    }
    
    func update(){
        // redrawing is very expensive, so only do it if the input image changed
        if currInputName != InputSource.getCurrentName() {
            currInputName = InputSource.getCurrentName()
            DispatchQueue.main.async(execute: { () -> Void in
                self.styleGalleryView.reset()
                self.imageSelectionView.update()
            })
        }
    }
    
    func doLayout(){
        
        displayHeight = view.height
        displayWidth = view.width
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        showAds = (isLandscape == true) ? false : true // don't show in landscape mode (too cluttered)
        //showAds = false // debug
        
        
        view.backgroundColor = theme.backgroundColor // default seems to be white
        
        
        //top-to-bottom layout scheme
        
        layoutBanner()
        
        if (showAds){
            adView.frame.size.height = bannerHeight
            adView.frame.size.width = displayWidth
        }
        
        imageSelectionView.frame.size.height = CGFloat(bannerHeight)
        imageSelectionView.frame.size.width = displayWidth
        imageSelectionView.enableBlend(false)
        imageSelectionView.enableSave(false)
        imageSelectionView.delegate = self
        view.addSubview(imageSelectionView)

        
        if (showAds){
            styleGalleryView.frame.size.height = displayHeight - bannerView.frame.size.height - adView.frame.size.height - imageSelectionView.frame.size.height
        } else {
            styleGalleryView.frame.size.height = displayHeight - bannerView.frame.size.height - imageSelectionView.frame.size.height
        }
        styleGalleryView.frame.size.width = displayWidth
        styleGalleryView.backgroundColor = theme.backgroundColor
        styleGalleryView.isHidden = false
        styleGalleryView.delegate = self
        view.addSubview(styleGalleryView)
        
        
        // Note: need to add subviews before modifying constraints
        view.addSubview(bannerView)
        if (showAds){
            adView.isHidden = false
            view.addSubview(adView)
            adView.layer.borderColor = theme.borderColor.cgColor
            adView.layer.borderWidth = 1.0
        } else {
            log.debug("Not showing Ads")
            adView.isHidden = true
        }


        // layout constraints
        bannerView.anchorAndFillEdge(.top, xPad: 0, yPad: statusBarOffset/2.0, otherSize: bannerView.frame.size.height)

        if (showAds){
            adView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: adView.frame.size.height)
            imageSelectionView.align(.underCentered, relativeTo: adView, padding: 0, width: displayWidth, height: imageSelectionView.frame.size.height)
        } else {
            imageSelectionView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: imageSelectionView.frame.size.height)
        }

        styleGalleryView.anchorAndFillEdge(.bottom, xPad: 1, yPad: 1, otherSize: styleGalleryView.frame.size.height)
  
    }
 
    
    func layoutBanner(){
        bannerView.frame.size.height = bannerHeight
        bannerView.frame.size.width = displayWidth
        bannerView.backgroundColor = theme.backgroundColor
        bannerView.title = "Style Transfer Gallery"
        bannerView.delegate = self
    }
    
    
    fileprivate func isValidIndex(_ index:Int)->Bool{
        //return ((index>=0) && (index<styleGalleryView.count)) ? true : false
        return ((index>=0) && (index<filterManager.getCategoryCount())) ? true : false
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
        log.warning("Low Memory Warning")
        // Dispose of any resources that can be recreated.
    }
    
    
    
    open func saveImage(){
        if filterDetailsViewController != nil {
            filterDetailsViewController?.saveImage()
            AudioServicesPlaySystemSound(1108) // undocumented iOS feature!
        }
    }
    
    
    /////////////////////////////
    // MARK: - Touch Handler(s)
    /////////////////////////////
    
    @objc func backDidPress(){
        log.verbose("Back pressed")
        //_ = self.navigationController?.popViewController(animated: true)
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            suspend()
            dismiss(animated: true, completion:  {  self.delegate?.galleryCompleted() })
            return
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
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let asset = info[UIImagePickerControllerPHAsset] as? PHAsset {
            let assetResources = PHAssetResource.assetResources(for: asset)
            let name = assetResources.first!.originalFilename
            let id = assetResources.first!.assetLocalIdentifier
            
            log.verbose("Picked image:\(name) id:\(id)")
            ImageManager.setCurrentEditImageName(id)
            DispatchQueue.main.async(execute: { () -> Void in
                self.styleGalleryView.reset()
                self.imageSelectionView.update()
            })
        } else {
            log.error("Error accessing image data")
        }
        picker.dismiss(animated: true)
        
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    
} // StyleTransferGalleryViewController


//////////////////////////////////////////
// MARK: - Delegate methods for sub-views
//////////////////////////////////////////



extension StyleTransferGalleryViewController: StyleTransferGalleryViewDelegate {

    
    func filterSelected(_ descriptor:FilterDescriptor?){
        
        filterManager.setSelectedFilter(key: (descriptor?.key)!)
        if self.mode == .displaySelection {
            let filterDetailsViewController = FilterDetailsViewController()
            filterDetailsViewController.delegate = self
            filterDetailsViewController.currFilterKey = (descriptor?.key)!
            self.present(filterDetailsViewController, animated: false, completion: nil)
        } else {
            suspend()
            if (descriptor != nil) && (!(descriptor?.key.isEmpty)!){
                dismiss(animated: true, completion:  { self.delegate?.gallerySelection(key: (descriptor?.key)!) })
            } else {
                dismiss(animated: true, completion:  { self.delegate?.galleryCompleted() })
            }
        }        
    }
    
}



extension StyleTransferGalleryViewController: FilterDetailsViewControllerDelegate {
    func onCompletion(key:String){
        log.verbose("FilterDetailsView completed")
        self.update()
    }
    
    func prevFilter(){
        log.verbose("Previous Filter")
    }
    
    func nextFilter(){
        log.verbose("Next Filter")
    }
}



extension StyleTransferGalleryViewController: TitleViewDelegate {
    func backPressed() {
        backDidPress()
    }
}


// ImageSelectionViewDelegate
extension StyleTransferGalleryViewController: ImageSelectionViewDelegate {
    
    func changeImagePressed(){
        self.changeImage()
    }
    
    func changeBlendPressed() {
        // no blend image for style transfer, ignore
    }
    
    func savePressed() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.saveImage()
            log.verbose("Image saved")
            self.imageSelectionView.update()
        })
    }
    
}
