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


// delegate method to let the launcing ViewController know that this one has finished
protocol FilterDetailsViewControllerDelegate: class {
    func onCompletion(key:String)
}



// This is the View Controller for displaying a filter with a sample image and exposing the controls (if any)

class FilterDetailsViewController: UIViewController {
    
    // delegate for handling events
    weak var delegate: FilterDetailsViewControllerDelegate?
    
    open var filterKey: String = ""
    
    // Banner View (title)
    fileprivate var bannerView: UIView! = UIView()
    fileprivate var backButton:UIButton! = UIButton()
    fileprivate var titleLabel:UILabel! = UILabel()
    
    
    // Advertisements View
    //var adView: GADBannerView! = GADBannerView()
    
    // Main Filtered Output View
    fileprivate var filterDisplayView: FilterDisplayView! = FilterDisplayView()
    
    // The filter configuration subview
    fileprivate var filterControlsView: FilterParametersView! = FilterParametersView()
    
    
    fileprivate var filterManager: FilterManager? = FilterManager.sharedInstance
    fileprivate var currFilterKey:String = ""
    fileprivate var currFilterDescriptor:FilterDescriptorInterface? = nil
    
    fileprivate var isLandscape : Bool = false
    fileprivate var screenSize : CGRect = CGRect.zero
    fileprivate var displayWidth : CGFloat = 0.0
    fileprivate var displayHeight : CGFloat = 0.0
    
    fileprivate let bannerHeight : CGFloat = 64.0
    fileprivate let buttonSize : CGFloat = 48.0
    
