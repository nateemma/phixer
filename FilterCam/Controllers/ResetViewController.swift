//
//  ResetViewController.swift
//  FilterCam
//
//  Created by Phil Price on 4/10/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation
import UIKit

import Neon
import GoogleMobileAds

// View Controller to reset the database

class ResetViewController: UIViewController, UINavigationControllerDelegate {


    
    var isLandscape : Bool = false
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    
    
    // Banner/Navigation View (title)
    fileprivate var bannerView: UIView! = UIView()
    fileprivate var backButton:UIButton! = UIButton()
    fileprivate var titleLabel:UILabel! = UILabel()
    fileprivate let statusBarOffset : CGFloat = 12.0

    // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    var showAds:Bool = true
    var bannerHeight : CGFloat = 64.0
    
    let buttonSize : CGFloat = 48.0
    
    fileprivate var filterManager: FilterManager? = FilterManager.sharedInstance

 
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        //doInit()
    }
    
    static var initDone:Bool = false
    
    func doInit(){
        
        if (!ResetViewController.initDone){
            log.verbose("init")
            ResetViewController.initDone = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        view.backgroundColor = UIColor.black
        
        // get display dimensions
        displayHeight = view.height
        displayWidth = view.width
        
        
        // get orientation
        //isLandscape = UIDevice.current.orientation.isLandscape // doesn't always work properly, especially in simulator
        isLandscape = (displayWidth > displayHeight)

        showAds = (isLandscape == true) ? false : true // don't show in landscape mode, too cluttered
        
        
        log.verbose("h:\(displayHeight) w:\(displayWidth) Landscape:\(isLandscape) showAds:\(showAds)")

        doInit()
        
        // Note: need to add subviews before modifying constraints
        view.addSubview(bannerView)
        view.addSubview(adView)

        
        // Banner and filter info view are always at the top of the screen
        bannerView.frame.size.height = bannerHeight * 0.5
        bannerView.frame.size.width = displayWidth
        bannerView.backgroundColor = UIColor.black
        
        
        layoutBanner()
        bannerView.anchorAndFillEdge(.top, xPad: 0, yPad: statusBarOffset/2.0, otherSize: bannerView.frame.size.height)

        // Set up Ads
        if (showAds){
            adView.isHidden = false
            adView.frame.size.height = bannerHeight
            adView.frame.size.width = displayWidth
            
            adView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: adView.frame.size.height)
        }

        
        // start Ads
        if (showAds){
            Admob.startAds(view:adView, viewController:self)
        }
        
        // display the reset dialog
        displayResetDialog()
        
    }
    
    
    // layout the banner view, with the Back button, title etc.
    func layoutBanner(){
        bannerView.addSubview(backButton)
        bannerView.addSubview(titleLabel)
        
        backButton.frame.size.height = bannerView.frame.size.height * 0.5
        backButton.frame.size.width = 2.5 * backButton.frame.size.height
        backButton.setTitle("< Back", for: .normal)
        backButton.backgroundColor = UIColor.flatMint
        backButton.setTitleColor(UIColor.white, for: .normal)
        backButton.titleLabel!.font = UIFont.boldSystemFont(ofSize: 20.0)
        backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
        
        titleLabel.frame.size.height = backButton.frame.size.height
        titleLabel.frame.size.width = displayWidth - backButton.frame.size.width
        titleLabel.text = "Reset to Default Settings"
        titleLabel.backgroundColor = UIColor.black
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
        titleLabel.textAlignment = .center
        
        
        backButton.anchorInCorner(.bottomLeft, xPad: 4, yPad: 4, width: backButton.frame.size.width, height: backButton.frame.size.height)
        titleLabel.align(.toTheRightCentered, relativeTo: backButton, padding: 0, width: titleLabel.frame.size.width, height: titleLabel.frame.size.height)
        
        backButton.addTarget(self, action: #selector(self.backDidPress), for: .touchUpInside)
        
    }
    

    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if UIDevice.current.orientation.isLandscape{
            log.verbose("### Detected change to: Landscape")
        } else {
            log.verbose("### Detected change to: Portrait")
            
        }
        //TODO: animate and maybe handle before rotation finishes
        self.viewDidLoad()
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        log.error("Memory Warning")
        // Dispose of any resources that can be recreated.
    }

    
    
    
    //////////////////////////////////////
    //MARK: - Navigation
    //////////////////////////////////////
    func backDidPress(){
        log.verbose("Back pressed")
        exitScreen()
    }
    
    
    func exitScreen(){
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            //suspend()
            dismiss(animated: true, completion:  { })
            return
        }
    }

    
    /////////////////////////////////
    // Handling for functions not yet implemented
    /////////////////////////////////
    
    fileprivate var resetAlert:UIAlertController? = nil
    
    fileprivate func displayResetDialog(){

        if (resetAlert == nil){
            resetAlert = UIAlertController(title: "Confirm",
                                           message:"Are you sure you want to reset the Filters and Categories? This cannot be undone",
                                           preferredStyle: .alert)
            
            // add the OK button
            let okAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                log.debug("OK - resetting categories/filters")
                self.filterManager?.restoreDefaults()
            }
            resetAlert?.addAction(okAction)
            
            // add the Cancel Button
            let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action:UIAlertAction) in
                log.debug("Cancel")
            }
            resetAlert?.addAction(cancelAction)

        }
        
        // display the dialog
        DispatchQueue.main.async(execute: { () -> Void in
            self.present(self.resetAlert!, animated: true, completion:nil)
        })
        

    }

} // ResetViewController

