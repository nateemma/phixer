//
//  CategoryGalleryViewController.swift
//  phixer
//
//  Created by Philip Price on 10/24/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import CoreImage
import Neon
import AVFoundation
//import MediaPlayer
//import AudioToolbox

import GoogleMobileAds





private var filterList: [String] = []
private var filterCount: Int = 0

// This is the View Controller for displaying the categories within a collection

class CategoryGalleryViewController: CoordinatedController {

    
    
    // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    
    var currCollectionIndex = -1
    var currCollection:String = FilterManager.defaultCollection
    
    var categoryGalleryView : CategoryGalleryView! = CategoryGalleryView()
    
    
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    
    
    /////////////////////////////
    // MARK: - Override Base Class functions
    /////////////////////////////
    
    // return the display title for this Controller
    override public func getTitle() -> String {
        return self.filterManager.getCollectionTitle(key: currCollection)
    }
    
    // return the name of the help file associated with this Controller (without extension)
    override public func getHelpKey() -> String {
        return "CategoryGallery"
    }
    
    
    override public func end() {
        categoryGalleryView.suspend()
        categoryGalleryView = nil // force deallocation
        self.dismiss()
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
        
        categoryGalleryView.delegate = self

        
        doInit()
        
        doLayout()
        
        // start Ads
        if (UISettings.showAds){
            Admob.startAds(view:adView, viewController:self)
        }
        
        
        // set up initial Collection
        currCollection = filterManager.getCurrentCollection()
        selectCollection(currCollection)
        
    }
    
    
    
    static var initDone:Bool = false
    
    
    
    func doInit(){
        
        if (!CategoryGalleryViewController.initDone){
            CategoryGalleryViewController.initDone = true
        }
    }

    
    
    func suspend(){
        DispatchQueue.main.async(execute: { () -> Void in
            self.categoryGalleryView.suspend()
        })
    }
    
    
    
    func doLayout(){
        
        displayHeight = view.height
        displayWidth = view.width
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        UISettings.showAds = (UISettings.isLandscape == true) ? false : true // don't show in landscape mode (too cluttered)
        //UISettings.showAds = false // debug
        
        
        view.backgroundColor = theme.backgroundColor // default seems to be white
        
        
        //top-to-bottom layout scheme
        
        if (UISettings.showAds){
            adView.frame.size.height = UISettings.panelHeight
            adView.frame.size.width = displayWidth
            adView.isHidden = false

            adView.layer.borderColor = theme.borderColor.cgColor
            adView.layer.borderWidth = 1.0
             view.addSubview(adView)
        } else {
            log.debug("Not showing Ads in landscape mode")
            adView.frame.size.height = 0
            adView.isHidden = true
        }
        
        
        
        
        if (UISettings.showAds){
            categoryGalleryView.frame.size.height = displayHeight - adView.frame.size.height
        } else {
             categoryGalleryView.frame.size.height = displayHeight
        }
        categoryGalleryView.frame.size.width = displayWidth
        categoryGalleryView.backgroundColor = theme.backgroundColor
        categoryGalleryView.isHidden = true
        categoryGalleryView.delegate = self
        view.addSubview(categoryGalleryView) // do this before collectionSelectionView is assigned
        
        // layout constraints
       
        if (UISettings.showAds){
            adView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: adView.frame.size.height)
            categoryGalleryView.align(.underCentered, relativeTo: adView, padding: 0, width: displayWidth, height: categoryGalleryView.frame.size.height)
        } else {
            categoryGalleryView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: categoryGalleryView.frame.size.height)
        }
  
    }
    
    
    fileprivate func isValidIndex(_ index:Int)->Bool{
        //return ((index>=0) && (index<categoryGalleryView.count)) ? true : false
        return ((index>=0) && (index<filterManager.getCollectionCount())) ? true : false
    }
    
    
    fileprivate func selectCollection(_ collection:String){
        DispatchQueue.main.async(execute: { () -> Void in
            
            
            let index = self.filterManager.getCollectionIndex(collection: collection)
            
            log.debug("Collection Selected: \(collection) (\(self.currCollectionIndex)->\(index))")
            
            if (self.isValidIndex(index)){
                if (index != self.currCollectionIndex){

                    self.currCollection = collection
                    self.currCollectionIndex = index
                    self.categoryGalleryView.suspend()
                    self.categoryGalleryView.setCollection(self.filterManager.getCollection(index: index))
                    self.categoryGalleryView.isHidden = false
                } else {
                    if (self.isValidIndex(self.currCollectionIndex)) { self.categoryGalleryView.isHidden = false } // re-display just in case (e.g. could be a rotation)
                    log.debug("Ignoring collection change \(self.currCollectionIndex)->\(index)")
                }

            } else {
                log.warning("Invalid index: \(index)")
            }
        })
    }
    
    
    fileprivate func updateCollectionDisplay(_ collection:String){
        let index = filterManager.getCollectionIndex(collection: collection)
        if (isValidIndex(index)){
            categoryGalleryView.update()
        }
    }
    


} // CategoryGalleryViewController


//////////////////////////////////////////
// MARK: - Delegate methods for sub-views
//////////////////////////////////////////


extension CategoryGalleryViewController: CategoryGalleryViewDelegate {
    func categorySelected(category:String){
        suspend()
        filterManager.setCurrentCollection(currCollection)
        filterManager.setCurrentCategory(category)
        
        self.coordinator?.activateRequest(id: ControllerIdentifier.browseFilters)
        //self.dismiss()
    }
    
    func filterSelected(category:String, key:String){
        suspend()
        filterManager.setCurrentCollection(currCollection)
        filterManager.setCurrentCategory(category)
        filterManager.setCurrentFilterKey(key)
        EditManager.addPreviewFilter(filterManager.getFilterDescriptor(key: key))
        self.coordinator?.activateRequest(id: ControllerIdentifier.edit)
        //self.coordinator?.selectFilterNotification(key: key)
        //self.dismiss()
    }
    
    func requestUpdate(collection:String){
        DispatchQueue.main.async(execute: {() -> Void in
            log.debug("Update requested for collection: \(collection)")
            self.updateCollectionDisplay(collection)
        })
    }
    
}