    fileprivate var initDone:Bool = false
    
    
    
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        doInit()
    }
    
    
    deinit{
        suspend()
    }
    
    
    
    func doInit(){
        
        if (!initDone){
            initDone = true
        }
    }
    
    func suspend(){
        filterDisplayView.suspend()
    }
    
    func update(){
        setupDisplay()
        setupConstraints()
        filterDisplayView.setFilter(key: currFilterKey)
        //filterDisplayView.update()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        log.verbose("filterKey:\(filterKey)")
        
        // get display dimensions
        displayHeight = view.height
        displayWidth = view.width
        
        
        // get orientation
        //isLandscape = UIDevice.current.orientation.isLandscape // doesn't always work properly, especially in simulator
        isLandscape = (displayWidth > displayHeight)
        
        log.verbose("h:\(displayHeight) w:\(displayWidth) landscape:\(isLandscape)")
        
        doInit()
        
        currFilterKey = (filterManager?.getSelectedFilter())!
        currFilterDescriptor = filterManager?.getFilterDescriptor(key: currFilterKey)
        if (currFilterDescriptor == nil){
            log.warning("NIL descriptor provided")
        } else {
            log.debug("descriptor:  \(currFilterDescriptor?.key)")
        }
        
        guard  (currFilterDescriptor != nil) else {
            log.error("!!! No descriptor provided !!!")
            return
        }
        

        doLayout()
        
        
        // start Advertisements
        //startAds()
        
        // that's it, rendering is handled by the FilterDisplayView and FilterControlsView classes
        
    }
    
    
    fileprivate func doLayout(){
        // Note: need to add subviews before modifying constraints
        
        setupBanner()
        //view.addSubview(adView)
        setupDisplay()
        setupControls()
        
        setupConstraints()
        filterDisplayView.setFilter(key: currFilterKey)
        filterControlsView.setFilter(currFilterDescriptor)
        
        filterControlsView.delegate = self
    }
    
    
    fileprivate func setupBanner(){
        
        bannerView.frame.size.height = bannerHeight
        bannerView.frame.size.width = displayWidth
        bannerView.backgroundColor = UIColor.flatBlack() // temp debug
        
        
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
        titleLabel.text = "Filter Gallery"
        titleLabel.backgroundColor = UIColor.black
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
        titleLabel.textAlignment = .center
        
        
        backButton.anchorInCorner(.bottomLeft, xPad: 4, yPad: 4, width: backButton.frame.size.width, height: backButton.frame.size.height)
        titleLabel.align(.toTheRightCentered, relativeTo: backButton, padding: 0, width: titleLabel.frame.size.width, height: titleLabel.frame.size.height)
        
        backButton.addTarget(self, action: #selector(self.backDidPress), for: .touchUpInside)
        
    }
    
    fileprivate func setupDisplay(){
        if (filterDisplayView != nil) { filterDisplayView.removeFromSuperview() }
        filterDisplayView = FilterDisplayView() // create new one each time, doesn't seem to update properly
    }
    
    fileprivate func setupControls(){
    }
    
    
    fileprivate func setupConstraints(){
        
        
        view.addSubview(bannerView)
        view.addSubview(filterDisplayView)
        view.addSubview(filterControlsView)
        
        bannerView.frame.size.height = bannerHeight
        bannerView.frame.size.width = displayWidth
        bannerView.anchorAndFillEdge(.top, xPad: 0, yPad: 4, otherSize: bannerView.frame.size.height)
        //bannerView.anchorInCorner(.topLeft, xPad: 0, yPad: 4, width: bannerView.frame.size.width, height: bannerView.frame.size.height)
        log.verbose("Banner: \((titleLabel.text)!) w:\(bannerView.frame.size.width) h:\(bannerView.frame.size.height)")
        
        //adView.frame.size.height = bannerHeight
        //adView.frame.size.width = displayWidth
        //adView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: adView.frame.size.height)
        
        // set up rest of layout based on orientation
        if (isLandscape){
            // left-to-right layout scheme
            
            filterDisplayView.frame.size.height = displayHeight - bannerHeight
            filterDisplayView.frame.size.width = displayWidth / 2
            filterDisplayView.anchorInCorner(.bottomLeft, xPad: 0, yPad: 0, width: filterDisplayView.frame.size.width, height: filterDisplayView.frame.size.height)
            
            // Align Overlay view to bottom of Render View
            filterControlsView.frame.size.height = displayHeight - bannerHeight
            filterControlsView.frame.size.width = displayWidth / 2
            filterControlsView.anchorInCorner(.bottomRight, xPad: 0, yPad: 0, width: filterControlsView.frame.size.width, height: filterControlsView.frame.size.height)
            
        } else {
            // Portrait: top-to-bottom layout scheme
            
            if (currFilterDescriptor != nil) {
                filterControlsView.frame.size.height = CGFloat(((currFilterDescriptor?.numParameters)! + 1)) * bannerHeight * 0.75
            } else {
                filterControlsView.frame.size.height = (displayHeight - 2.0 * bannerHeight) * 0.3
            }
            filterControlsView.frame.size.width = displayWidth
            //filterControlsView.align(.underCentered, relativeTo: filterDisplayView, padding: 4, width: displayWidth, height: bannerView.frame.size.height)
            filterControlsView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 4, otherSize: filterControlsView.frame.size.height)
            
            filterDisplayView.frame.size.height = displayHeight - bannerHeight - filterControlsView.frame.size.height - 4
            filterDisplayView.frame.size.width = displayWidth
            //filterDisplayView.align(.underCentered, relativeTo: adView, padding: 0, width: displayWidth, height: filterDisplayView.frame.size.height)
            filterDisplayView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: filterDisplayView.frame.size.height)
        }
        
    }
    
    
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        displayHeight = view.height
        displayWidth = view.width
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
    
    /////////////////////////////
    // MARK: - Ad Framework
    /////////////////////////////
    /*
     fileprivate func startAds(){
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
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            suspend()
            dismiss(animated: true, completion: { self.delegate?.onCompletion(key: self.currFilterKey) })
            return
        }
    }
}


//////////////////////////////////////////
// MARK: - Delegate methods for sub-views
//////////////////////////////////////////



extension FilterDetailsViewController: FilterParametersViewDelegate {
    
    func settingsChanged(){
        log.debug("Filter settings changed")
        self.update()
    }
}

