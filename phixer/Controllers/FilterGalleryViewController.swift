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




// delegate method to let the launching ViewController know that this one has finished
protocol FilterGalleryViewControllerDelegate: class {
    func filterGalleryCompleted()
}


private var filterList: [String] = []
private var filterCount: Int = 0

// This is the View Controller for displaying and organising filters into categories

class FilterGalleryViewController: UIViewController {
    
    // delegate for handling events
    weak var delegate: FilterGalleryViewControllerDelegate?
    
    
    // Banner View (title)
    var bannerView: TitleView! = TitleView()
    
    
    // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    
    // Category Selection View
    var categorySelectionView: CategorySelectionView!
    var currCategoryIndex = -1
    var currCategory:String = FilterManager.defaultCategory
    
    // Filter Galleries (one per category).
    var filterGalleryView : [FilterGalleryView] = []
    
    
    var filterManager:FilterManager = FilterManager.sharedInstance
    
    
    var isLandscape : Bool = false
    var showAds : Bool = true
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    let bannerHeight : CGFloat = 64.0
    let buttonSize : CGFloat = 48.0
    let statusBarOffset : CGFloat = 12.0
    
    
    
    
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
        
        
        // set up initial Category
        currCategory = filterManager.getCurrentCategory()
        selectCategory(currCategory)
        categorySelectionView.setFilterCategory(currCategory)
        
        
    }
    
    
    
    static var initDone:Bool = false
    
    
    
    func doInit(){
        
        if (!FilterGalleryViewController.initDone){
            FilterGalleryViewController.initDone = true
            
            //ImageCache.default.clearMemoryCache() // for testing
            //ImageCache.default.clearDiskCache() // for testing
            
            loadGalleries()
        }
    }
    
    
    
    func suspend(){
        DispatchQueue.main.async(execute: { () -> Void in
            for filterView in self.filterGalleryView{
                filterView.suspend()
            }
        })
    }
    
    func loadGalleries(){
        // create an array of FilterGalleryViews and assign a category to each one
        filterGalleryView = []
        let count = filterManager.getCategoryCount()
        for _ in 0...count {
            filterGalleryView.append(FilterGalleryView())
        }
    }
    
    func doLayout(){
        
        displayHeight = view.height
        displayWidth = view.width
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        showAds = (isLandscape == true) ? false : true // don't show in landscape mode (too cluttered)
        //showAds = false // debug
        
        
        view.backgroundColor = UIColor.black // default seems to be white
        
        //HACK: double-check that category data is loaded
        if (filterGalleryView.count==0) {
            loadGalleries()
        }
    
        
        //top-to-bottom layout scheme
        
        bannerView.frame.size.height = bannerHeight * 0.75
        bannerView.frame.size.width = displayWidth
        bannerView.backgroundColor = UIColor.black
        
        
        layoutBanner()
        
        if (showAds){
            adView.frame.size.height = bannerHeight
            adView.frame.size.width = displayWidth
        }
        
        
        // setup Galleries
        for filterView in filterGalleryView{
            if (showAds){
                filterView.frame.size.height = displayHeight - 3.75 * bannerHeight
            } else {
                filterView.frame.size.height = displayHeight - 2.75 * bannerHeight
            }
            filterView.frame.size.width = displayWidth
            filterView.backgroundColor = UIColor.black
            filterView.isHidden = true
            filterView.delegate = self
            view.addSubview(filterView) // do this before categorySelectionView is assigned
        }
        
        
        // Note: need to add subviews before modifying constraints
        view.addSubview(bannerView)
        if (showAds){
            adView.isHidden = false
            view.addSubview(adView)
        } else {
            log.debug("Not showing Ads in landscape mode")
            adView.isHidden = true
        }
        
        
        categorySelectionView = CategorySelectionView()
        
        categorySelectionView.frame.size.height = 2.0 * bannerHeight
        categorySelectionView.frame.size.width = displayWidth
        categorySelectionView.backgroundColor = UIColor.black
        view.addSubview(categorySelectionView)
        
        // layout constraints
        bannerView.anchorAndFillEdge(.top, xPad: 0, yPad: statusBarOffset/2.0, otherSize: bannerView.frame.size.height)
        for filterView in filterGalleryView{
            filterView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: filterView.frame.size.height)
        }
        
        if (showAds){
            adView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: adView.frame.size.height)
            categorySelectionView.align(.underCentered, relativeTo: adView, padding: 0, width: displayWidth, height: categorySelectionView.frame.size.height)
        } else {
            categorySelectionView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: categorySelectionView.frame.size.height)
        }
        
        
        // add delegates to sub-views (for callbacks)
        //bannerView.delegate = self
        
        categorySelectionView.delegate = self
        for gallery in filterGalleryView{
            gallery.delegate = self
        }
        
    }
    
    func layoutBanner(){
        bannerView.frame.size.height = bannerHeight * 0.5
        bannerView.frame.size.width = displayWidth
        bannerView.title = "Filter Gallery"
        bannerView.delegate = self
    }
    
    
    fileprivate func isValidIndex(_ index:Int)->Bool{
        return ((index>=0) && (index<filterGalleryView.count)) ? true : false
    }
    
    fileprivate func selectCategory(_ category:String){
        DispatchQueue.main.async(execute: { () -> Void in
            
            
            let index = self.filterManager.getCategoryIndex(category: category)
            
            guard (self.filterGalleryView.count > 0) else {
                log.error("Galleries not initialised!")
                return
            }
            
            if (self.isValidIndex(index)){
                if (index != self.currCategoryIndex){
                    log.debug("Category Selected: \(category) (\(self.currCategoryIndex)->\(index))")
                    if (self.isValidIndex(self.currCategoryIndex)) {
                        self.filterGalleryView[self.currCategoryIndex].isHidden = true
                        self.filterGalleryView[self.currCategoryIndex].suspend()
                    }
                    self.filterGalleryView[index].setCategory(self.filterManager.getCategory(index: index))
                    self.currCategory = category
                    self.currCategoryIndex = index
                    self.filterGalleryView[index].isHidden = false
                } else {
                    if (self.isValidIndex(self.currCategoryIndex)) { self.filterGalleryView[self.currCategoryIndex].isHidden = false } // re-display just in case (e.g. could be a rotation)
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
            filterGalleryView[index].update()
        }
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
    
    
    
    
    /////////////////////////////
    // MARK: - Touch Handler(s)
    /////////////////////////////
    
    @objc func backDidPress(){
        log.verbose("Back pressed")
        //_ = self.navigationController?.popViewController(animated: true)
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            suspend()
            dismiss(animated: true, completion:  { self.delegate?.filterGalleryCompleted() })
            return
        }
    }
    
    
}


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
        filterManager.setSelectedCategory(currCategory)
        filterManager.setSelectedFilter(key: (descriptor?.key)!)
        let filterDetailsViewController = FilterDetailsViewController()
        filterDetailsViewController.delegate = self
        filterDetailsViewController.currFilterKey = (descriptor?.key)!
        self.present(filterDetailsViewController, animated: false, completion: nil)
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



extension FilterGalleryViewController: FilterDetailsViewControllerDelegate {
    func onCompletion(key:String){
        //DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {() -> Void in
        DispatchQueue.main.async(execute: {() -> Void in
            log.verbose("FilterDetailsView completed")
            self.updateCategoryDisplay(self.currCategory)
        })
    }
    
    func prevFilter(){
        log.verbose("Previous Filter")
    }
    
    func nextFilter(){
        log.verbose("Next Filter")
    }
}



extension FilterGalleryViewController: TitleViewDelegate {
    func backPressed() {
        backDidPress()
    }
}

