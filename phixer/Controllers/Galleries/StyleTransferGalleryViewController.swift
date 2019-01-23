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

class StyleTransferGalleryViewController: CoordinatedController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    
    // Gallery of styled images
    var styleGalleryView : StyleTransferGalleryView! = StyleTransferGalleryView()
    
    
    // image picker for changing edit image
    let imagePicker = UIImagePickerController()
    
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    
    var currInputName:String = ""
    
    
    
    /////////////////////////////
    // MARK: - Override Base Class functions
    /////////////////////////////
    
    // return the display title for this Controller
    override public func getTitle() -> String {
        return "Style Transfer Gallery"
    }
    
    // return the name of the help file associated with this Controller (without extension)
    override public func getHelpKey() -> String {
        return "StyleTransferGallery"
    }
    
    /////////////////////////////
    // INIT
    /////////////////////////////
    

    convenience init(){
        self.init(nibName:nil, bundle:nil)
        doInit()
    }
    
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // common setup
        self.prepController()

        // get display dimensions
        displayHeight = view.height
        displayWidth = view.width
        
        styleGalleryView.delegate = self
        
        doInit()
        
        currInputName = InputSource.getCurrentName()
        
        doLayout()
        
        // start Ads
        if (UISettings.showAds){
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
            })
        }
    }
    
    func doLayout(){
        
        displayHeight = view.height
        displayWidth = view.width
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        
        view.backgroundColor = theme.backgroundColor // default seems to be white
        
        
        //top-to-bottom layout scheme
        
        
        if (UISettings.showAds){
            adView.frame.size.height = UISettings.panelHeight
            adView.frame.size.width = displayWidth
        }
        
        
        if (UISettings.showAds){
            styleGalleryView.frame.size.height = displayHeight - UISettings.topBarHeight - adView.frame.size.height
        } else {
            styleGalleryView.frame.size.height = displayHeight - UISettings.topBarHeight
        }
        styleGalleryView.frame.size.width = displayWidth
        styleGalleryView.backgroundColor = theme.backgroundColor
        styleGalleryView.isHidden = false
        styleGalleryView.delegate = self
        view.addSubview(styleGalleryView)
        
        
        // Note: need to add subviews before modifying constraints
        if (UISettings.showAds){
            adView.isHidden = false
            view.addSubview(adView)
            adView.layer.borderColor = theme.borderColor.cgColor
            adView.layer.borderWidth = 1.0
        } else {
            log.debug("Not showing Ads")
            adView.isHidden = true
        }


        // layout constraints


        if (UISettings.showAds){
            adView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: adView.frame.size.height)
        }

        styleGalleryView.anchorAndFillEdge(.bottom, xPad: 1, yPad: 1, otherSize: styleGalleryView.frame.size.height)
  
    }
 
    
    
    fileprivate func isValidIndex(_ index:Int)->Bool{
        //return ((index>=0) && (index<styleGalleryView.count)) ? true : false
        return ((index>=0) && (index<filterManager.getCategoryCount())) ? true : false
    }
    
    
    
    /***
    open func saveImage(){
        if filterDetailsViewController != nil {
            filterDetailsViewController?.saveImage()
            AudioServicesPlaySystemSound(1108) // undocumented iOS feature!
        }
    }
    ***/
 
    
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
    
    
    private func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
            let assetResources = PHAssetResource.assetResources(for: asset)
            let name = assetResources.first!.originalFilename
            let id = assetResources.first!.assetLocalIdentifier
            
            log.verbose("Picked image:\(name) id:\(id)")
            ImageManager.setCurrentEditImageName(id)
            DispatchQueue.main.async(execute: { () -> Void in
                self.styleGalleryView.reset()
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
        
        filterManager.setCurrentFilterKey((descriptor?.key)!)
        self.coordinator?.selectFilterNotification(key: (descriptor?.key)!)
        //self.dismiss()

    }
    
}


