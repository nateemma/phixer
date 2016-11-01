//
//  CategoryManagerViewController.swift
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
import Kingfisher



private var filterList: [String] = []
private var filterCount: Int = 0

// This is the View Controller for displaying and organising filters into categories

class CategoryManagerViewController: UIViewController {
    
    // Banner View (title)
    var bannerView: UIView! = UIView()
    var backButton:UIButton! = UIButton()
    var titleLabel:UILabel! = UILabel()
    
    
    // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    
    // Category Selection View
    var categorySelectionView: CategorySelectionView!
    
    // Filter Gallery
    var filterGalleryView : FilterGalleryView! = FilterGalleryView()
    var filterManager:FilterManager = FilterManager.sharedInstance
    
    var currCategory:FilterManager.CategoryType = .none
    
    
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
    
    static var initDone:Bool = false
    
    func doInit(){
        
        if (!CategoryManagerViewController.initDone){
            CategoryManagerViewController.initDone = true
            ImageCache.default.clearMemoryCache() // for testing
            ImageCache.default.clearDiskCache() // for testing
            
        }
    }
    
    func doLayout(){
        
        displayHeight = view.height
        displayWidth = view.width
        log.verbose("h:\(displayHeight) w:\(displayWidth)")

        showAds = (isLandscape == true) ? false : true // don't show in landscape mode (too cluttered)
        //showAds = false // debug

        
        view.backgroundColor = UIColor.black // default seems to be white
        

        
        //top-to-bottom layout scheme
        
        bannerView.frame.size.height = bannerHeight * 0.75
        bannerView.frame.size.width = displayWidth
        bannerView.backgroundColor = UIColor.black
        
        
        layoutBanner()
        
        if (showAds){
            adView.frame.size.height = bannerHeight
            adView.frame.size.width = displayWidth
        }
        
        
        
        filterGalleryView.frame.size.height = displayHeight - bannerView.frame.size.height - 3.0 * bannerHeight - statusBarOffset
        filterGalleryView.frame.size.width = displayWidth
        filterGalleryView.backgroundColor = UIColor.black
        //filterGalleryView.reload()
        view.addSubview(filterGalleryView) // do this before categorySelectionView is assigned

        
        // Note: need to add subviews before modifying constraints
        view.addSubview(bannerView)
        if (showAds){
            adView.isHidden = false
            view.addSubview(adView)
        } else {
            log.debug("Not showing Ads in landscape mode")
            adView.isHidden = true
            //adView.removeFromSuperview()
        }
        
        
        categorySelectionView = CategorySelectionView()
        
        categorySelectionView.frame.size.height = 2.0 * bannerHeight
        categorySelectionView.frame.size.width = displayWidth
        categorySelectionView.backgroundColor = UIColor.black
        view.addSubview(categorySelectionView)

        // layout constraints
        bannerView.anchorAndFillEdge(.top, xPad: 0, yPad: statusBarOffset/2.0, otherSize: bannerView.frame.size.height)
        filterGalleryView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: filterGalleryView.frame.size.height)
        //filterGalleryView.align(.underCentered, relativeTo: categorySelectionView, padding: 0, width: displayWidth, height: filterGalleryView.frame.size.height)
        if (showAds){
            adView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: adView.frame.size.height)
            categorySelectionView.align(.underCentered, relativeTo: adView, padding: 0, width: displayWidth, height: categorySelectionView.frame.size.height)
        } else {
            categorySelectionView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: categorySelectionView.frame.size.height)
        }
}
    
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
        titleLabel.text = "Category/Filter Management"
        titleLabel.backgroundColor = UIColor.black
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
        titleLabel.textAlignment = .center
        
        
        backButton.anchorInCorner(.bottomLeft, xPad: 4, yPad: 4, width: backButton.frame.size.width, height: backButton.frame.size.height)
        titleLabel.align(.toTheRightCentered, relativeTo: backButton, padding: 0, width: titleLabel.frame.size.width, height: titleLabel.frame.size.height)
        
        backButton.addTarget(self, action: #selector(self.backDidPress), for: .touchUpInside)
        
    }
    


    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            
                        
            // get display dimensions
            displayHeight = view.height
            displayWidth = view.width
            
            
            // get orientation
            //isLandscape = UIDevice.current.orientation.isLandscape // doesn't always work properly, especially in simulator
            isLandscape = (displayWidth > displayHeight)
            
            currCategory = filterManager.getCurrentCategory()
            
            // initialisation workaroundm, set category to "none" during setup
            filterManager.setCurrentCategory(.none)
            
            doInit()
            
            doLayout()
           
            filterGalleryView.setCategory(.none)
            filterGalleryView.doLoadData()
           
            // start Ads
            if (showAds){
                setupAds()
            }
            
            //self.filterManager.setCurrentCategory(.none)
            //self.filterGalleryView.setCategory(.none)
            //self.categorySelectionView.setFilterCategory(.none)
          
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.filterManager.setCurrentCategory(self.currCategory)
                self.filterGalleryView.setCategory(self.currCategory)
                self.categorySelectionView.setFilterCategory(self.currCategory)
                self.categorySelectionView.update()
            }

            //view.bringSubview(toFront: categorySelectionView)
            
            // add delegates to sub-views (for callbacks)
            //bannerView.delegate = self
            categorySelectionView.delegate = self
            filterGalleryView.delegate = self
            
        }
        catch  let error as NSError {
            log.error ("Error detected: \(error.localizedDescription)");
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
    // MARK: - Ad Framework
    /////////////////////////////
    
    fileprivate func setupAds(){
        log.debug("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        adView.adUnitID = admobID
        adView.rootViewController = self
        adView.load(GADRequest())
        adView.backgroundColor = UIColor.darkGray
    }
    
    
    
    
    /////////////////////////////
    // MARK: - Touch Handler(s)
    /////////////////////////////
    
    func backDidPress(){
        log.verbose("Back pressed")
        //_ = self.navigationController?.popViewController(animated: true)
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            dismiss(animated: true, completion: nil)
            return
        }
    }
    
    
}


//////////////////////////////////////////
// MARK: - Delegate methods for sub-views
//////////////////////////////////////////

extension CategoryManagerViewController: CategorySelectionViewDelegate {
    func categorySelected(_ category:FilterManager.CategoryType){
        log.debug("Category Selected: \(category)")
        filterGalleryView.setCategory(category)
        currCategory = category
    }
    
}





extension CategoryManagerViewController: FilterGalleryViewDelegate {
    func filterSelected(_ descriptor:FilterDescriptorInterface?){
        filterManager.setSelectedFilter(key: (descriptor?.key)!)
        self.present(FilterDetailsViewController(), animated: false, completion: nil)
    }
}
