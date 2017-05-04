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
    func prevFilter()
    func nextFilter()
}



// This is the View Controller for displaying a filter with a sample image and exposing the controls (if any)

class FilterDetailsViewController: UIViewController {
    
    // delegate for handling events
    weak var delegate: FilterDetailsViewControllerDelegate?
    
    open var currFilterKey: String = ""
    
    // Banner View (title)
    fileprivate var bannerView: UIView! = UIView()
    fileprivate var backButton:UIButton! = UIButton()
    fileprivate var titleLabel:UILabel! = UILabel()
    
    
    // Advertisements View
    //var adView: GADBannerView! = GADBannerView()
    
    // Main Filtered Output View
    fileprivate var filterDisplayView: FilterDisplayView! = FilterDisplayView()
    
    // Adornment Overlay
    var adornmentView: UIView = UIView()
    
    
    // The filter configuration subview
    fileprivate var filterParametersView: FilterParametersView! = FilterParametersView()
    
    // Navigation help views
    fileprivate var navView: UIView! = UIView()
    fileprivate var prevView: UIView! = UIView()
    fileprivate var nextView: UIView! = UIView()
    
    
    fileprivate var filterManager: FilterManager? = FilterManager.sharedInstance
    fileprivate var currCategory: String = ""
    fileprivate var currFilterDescriptor:FilterDescriptorInterface? = nil
    fileprivate var currFilterIndex:Int = -1
    fileprivate var currFilterCount:Int = 0
    
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
        self.filterDisplayView.suspend()
    }
    
    func update(){
        DispatchQueue.main.async(execute: { () -> Void in
            self.doLayout()
            self.navView.setNeedsLayout()
        })
    }

    
    func loadFilterInfo(category: String, key: String){
        currFilterKey = key
        currCategory = category
        currFilterIndex = (filterManager?.getFilterIndex(category: category, key: key))!
        currFilterDescriptor = filterManager?.getFilterDescriptor(key: key)
        currFilterCount = (filterManager?.getFilterCount(category))!
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        log.verbose("currFilterKey:\(currFilterKey)")
        
        // get display dimensions
        displayHeight = view.height
        displayWidth = view.width
        
        
        // get orientation
        //isLandscape = UIDevice.current.orientation.isLandscape // doesn't always work properly, especially in simulator
        isLandscape = (displayWidth > displayHeight)
        
        log.verbose("h:\(displayHeight) w:\(displayWidth) landscape:\(isLandscape)")
        
        doInit()
        
        loadFilterInfo(category: (filterManager?.getSelectedCategory())!, key: (filterManager?.getSelectedFilter())!)
        
        guard  (currFilterDescriptor != nil) else {
            log.error("!!! No descriptor provided !!!")
            return
        }
        

        doLayout()
        
        
        // start Advertisements
        //startAds()
        
        
        assignTouchHandlers()
        
        // that's it, rendering is handled by the FilterDisplayView and FilterControlsView classes
        
    }
    
    
    fileprivate func doLayout(){
        // Note: need to add subviews before modifying constraints
 
        // get display dimensions
        displayHeight = view.height
        displayWidth = view.width

        setupBanner()
        //view.addSubview(adView)
        setupDisplay()
        setupAdornments()
        setupNavigationControls()
        
        setupConstraints()
        filterDisplayView.setFilter(key: currFilterKey)
        filterParametersView.setFilter(currFilterDescriptor)
        updateBanner(key: self.currFilterKey)
        
        filterParametersView.delegate = self
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
        titleLabel.text = "Filter Preview"
        titleLabel.backgroundColor = UIColor.black
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
        titleLabel.textAlignment = .center
        
        
        backButton.anchorInCorner(.bottomLeft, xPad: 4, yPad: 4, width: backButton.frame.size.width, height: backButton.frame.size.height)
        titleLabel.align(.toTheRightCentered, relativeTo: backButton, padding: 0, width: titleLabel.frame.size.width, height: titleLabel.frame.size.height)
        
        backButton.addTarget(self, action: #selector(self.backDidPress), for: .touchUpInside)
        
    }
  
    
    fileprivate func updateBanner(key: String){
        titleLabel.text = key
    }
    
    
    fileprivate func setupDisplay(){
        if (filterDisplayView != nil) { filterDisplayView.removeFromSuperview() }
        filterDisplayView = FilterDisplayView() // create new one each time, doesn't seem to update properly
    }
    
    fileprivate func setupNavigationControls(){
        // add the left and right arrows for filter navigation
        
        // a little complicated, but we define navView as the overall holding view (transparent, used for placement over the filter display)
        // next/prevImage views are the actual images, next/prevBack is a partially transparent background and next/prevView are the views that are placed onto navView
        
        let nextImage:UIImageView = UIImageView()
        let prevImage:UIImageView = UIImageView()
        let nextBack:UIView = UIView()
        let prevBack:UIView = UIView()
        
        nextImage.image = UIImage(named:"ic_next")
        prevImage.image = UIImage(named:"ic_prev")
        
        nextBack.backgroundColor = UIColor.black
        nextBack.alpha = 0.2
        
        prevBack.backgroundColor = UIColor.black
        prevBack.alpha = 0.2
        
        nextView.addSubview(nextBack)
        nextView.addSubview(nextImage)
        nextBack.fillSuperview()
        nextImage.fillSuperview()
        nextView.bringSubview(toFront: nextImage)
        
        prevView.addSubview(prevBack)
        prevView.addSubview(prevImage)
        prevBack.fillSuperview()
        prevImage.fillSuperview()
        prevView.bringSubview(toFront: prevImage)
        
        navView.backgroundColor = UIColor.clear
        prevView.backgroundColor = UIColor.clear
        nextView.backgroundColor = UIColor.clear
        
        navView.addSubview(prevView)
        navView.addSubview(nextView)
        
        prevView.frame.size.height = bannerHeight
        prevView.frame.size.width = bannerHeight
        
        nextView.frame.size.height = bannerHeight
        nextView.frame.size.width = bannerHeight
    }
    
    
    fileprivate func setupConstraints(){
        
        
        view.addSubview(bannerView)
        view.addSubview(filterDisplayView)
        view.addSubview(adornmentView)
        view.addSubview(navView)
        view.addSubview(filterParametersView)
        
        bannerView.frame.size.height = bannerHeight
        bannerView.frame.size.width = displayWidth
        bannerView.anchorAndFillEdge(.top, xPad: 0, yPad: 4, otherSize: bannerView.frame.size.height)
        //bannerView.anchorInCorner(.topLeft, xPad: 0, yPad: 4, width: bannerView.frame.size.width, height: bannerView.frame.size.height)
        log.verbose("Banner: \((titleLabel.text)!) w:\(bannerView.frame.size.width) h:\(bannerView.frame.size.height)")
        
        //adView.frame.size.height = bannerHeight
        //adView.frame.size.width = displayWidth
        //adView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: adView.frame.size.height)
        
        // set up rest of layout based on orientation
        if (UIDevice.current.orientation.isLandscape){
            // left-to-right layout scheme
            
            filterDisplayView.frame.size.height = displayHeight - bannerHeight
            filterDisplayView.frame.size.width = displayWidth / 2
            filterDisplayView.anchorInCorner(.bottomLeft, xPad: 0, yPad: 0, width: filterDisplayView.frame.size.width, height: filterDisplayView.frame.size.height)
            
            // Adornment view is same size and location as filterDisplayView
            adornmentView.frame.size = filterDisplayView.frame.size
            adornmentView.anchorInCorner(.bottomLeft, xPad: 0, yPad: 0, width: adornmentView.frame.size.width, height: adornmentView.frame.size.height)
            
            
            // Align Overlay view to bottom of Render View
            filterParametersView.frame.size.height = displayHeight - bannerHeight
            filterParametersView.frame.size.width = displayWidth / 2
            filterParametersView.anchorInCorner(.bottomRight, xPad: 0, yPad: 0, width: filterParametersView.frame.size.width, height: filterParametersView.frame.size.height)
            
            // put controls in the middle of the left/right edges
            
        } else {
            // Portrait: top-to-bottom layout scheme
            
            
            // Parameters on the bottom
            if (currFilterDescriptor != nil) {
                filterParametersView.frame.size.height = fmin((CGFloat(((currFilterDescriptor?.numParameters)! + 1)) * bannerHeight * 0.75), (displayHeight*0.75))
            } else {
                filterParametersView.frame.size.height = (displayHeight - 2.0 * bannerHeight) * 0.3
            }
            
            filterParametersView.frame.size.width = displayWidth
            filterParametersView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 1, otherSize: filterParametersView.frame.size.height)
            
            // Filter display takes the rest of the screen
            //filterDisplayView.frame.size.height = displayHeight - bannerHeight - filterParametersView.frame.size.height - 4
            filterDisplayView.frame.size.height = displayHeight - bannerHeight
            filterDisplayView.frame.size.width = displayWidth
            log.verbose("FilterDisplay: (w:\(filterDisplayView.frame.size.width), h:\(filterDisplayView.frame.size.height))")
            
            filterDisplayView.align(.underCentered, relativeTo: bannerView, padding: 0, width: filterDisplayView.frame.size.width, height: filterDisplayView.frame.size.height)
        
            
            // Adornment view is same size and location as filterDisplayView
            adornmentView.frame.size = filterDisplayView.frame.size
            adornmentView.align(.underCentered, relativeTo: bannerView, padding: 0, width: adornmentView.frame.size.width, height: adornmentView.frame.size.height)
        }
        
        layoutAdornments() // same for either rotation
        
        // prev/next navigation (same for both layouts)

        log.debug("Overlaying navigation buttons")
        
        //TODO: fix landscape layout
        
        // resize navView to match the display view (minus the parameters view)
        navView.frame.size.width  = filterDisplayView.frame.size.width
        //navView.frame.size.height  = filterDisplayView.frame.size.height
        navView.frame.size.height  = filterDisplayView.frame.size.height - filterParametersView.frame.size.height
        navView.align(.underCentered, relativeTo: bannerView, padding: 0, width: navView.frame.size.width, height: navView.frame.size.height)
        
        prevView.anchorToEdge(.left, padding: 0, width: prevView.frame.size.width, height: prevView.frame.size.height)
        nextView.anchorToEdge(.right, padding: 0, width: nextView.frame.size.width, height: nextView.frame.size.height)
        view.bringSubview(toFront: navView)
        navView.setNeedsDisplay() // for some reason it doesn't display the first time through

    }
    
    
    // setup the adornments (favourites, show/hide, ratings etc.) for the current filter
    
    // individual adornments
    fileprivate var showAdornment: UIImageView = UIImageView()
    fileprivate var favAdornment: UIImageView = UIImageView()
    fileprivate var ratingAdornment: UIImageView = UIImageView()
    
    fileprivate func setupAdornments() {
        
        guard (self.currFilterDescriptor != nil)  else {
            log.error ("NIL descriptor")
            return
        }
        
        adornmentView.frame = self.filterDisplayView.frame
        
        // set size of adornments
        //let dim: CGFloat = adornmentView.frame.size.height / 8.0
        let dim: CGFloat = buttonSize
        let adornmentSize = CGSize(width: dim, height: dim)
        // show/hide
        let showAsset: String =  (self.currFilterDescriptor?.show == true) ? "ic_accept" : "ic_reject"
        showAdornment.image = UIImage(named: showAsset)?.imageScaled(to: adornmentSize)
        
        
        // favourite
        var favAsset: String =  "ic_heart_outline"
        // TODO" figure out how to identify something in the favourite (quick select) list
        if (self.filterManager?.isFavourite(key: (self.currFilterDescriptor?.key)!))!{
            favAsset = "ic_heart_filled"
        }
        favAdornment.image = UIImage(named: favAsset)?.imageScaled(to: adornmentSize)
        
        // rating
        var ratingAsset: String =  "ic_star"
        switch ((self.currFilterDescriptor?.rating)!){
        case 1:
            ratingAsset = "ic_star_filled_1"
        case 2:
            ratingAsset = "ic_star_filled_2"
        case 3:
            ratingAsset = "ic_star_filled_3"
        default:
            break
        }
        ratingAdornment.image = UIImage(named: ratingAsset)?.imageScaled(to: adornmentSize)
        
        
        // add a little background so that you can see the icons
        showAdornment.backgroundColor = UIColor.flatGray().withAlphaComponent(0.5)
        showAdornment.layer.cornerRadius = 2.0
        
        favAdornment.backgroundColor = showAdornment.backgroundColor
        favAdornment.alpha = showAdornment.alpha
        favAdornment.layer.cornerRadius = showAdornment.layer.cornerRadius
        
        ratingAdornment.backgroundColor = showAdornment.backgroundColor
        ratingAdornment.alpha = showAdornment.alpha
        ratingAdornment.layer.cornerRadius = showAdornment.layer.cornerRadius
        
        // add icons to the adornment view
        adornmentView.addSubview(showAdornment)
        adornmentView.addSubview(favAdornment)
        adornmentView.addSubview(ratingAdornment)
        
    }
    
    
    fileprivate func layoutAdornments(){
        let dim: CGFloat = adornmentView.frame.size.height / 16.0
        let pad: CGFloat = 2.0
        showAdornment.anchorInCorner(.topLeft, xPad:pad, yPad:pad, width: dim, height: dim)
        ratingAdornment.anchorInCorner(.topRight, xPad:pad, yPad:pad, width: dim, height: dim)
        favAdornment.anchorToEdge(.top, padding:pad, width:dim, height:dim)
        view.bringSubview(toFront: adornmentView)
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
    // MARK: - Filter Management
    /////////////////////////////
    
    fileprivate func nextFilter(){
        currFilterIndex = (currFilterIndex + 1) % currFilterCount
        let key = (filterManager?.getFilterKey(category: currCategory, index: currFilterIndex))!
        loadFilterInfo(category: currCategory, key: key)
    }
    
    
    fileprivate func previousFilter(){
        currFilterIndex = (currFilterIndex - 1)
        if (currFilterIndex < 0) { currFilterIndex = currFilterCount - 1 }
        let key = (filterManager?.getFilterKey(category: currCategory, index: currFilterIndex))!
        loadFilterInfo(category: currCategory, key: key)
    }
    
    /////////////////////////////
    // MARK: - Touch Handler(s)
    /////////////////////////////
    
    func assignTouchHandlers(){
        let prevTap = UITapGestureRecognizer(target: self, action: #selector(prevDidPress))
        prevView.addGestureRecognizer(prevTap)
        prevView.isUserInteractionEnabled = true
        
        let nextTap = UITapGestureRecognizer(target: self, action: #selector(nextDidPress))
        nextView.addGestureRecognizer(nextTap)
        nextView.isUserInteractionEnabled = true
        
        setGestureDetectors(navView)
    
    }

    func backDidPress(){
        log.verbose("Back pressed")
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            //suspend()
            dismiss(animated: true, completion: { self.delegate?.onCompletion(key: self.currFilterKey) })
            return
        }
    }
    
    func prevDidPress(){
        log.verbose("Previous Filter pressed")
        suspend()
        previousFilter()
        update()
    }
    
    func nextDidPress(){
        log.verbose("Next Filter pressed")
        suspend()
        nextFilter()
        update()
    }
    
    func showParameters(){
        filterParametersView.isHidden = false
        filterParametersView.setNeedsDisplay()
    }
    
    func hideParameters(){
        filterParametersView.isHidden = true
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
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.swiped))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.swiped))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
    }
    
    
    func swiped(_ gesture: UIGestureRecognizer)
    {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer
        {
            switch swipeGesture.direction
            {
                
            case UISwipeGestureRecognizerDirection.right:
                //log.verbose("Swiped Right")
                prevDidPress()
                break
                
            case UISwipeGestureRecognizerDirection.left:
                //log.verbose("Swiped Left")
                nextDidPress()
                break
                
            case UISwipeGestureRecognizerDirection.up:
                log.verbose("Swiped Up")
                showParameters()
                break
                
            case UISwipeGestureRecognizerDirection.down:
                log.verbose("Swiped Down")
                hideParameters()
                break
                
            default:
                log.debug("Unhandled gesture direction: \(swipeGesture.direction)")
                break
            }
        }
    }
    
    
} // FilterDetailsViewController class

//////////////////////////////////////////
// MARK: - Delegate methods for sub-views
//////////////////////////////////////////



extension FilterDetailsViewController: FilterParametersViewDelegate {
    
    func settingsChanged(){
        log.debug("Filter settings changed")
        self.update()
    }
}

