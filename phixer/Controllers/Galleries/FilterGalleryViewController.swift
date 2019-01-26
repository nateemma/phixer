//
//  FilterGalleryViewController.swift
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
//import Kingfisher





private var filterList: [String] = []
private var filterCount: Int = 0

// This is the View Controller for displaying and organising filters into categories

class FilterGalleryViewController: CoordinatedController {

    
    
    // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    
    // Category Selection View
    var categorySelectionView: CategorySelectionView!
    var currCategoryIndex = -1
    var currCategory:String = FilterManager.defaultCategory
    
    var filterGalleryView : FilterGalleryView! = FilterGalleryView()
    
    
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    
    
    /////////////////////////////
    // MARK: - Override Base Class functions
    /////////////////////////////
    
    // return the display title for this Controller
    override public func getTitle() -> String {
        return "Filter Gallery"
    }
    
    // return the name of the help file associated with this Controller (without extension)
    override public func getHelpKey() -> String {
        return "FilterGallery"
    }
    
    
    override public func end() {
        filterGalleryView = nil // force deallocation
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
        
        filterGalleryView.delegate = self

        
        doInit()
        
        doLayout()
        
        // start Ads
        if (UISettings.showAds){
            Admob.startAds(view:adView, viewController:self)
        }
        
        
        // set up initial Category
        currCategory = filterManager.getCurrentCategory()
        selectCategory(currCategory)
        categorySelectionView.setFilterCategory(currCategory)
        
    }
    
    
    
    static var initDone:Bool = false
    
    
    
    func doInit(){
        
        if (!FilterGalleryViewController.initDone){
            FilterGalleryViewController.initDone = true
        }
    }

    
    
    func suspend(){
        DispatchQueue.main.async(execute: { () -> Void in
            self.filterGalleryView.suspend()
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
        
        
        categorySelectionView = CategorySelectionView()
        
        categorySelectionView.frame.size.height = UISettings.menuHeight + UISettings.titleHeight
        categorySelectionView.frame.size.width = displayWidth
        categorySelectionView.backgroundColor = theme.backgroundColor
        view.addSubview(categorySelectionView)

        
        
        if (UISettings.showAds){
            filterGalleryView.frame.size.height = displayHeight - adView.frame.size.height - categorySelectionView.frame.size.height
        } else {
             filterGalleryView.frame.size.height = displayHeight - categorySelectionView.frame.size.height
        }
        filterGalleryView.frame.size.width = displayWidth
        filterGalleryView.backgroundColor = theme.backgroundColor
        filterGalleryView.isHidden = true
        filterGalleryView.delegate = self
        view.addSubview(filterGalleryView) // do this before categorySelectionView is assigned
        
        // layout constraints
       
        if (UISettings.showAds){
            adView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: adView.frame.size.height)
            categorySelectionView.align(.underCentered, relativeTo: adView, padding: 0, width: displayWidth, height: categorySelectionView.frame.size.height)
        } else {
            categorySelectionView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: categorySelectionView.frame.size.height)
        }
  
        filterGalleryView.align(.underCentered, relativeTo: categorySelectionView, padding: 8, width: displayWidth, height: filterGalleryView.frame.size.height)
        //filterGalleryView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: filterGalleryView.frame.size.height)
        
        categorySelectionView.delegate = self

    }
    
    
    fileprivate func isValidIndex(_ index:Int)->Bool{
        //return ((index>=0) && (index<filterGalleryView.count)) ? true : false
        return ((index>=0) && (index<filterManager.getCategoryCount())) ? true : false
    }
    
    
    fileprivate func selectCategory(_ category:String){
        DispatchQueue.main.async(execute: { () -> Void in
            
            
            let index = self.filterManager.getCategoryIndex(category: category)
            
            log.debug("Category Selected: \(category) (\(self.currCategoryIndex)->\(index))")
            
            if (self.isValidIndex(index)){
                if (index != self.currCategoryIndex){

                    self.currCategory = category
                    self.currCategoryIndex = index
                    self.filterGalleryView.suspend()
                    self.filterGalleryView.setCategory(self.filterManager.getCategory(index: index))
                    self.filterGalleryView.isHidden = false
                } else {
                    if (self.isValidIndex(self.currCategoryIndex)) { self.filterGalleryView.isHidden = false } // re-display just in case (e.g. could be a rotation)
                    log.debug("Ignoring category change \(self.currCategoryIndex)->\(index)")
                }

                self.categorySelectionView.setFilterCategory(self.currCategory)
            } else {
                log.warning("Invalid index: \(index)")
            }
        })
    }
    
    
    fileprivate func updateCategoryDisplay(_ category:String){
        let index = filterManager.getCategoryIndex(category: category)
        if (isValidIndex(index)){
            filterGalleryView.update()
        }
    }
    


} // FilterGalleryViewController


//////////////////////////////////////////
// MARK: - Delegate methods for sub-views
//////////////////////////////////////////

extension FilterGalleryViewController: CategorySelectionViewDelegate {
    func categorySelected(_ category:String){
        selectCategory(category)
    }
    
}





extension FilterGalleryViewController: FilterGalleryViewDelegate {
    func filterSelected(_ descriptor:FilterDescriptor?){
        //suspend()
        filterManager.setCurrentCategory(currCategory)
        filterManager.setCurrentFilterKey((descriptor?.key)!)
        
        self.coordinator?.selectFilterNotification(key: (descriptor?.key)!)
        //self.dismiss()
    }
    
    func requestUpdate(category:String){
        DispatchQueue.main.async(execute: {() -> Void in
            log.debug("Update requested for category: \(category)")
            self.updateCategoryDisplay(category)
        })
    }
    
    func setHidden(key:String, hidden:Bool){
        self.filterManager.setHidden(key:key, hidden:hidden)
        DispatchQueue.main.async(execute: {() -> Void in
            self.updateCategoryDisplay(self.currCategory)
        })
    }
    
    func setFavourite(key:String, fav:Bool){
        if (fav){
            self.filterManager.addToFavourites(key:key)
        } else {
            self.filterManager.removeFromFavourites(key:key)
        }
        DispatchQueue.main.async(execute: {() -> Void in
            self.updateCategoryDisplay(self.currCategory)
        })
    }
    
    func setRating(key:String, rating:Int){
        self.filterManager.setRating(key:key, rating:rating)
        DispatchQueue.main.async(execute: {() -> Void in
            self.updateCategoryDisplay(self.currCategory)
        })
    }
}



