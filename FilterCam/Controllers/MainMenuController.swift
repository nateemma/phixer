//
//  MainMenuController.swift
//  FilterCam
//
//  Created by Phil Price on 4/10/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation
import UIKit

import Neon
import GoogleMobileAds

// This is the Main View Controller for FilterCam, and basically just presents a menu of available options

class MainMenuController: UIViewController, UINavigationControllerDelegate {

    
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
    var liveFilterMenuItem: UILabel = UILabel()
    var editPictureMenuItem: UILabel = UILabel()
    var viewFiltersMenuItem: UILabel = UILabel()
    var changeBlendMenuItem: UILabel = UILabel()
    var changeSampleMenuItem: UILabel = UILabel()
    var aboutMenuItem: UILabel = UILabel()
 
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        //doInit()
    }
    
    static var initDone:Bool = false
    
    func doInit(){
        
        if (!MainMenuController.initDone){
            log.verbose("init")
            MainMenuController.initDone = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load filters etc. on a separate thread (not needed to display menu options)
        DispatchQueue.main.async(execute: { () -> Void in
            self.filterManager = FilterManager.sharedInstance
        })
        
        view.backgroundColor = UIColor.black
        
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
        view.addSubview(liveFilterMenuItem)
        view.addSubview(editPictureMenuItem)
        view.addSubview(viewFiltersMenuItem)
        view.addSubview(changeBlendMenuItem)
        view.addSubview(changeSampleMenuItem)
        view.addSubview(aboutMenuItem)
        
        
        // set default size for menu items
        if (bannerHeight < (view.frame.size.height/7)) {
            bannerHeight = view.frame.size.height/7 + 8
        }
        
        let h = (view.frame.size.height - bannerHeight) / 6 - 8
        let w = displayWidth - 4
        
        if (showAds){
            adView.isHidden = false
            adView.frame.size.height = bannerHeight
            adView.frame.size.width = displayWidth
        } else {
            adView.isHidden = true
        }

        
        // set up touch handlers (couldn't do it in setupMenuItem for some reason - scope?!)
        
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(presentLiveFilter))
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(presentImageEditor))
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(presentFilterGallery))
        let tap4 = UITapGestureRecognizer(target: self, action: #selector(presentBlendGallery))
        let tap5 = UITapGestureRecognizer(target: self, action: #selector(presentSampleGallery))
        let tap6 = UITapGestureRecognizer(target: self, action: #selector(presentAbout))

        // setup text, colours etc.
        setupMenuItem(label:liveFilterMenuItem, height:h, width:w,
                      title:"Live Filters", color:UIColor.flatWatermelonDark, handler: tap1)
        
        setupMenuItem(label:editPictureMenuItem, height:h, width:w,
                      title:"Edit Picture", color:UIColor.flatMint, handler: tap2)
        
        setupMenuItem(label:viewFiltersMenuItem, height:h, width:w,
                      title:"Manage Filters", color:UIColor.flatMintDark, handler: tap3)
        
        setupMenuItem(label:changeBlendMenuItem, height:h, width:w,
                      title:"Manage Blend Image", color:UIColor.flatTeal, handler: tap4)
        
        setupMenuItem(label:changeSampleMenuItem, height:h, width:w,
                      title:"Manage Sample Image", color:UIColor.flatBlue, handler: tap5)
        
        setupMenuItem(label:aboutMenuItem, height:h, width:w,
                      title:"About", color:UIColor.flatPurple, handler: tap6)
        

        // set layout constraints
        view.groupAgainstEdge(.vertical,
                              views: [liveFilterMenuItem, editPictureMenuItem, viewFiltersMenuItem, changeBlendMenuItem,
                                      changeSampleMenuItem, aboutMenuItem],
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
        let size = label.font.pointSize + 2.0
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
    
    
    func presentLiveFilter(){
        //launch Live Filter VC
        let vc = LiveFilterViewController()
        //vc.delegate = self
        present(vc, animated: true, completion: nil)
        //self.performSegueWithIdentifier(.categoryManager, sender: self)
    }

    func presentFilterGallery(){
        //launch Category Manager VC
        let vc = FilterGalleryViewController()
        vc.delegate = self
        present(vc, animated: true, completion: nil)
        //self.performSegueWithIdentifier(.categoryManager, sender: self)
    }
    
    func presentImageEditor(){
        /***
         let vc = ImageEditorViewController()
         vc = self
         present(vc, animated: true, completion: nil)
         ***/
        notImplemented()
    }
    
    
    
    
    func presentBlendGallery(){
        let vc = BlendGalleryViewController()
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }
    
    
    func presentSampleGallery(){
        let vc = SampleGalleryViewController()
        vc.delegate = self
        present(vc, animated: true, completion: nil)
        
    }
    
    
    func presentAbout(){
        /***
         let vc = AboutViewController()
         vc.delegate = self
         present(vc, animated: true, completion: nil)
         ***/
        notImplemented()
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



// FilterGalleryViewControllerDelegate

extension MainMenuController: FilterGalleryViewControllerDelegate {
    internal func filterGalleryCompleted(){
        log.debug("Returned from Filter Gallery")
    }
}


// BlendGalleryViewControllerDelegate

extension MainMenuController: BlendGalleryViewControllerDelegate {
    internal func blendGalleryCompleted(){
        log.debug("Returned from Blend Gallery")
    }
}


// SampleGalleryViewControllerDelegate

extension MainMenuController: SampleGalleryViewControllerDelegate {
    internal func sampleGalleryCompleted(){
        log.debug("Returned from Sample Gallery")
    }
}
