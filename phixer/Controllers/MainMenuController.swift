//
//  MainMenuController.swift
//  phixer
//
//  Created by Phil Price on 4/10/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation
import UIKit

import Neon
import GoogleMobileAds

// This is the Main View Controller for phixer, and basically just presents a menu of available options

class MainMenuController: UIViewController, UINavigationControllerDelegate {
    
    var theme = ThemeManager.currentTheme()
    

    
    //var filterManager: FilterManager? = FilterManager.sharedInstance
    var filterManager: FilterManager?
    
    var isLandscape : Bool = false
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    
    // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    var showAds:Bool = true
    var bannerHeight : CGFloat = 64.0
    
    let buttonSize : CGFloat = 48.0
    
    // Menu items
    var simpleEditMenuItem: UILabel = UILabel()
    var styleTransferMenuItem: UILabel = UILabel()
    var browseFiltersMenuItem: UILabel = UILabel()
    var settingsMenuItem: UILabel = UILabel()
 
    let numItems = 4
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        log.debug("=== MainMenuController() ===")
        //doInit()
    }
    
    var initDone:Bool = false
    
    func doInit(){
        
        if (!initDone){
            log.verbose("init")
            initDone = true
            
            // load filters etc. on a separate thread (not needed to display menu options)
            DispatchQueue.main.async(execute: { () -> Void in
                self.filterManager = FilterManager.sharedInstance
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Logging nicety, show that controller has changed:
        print ("\n========== \(String(describing: self)) ==========")

        // load theme here in case it changed
        theme = ThemeManager.currentTheme()
        
        view.backgroundColor = theme.backgroundColor
        
        // get display dimensions
        displayHeight = view.height
        displayWidth = view.width
        
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        // get orientation
        //isLandscape = UIDevice.current.orientation.isLandscape // doesn't always work properly, especially in simulator
        isLandscape = (displayWidth > displayHeight)
        
        showAds = (isLandscape == true) ? false : true // don't show in landscape mode, too cluttered
        
        doInit()
        
        // Note: need to add subviews before modifying constraints
        view.addSubview(adView)
        view.addSubview(simpleEditMenuItem)
        view.addSubview(styleTransferMenuItem)
        view.addSubview(browseFiltersMenuItem)
        view.addSubview(settingsMenuItem)
        
        
        // set default size for menu items
        if (bannerHeight < (view.frame.size.height/CGFloat(numItems+1))) {
            bannerHeight = view.frame.size.height/CGFloat(numItems+1) + 8
        }
        
        let h = (view.frame.size.height - bannerHeight) / CGFloat(numItems) - 8
        let w = displayWidth - 4
        
        
        
        // set up Ads
        if (showAds){
            adView.isHidden = false
            adView.frame.size.height = bannerHeight
            adView.frame.size.width = displayWidth
            adView.layer.borderColor = theme.borderColor.cgColor
            adView.layer.borderWidth = 1.0
        } else {
            adView.isHidden = true
        }

        
        // setup text, colours etc.
        setupMenuItem(label:simpleEditMenuItem, height:h, width:w,
                      title:"Simple Picture Editor", color:UIColor.flatMint, handler: UITapGestureRecognizer(target: self, action: #selector(presentSimpleImageEditor)))
        
        setupMenuItem(label:styleTransferMenuItem, height:h, width:w,
                      title:"Style Transfer", color:UIColor.flatMintDark, handler: UITapGestureRecognizer(target: self, action: #selector(presentStyleTransfer)))
        
        setupMenuItem(label:browseFiltersMenuItem, height:h, width:w,
                      title:"Browse Filters", color:UIColor.flatWatermelonDark, handler: UITapGestureRecognizer(target: self, action: #selector(presentFilterGallery)))
    
        
        setupMenuItem(label:settingsMenuItem, height:h, width:w,
                      title:"Settings", color:UIColor.flatPurple, handler: UITapGestureRecognizer(target: self, action: #selector(presentSettings)))


        // set layout constraints
        view.groupAgainstEdge(group: .vertical,
                              views: [simpleEditMenuItem, styleTransferMenuItem, browseFiltersMenuItem, settingsMenuItem],
                              againstEdge: .bottom, padding: 8, width: w-8, height: h)
        
        // start Ads
        if (showAds){
            Admob.startAds(view:adView, viewController:self)
        }
        
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
 
    // utility function to setup a menu item
    func setupMenuItem(label:UILabel, height:CGFloat, width:CGFloat, title:String, color:UIColor, handler:UITapGestureRecognizer){
        
        // set size
        label.frame.size.height = height
        label.frame.size.width = width
        
        // change font to bold (and slightly bigger size)
        let size = label.font.pointSize + 3.0
        label.font = UIFont.boldSystemFont(ofSize: size)
 
        // set text
        label.text = title

        // set Colours
        label.backgroundColor = color
        //label.textColor = UIColor.flatWhite()
        label.textColor = UIColor(contrastingBlackOrWhiteColorOn:color, isFlat:true)
        label.textAlignment = .center

        // assign gesture handler
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(handler)

    }
    
    /////////////////////////////////
    // Handlers for menu items
    /////////////////////////////////
    
    
    @objc func presentSimpleImageEditor(){
        InputSource.setCurrent(source: .edit)
        let vc = SimpleEditViewController()
        //vc.delegate = self
        present(vc, animated: true, completion: nil)
        //notImplemented()
    }
    
    @objc func presentStyleTransfer(){
        InputSource.setCurrent(source: .edit)
        let vc = StyleTransferGalleryViewController()
        vc.mode = .displaySelection
        vc.delegate = self
        present(vc, animated: true, completion: nil)
        //notImplemented()
    }

    
    @objc func presentFilterGallery(){
        InputSource.setCurrent(source: .sample)
        let vc = FilterGalleryViewController()
        vc.mode = .displaySelection
        vc.delegate = self
        present(vc, animated: true, completion: nil)

    }
    

    @objc func presentSettings(){
        //launch Category Manager VC
        let vc = SettingsMenuController()
        //vc.delegate = self
        present(vc, animated: true, completion: nil)
        //self.performSegueWithIdentifier(.categoryManager, sender: self)
    }
    
    
    /////////////////////////////////
    // Handling for functions not yet implemented
    /////////////////////////////////
    
    fileprivate var notImplementedAlert:UIAlertController? = nil
    
    fileprivate func notImplemented(){
        
        if (notImplementedAlert == nil){
            notImplementedAlert = UIAlertController(title: "Not Implemented  ☹️", message: "Sorry, this function has not (yet) been implemented", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .cancel) { (action:UIAlertAction) in
                log.debug("OK")
            }
            notImplementedAlert?.addAction(okAction)
        }
        DispatchQueue.main.async(execute: { () -> Void in
            self.present(self.notImplementedAlert!, animated: true, completion:nil)
        })
    }

} // MainMenuController


/////////////////////////////////
// Extensions
/////////////////////////////////


// FilterBasedControllerDelegate(s)

extension MainMenuController: FilterBasedControllerDelegate {
    func filterControllerSelection(key: String) {
        log.warning("Unexpected selection: \(key)")
    }
    
    func filterControllerUpdateRequest(tag: String) {
        log.debug("filterControllerUpdateRequest ignored for tag: \(tag)")
    }
    
    func filterControllerCompleted(tag: String) {
        log.debug("Returned from: \(tag)")
    }
}


// SampleFilterBasedControllerDelegate

extension MainMenuController: ColorSchemeViewControllerDelegate {
    func colorSchemeCompleted(scheme: [UIColor]) {
        log.debug("Color Scheme finished")
    }
    

}
