//
//  FilterDetailsViewController.swift
//  FilterCam
//
//  Created by Philip Price on 10/27/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation

import UIKit
import GPUImage
import Neon
import AVFoundation
import MediaPlayer
import AudioToolbox

import GoogleMobileAds



private var filterList: [String] = []
private var filterCount: Int = 0

// This is the View Controller for displaying a filter with a sample image and exposing the controls (if any)

class FilterDetailsViewController: UIViewController {
    
    // this parameter should be set upon startup
    public var displayFilterDescriptor:FilterDescriptorInterface? = nil
    
    // Banner View (title)
    var bannerView: UIView! = UIView()
    var backButton:UIButton! = UIButton()
    var titleLabel:UILabel! = UILabel()
    
    
    // Advertisements View
    //var adView: GADBannerView! = GADBannerView()
    
    // Main Filtered Output View
    var filterDisplayView: FilterDisplayView! = FilterDisplayView()
    
    // The filter configuration subview
    var filterControlsView: FilterParametersView! = FilterParametersView()
    
    
    var filterManager: FilterManager? = FilterManager.sharedInstance
    var currFilterDescriptor:FilterDescriptorInterface? = nil
    
    var isLandscape : Bool = false
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    let bannerHeight : CGFloat = 64.0
    let buttonSize : CGFloat = 48.0
    
    
  
    var sampleImageFull:UIImage = UIImage(named:"sample_emma_01.png")!
    var blendImageFull:UIImage = UIImage(named:"bl_topaz_warm.png")!
    var initDone:Bool = false
    var sampleImage:UIImage? = nil
    var blendImage:UIImage? = nil
    var filteredImage:UIImage? = nil
    
    
    
    
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        doInit()
    }
    
    func doInit(){
        
        if (!FiltersViewController.initDone){
            
            FiltersViewController.initDone = true
        }
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
            
            log.verbose("h:\(displayHeight) w:\(displayWidth) landscape:\(isLandscape)")
            
            doInit()
            
            currFilterDescriptor = filterManager?.getSelectedFilter()
            if (currFilterDescriptor == nil){
                log.warning("NIL descriptor provided")
            } else {
                log.debug("descriptor:  \(currFilterDescriptor?.key)")
            }
            
            guard  (currFilterDescriptor != nil) else {
                log.error("!!! No descriptor provided !!!")
                return
            }
            
            // Note: need to add subviews before modifying constraints
            view.addSubview(bannerView)
            //view.addSubview(adView)
            view.addSubview(filterDisplayView)
            view.addSubview(filterControlsView)
            
            
            
            bannerView.frame.size.height = bannerHeight
            bannerView.frame.size.width = displayWidth
            layoutBanner()
            bannerView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: bannerHeight)
            
            
            //adView.frame.size.height = bannerHeight
            //adView.frame.size.width = displayWidth
            //adView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: adView.frame.size.height)
            
            // set up rest of layout based on orientation
            if (isLandscape){
                // left-to-right layout scheme
                
                filterDisplayView.frame.size.height = displayHeight - 2 * bannerHeight
                filterDisplayView.frame.size.width = displayWidth / 2
                filterDisplayView.anchorInCorner(.bottomLeft, xPad: 0, yPad: 0, width: filterDisplayView.frame.size.width, height: filterDisplayView.frame.size.height)
                
                // Align Overlay view to bottom of Render View
                filterControlsView.frame.size.height = displayHeight - 2 * bannerHeight
                filterControlsView.frame.size.width = displayWidth / 2
                filterControlsView.anchorInCorner(.bottomRight, xPad: 0, yPad: 0, width: filterControlsView.frame.size.width, height: filterControlsView.frame.size.height)
                
            } else {
                // Portrait: top-to-bottom layout scheme
                
                filterDisplayView.frame.size.height = (displayHeight - 2.0 * bannerHeight) * 0.7
                filterDisplayView.frame.size.width = displayWidth
                //filterDisplayView.align(.underCentered, relativeTo: adView, padding: 0, width: displayWidth, height: filterDisplayView.frame.size.height)
                filterDisplayView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: filterDisplayView.frame.size.height)
                
                filterControlsView.frame.size.height = (displayHeight - 2.0 * bannerHeight) * 0.3
                filterControlsView.frame.size.width = displayWidth
                filterControlsView.align(.underCentered, relativeTo: filterDisplayView, padding: 0, width: displayWidth, height: bannerView.frame.size.height)
            }
            
            
            // start Ads
            //setupAds()
            
            //filterDisplayView.setFilter(currFilterDescriptor)
            filterControlsView.setFilter(currFilterDescriptor)
            
            // that's it, rendering is handled by the FilterDisplayView and FilterControlsView classes
            
        }
        catch  let error as NSError {
            log.error ("Error detected: \(error.localizedDescription)");
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
        titleLabel.text = "Filter: " + (currFilterDescriptor?.title)!
        titleLabel.backgroundColor = UIColor.black
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
        titleLabel.textAlignment = .center
        
        
        backButton.anchorInCorner(.bottomLeft, xPad: 4, yPad: 4, width: backButton.frame.size.width, height: backButton.frame.size.height)
        titleLabel.align(.toTheRightCentered, relativeTo: backButton, padding: 0, width: titleLabel.frame.size.width, height: titleLabel.frame.size.height)
        
        backButton.addTarget(self, action: #selector(self.backDidPress), for: .touchUpInside)
        
    }
    
    /////////////////////////////
    // MARK: - Ad Framework
    /////////////////////////////
    /*
    fileprivate func setupAds(){
        log.debug("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        adView.adUnitID = admobID
        adView.rootViewController = self
        adView.load(GADRequest())
        adView.backgroundColor = UIColor.black
    }
    */
    
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
