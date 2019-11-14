//
//  ResetViewController.swift
//  phixer
//
//  Created by Phil Price on 4/10/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation
import UIKit

import Neon
import GoogleMobileAds

// View Controller to reset the database

class ResetViewController: CoordinatedController, UINavigationControllerDelegate {

    
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    

    // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    
 
    
    
    /////////////////////////////
    // MARK: - Override Base Class functions
    /////////////////////////////
    
    // return the display title for this Controller
    override public func getTitle() -> String {
        return "Reset"
    }
    
    // return the name of the help file associated with this Controller (without extension)
    override public func getHelpKey() -> String {
        return "Reset"
    }
    
    /////////////////////////////
    // INIT
    /////////////////////////////
    

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
        
        // common setup
        self.prepController()

        view.backgroundColor = theme.backgroundColor
        
        // get display dimensions
        displayHeight = view.height
        displayWidth = view.width
        
        
        UISettings.showAds = (UISettings.isLandscape == true) ? false : true // don't show in landscape mode, too cluttered
        
        
        log.verbose("h:\(displayHeight) w:\(displayWidth) Landscape:\(UISettings.isLandscape) UISettings.showAds:\(UISettings.showAds)")

        doInit()
        
        // Note: need to add subviews before modifying constraints
        view.addSubview(adView)
        

        // Set up Ads
        if (UISettings.showAds){
            adView.isHidden = false
            adView.frame.size.height = UISettings.panelHeight
            adView.frame.size.width = displayWidth
            
            adView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: adView.frame.size.height)
        }

        
        // start Ads
        if (UISettings.showAds){
            Admob.startAds(view:adView, viewController:self)
        }
        
        // display the reset dialog
        displayResetDialog()
        
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
                self.filterManager.restoreDefaults()
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



