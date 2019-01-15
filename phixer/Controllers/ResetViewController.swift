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

    
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    
    
    // Banner/Navigation View (title)
    fileprivate var bannerView: TitleView! = TitleView()
    fileprivate let statusBarOffset : CGFloat = 2.0

    // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    var bannerHeight : CGFloat = 64.0
    
    let buttonSize : CGFloat = 48.0
    
 
    
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
        
        
        // Logging nicety, show that controller has changed:
        print ("\n========== \(String(describing: type(of: self))) ==========")

        // load theme here in case it changed
        theme = ThemeManager.currentTheme()
        

        view.backgroundColor = theme.backgroundColor
        
        // get display dimensions
        displayHeight = view.height
        displayWidth = view.width
        
        
        showAds = (isLandscape == true) ? false : true // don't show in landscape mode, too cluttered
        
        
        log.verbose("h:\(displayHeight) w:\(displayWidth) Landscape:\(isLandscape) showAds:\(showAds)")

        doInit()
        
        // Note: need to add subviews before modifying constraints
        view.addSubview(bannerView)
        view.addSubview(adView)

        
        // Banner and filter info view are always at the top of the screen
        bannerView.frame.size.height = bannerHeight * 0.5
        bannerView.frame.size.width = displayWidth
        bannerView.backgroundColor = theme.backgroundColor
        
        
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
        bannerView.frame.size.height = bannerHeight * 0.5
        bannerView.frame.size.width = displayWidth
        bannerView.title = "Reset Filters"
        bannerView.delegate = self
    }

    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if ((UIApplication.shared.statusBarOrientation == .landscapeLeft) || (UIApplication.shared.statusBarOrientation == .landscapeRight)){
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
    @objc func backDidPress(){
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



extension ResetViewController: TitleViewDelegate {
    func backPressed() {
        backDidPress()
    }
    
    func helpPressed() {
//        let vc = HTMLViewController()
//        vc.setTitle("Reset")
//        vc.loadFile(name: "Reset")
//        present(vc, animated: true, completion: nil)
        self.coordinator?.help()
    }
    
    func menuPressed() {
        // placeholder
    }
}


