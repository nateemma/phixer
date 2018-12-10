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

import GoogleMobileAds
//import Kingfisher




// delegate method to let the launching ViewController know that this one has finished
protocol StyleTransferGalleryViewControllerDelegate: class {
    func styleGalleryCompleted()
}


private var filterList: [String] = []
private var filterCount: Int = 0

// This is the View Controller for displaying Style Transfer models

class StyleTransferGalleryViewController: UIViewController {
    
    var theme = ThemeManager.currentTheme()
    
    
    // Banner View (title)
    var bannerView: TitleView! = TitleView()
    
    
    // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    
    var styleGalleryView : StyleTransferGalleryView! = StyleTransferGalleryView()
    
    var filterManager:FilterManager = FilterManager.sharedInstance
    
    
    var isLandscape : Bool = false
    var showAds : Bool = true
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    let bannerHeight : CGFloat = 64.0
    let buttonSize : CGFloat = 48.0
    let statusBarOffset : CGFloat = 2.0
    
    
    
    
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
            styleGalleryView.frame.size.height = displayHeight - bannerView.frame.size.height - adView.frame.size.height
        } else {
            styleGalleryView.frame.size.height = displayHeight - bannerView.frame.size.height
        }
        styleGalleryView.frame.size.width = displayWidth
        styleGalleryView.backgroundColor = theme.backgroundColor
        styleGalleryView.isHidden = false
        styleGalleryView.delegate = self
        view.addSubview(styleGalleryView) // do this before categorySelectionView is assigned
        
        
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


        // layout constraints
        bannerView.anchorAndFillEdge(.top, xPad: 0, yPad: statusBarOffset/2.0, otherSize: bannerView.frame.size.height)

        if (showAds){
            adView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: adView.frame.size.height)
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
    
    
    
    
    /////////////////////////////
    // MARK: - Touch Handler(s)
    /////////////////////////////
    
    @objc func backDidPress(){
        log.verbose("Back pressed")
        //_ = self.navigationController?.popViewController(animated: true)
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            suspend()
            dismiss(animated: true, completion:  {  })
            return
        }
    }
    

} // StyleTransferGalleryViewController


//////////////////////////////////////////
// MARK: - Delegate methods for sub-views
//////////////////////////////////////////



extension StyleTransferGalleryViewController: StyleTransferGalleryViewDelegate {

    
    func filterSelected(_ descriptor:FilterDescriptor?){
        filterManager.setSelectedFilter(key: (descriptor?.key)!)
        let filterDetailsViewController = FilterDetailsViewController()
        filterDetailsViewController.delegate = self
        filterDetailsViewController.currFilterKey = (descriptor?.key)!
        self.present(filterDetailsViewController, animated: false, completion: nil)
    }
    
}



extension StyleTransferGalleryViewController: FilterDetailsViewControllerDelegate {
    func onCompletion(key:String){
        log.verbose("FilterDetailsView completed")
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

