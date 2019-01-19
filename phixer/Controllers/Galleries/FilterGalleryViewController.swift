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

    
    // Banner View (title)
    var bannerView: TitleView! = TitleView()
    
    
    // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    
    // Category Selection View
    var categorySelectionView: CategorySelectionView!
    var currCategoryIndex = -1
    var currCategory:String = FilterManager.defaultCategory
    
    var filterGalleryView : FilterGalleryView! = FilterGalleryView()
    
    
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    let bannerHeight : CGFloat = 64.0
    let buttonSize : CGFloat = 48.0
    let statusBarOffset : CGFloat = 2.0
    
    
    
    
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
        if (showAds){
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
        
        showAds = (isLandscape == true) ? false : true // don't show in landscape mode (too cluttered)
        //showAds = false // debug
        
        
        view.backgroundColor = theme.backgroundColor // default seems to be white
        
        
        //top-to-bottom layout scheme
        
        layoutBanner()
        
        if (showAds){
            adView.frame.size.height = bannerHeight
            adView.frame.size.width = displayWidth
        }
        
        
        if (showAds){
            //filterView.frame.size.height = displayHeight - 3.75 * bannerHeight
            filterGalleryView.frame.size.height = displayHeight - 4.25 * bannerHeight
        } else {
            //filterView.frame.size.height = displayHeight - 2.75 * bannerHeight
            filterGalleryView.frame.size.height = displayHeight - 3.25 * bannerHeight
        }
        filterGalleryView.frame.size.width = displayWidth
        filterGalleryView.backgroundColor = theme.backgroundColor
        filterGalleryView.isHidden = true
        filterGalleryView.delegate = self
        view.addSubview(filterGalleryView) // do this before categorySelectionView is assigned
        
        
        // Note: need to add subviews before modifying constraints
        view.addSubview(bannerView)
        if (showAds){
            adView.isHidden = false
            view.addSubview(adView)
            adView.layer.borderColor = theme.borderColor.cgColor
            adView.layer.borderWidth = 1.0
        } else {
            log.debug("Not showing Ads in landscape mode")
            adView.isHidden = true
        }
        
        
        categorySelectionView = CategorySelectionView()
        
        categorySelectionView.frame.size.height = 1.5 * bannerHeight
        categorySelectionView.frame.size.width = displayWidth
        categorySelectionView.backgroundColor = theme.backgroundColor
        view.addSubview(categorySelectionView)


        // layout constraints
        bannerView.anchorAndFillEdge(.top, xPad: 0, yPad: statusBarOffset/2.0, otherSize: bannerView.frame.size.height)

        filterGalleryView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: filterGalleryView.frame.size.height)
        
        if (showAds){
            adView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: adView.frame.size.height)
            categorySelectionView.align(.underCentered, relativeTo: adView, padding: 0, width: displayWidth, height: categorySelectionView.frame.size.height)
        } else {
            categorySelectionView.align(.underMatchingLeft, relativeTo: bannerView, padding: 0, width: displayWidth, height: categorySelectionView.frame.size.height)
        }
  
        categorySelectionView.delegate = self

    }
 
    
    func layoutBanner(){
        bannerView.frame.size.height = bannerHeight
        bannerView.frame.size.width = displayWidth
        bannerView.backgroundColor = theme.backgroundColor
        bannerView.title = "Filter Gallery"
        bannerView.delegate = self
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
        
    
    
    
    /////////////////////////////
    // MARK: - Touch Handler(s)
    /////////////////////////////
    
    @objc func backDidPress(){
        log.verbose("Back pressed")
        suspend()
        self.dismiss()
        return
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




extension FilterGalleryViewController: TitleViewDelegate {
    
    func backPressed() {
        backDidPress()
    }
    
    func helpPressed() {
        let vc = HTMLViewController()
        vc.setTitle("Filter Gallery")
        vc.loadFile(name: "FilterGallery")
        present(vc, animated: true, completion: nil)    }
    
    func menuPressed() {
        // placeholder
    }
}

