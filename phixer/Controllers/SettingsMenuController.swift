//
//  SettingsMenuController.swift
//  phixer
//
//  Created by Phil Price on 4/10/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation
import UIKit

import Neon
import GoogleMobileAds

// Menu display for "Settings" Items

class SettingsMenuController: UIViewController, UINavigationControllerDelegate {


    
    var isLandscape : Bool = false
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    
    
    // Banner/Navigation View (title)
    fileprivate var titleView:TitleView! = TitleView()
    fileprivate let statusBarOffset : CGFloat = 12.0

    // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    var showAds:Bool = true
    var bannerHeight : CGFloat = 64.0
    
    let buttonSize : CGFloat = 48.0
    
    // Menu items

    var aboutMenuItem: UILabel = UILabel()
    var changeBlendMenuItem: UILabel = UILabel()
    var changeSampleMenuItem: UILabel = UILabel()
    var manageCategoriesMenuItem: UILabel = UILabel()
    var resetMenuItem: UILabel = UILabel()
    var colorsMenuItem: UILabel = UILabel()
    
    let numItems:CGFloat = 6
 
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        //doInit()
    }
    
    static var initDone:Bool = false
    
    func doInit(){
        
        if (!SettingsMenuController.initDone){
            log.verbose("init")
            SettingsMenuController.initDone = true
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
        
        
        //log.verbose("h:\(displayHeight) w:\(displayWidth) Landscape:\(isLandscape) showAds:\(showAds)")

        doInit()
        
        // Note: need to add subviews before modifying constraints
        view.addSubview(titleView)
        view.addSubview(adView)
        view.addSubview(aboutMenuItem)
        view.addSubview(changeBlendMenuItem)
        view.addSubview(changeSampleMenuItem)
        view.addSubview(manageCategoriesMenuItem)
        view.addSubview(resetMenuItem)
        view.addSubview(colorsMenuItem)

        
        // if room, increase size of ads
        if (bannerHeight < (view.frame.size.height/CGFloat(numItems+1.5))) {
            bannerHeight = view.frame.size.height/CGFloat(numItems+1.5) + 8
        }
        
        // Banner and filter info view are always at the top of the screen
        titleView.frame.size.height = bannerHeight * 0.5
        titleView.frame.size.width = displayWidth
        titleView.title = "Settings"
        titleView.delegate = self
        
        
        titleView.anchorAndFillEdge(.top, xPad: 0, yPad: statusBarOffset/2.0, otherSize: titleView.frame.size.height)

        // Set up Ads
        if (showAds){
            adView.isHidden = false
            adView.frame.size.height = bannerHeight
            adView.frame.size.width = displayWidth
            adView.layer.borderColor = UIColor.flatBlack.cgColor
            adView.layer.borderWidth = 1.0

            adView.align(.underCentered, relativeTo: titleView, padding: 0, width: displayWidth, height: adView.frame.size.height)
        }

        
        // set up touch handlers (couldn't do it in setupMenuItem for some reason - scope?!)
        
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(presentAbout))
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(presentBlendGallery))
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(presentSampleGallery))
        let tap4 = UITapGestureRecognizer(target: self, action: #selector(presentManageCategories))
        let tap5 = UITapGestureRecognizer(target: self, action: #selector(presentReset))
        let tap6 = UITapGestureRecognizer(target: self, action: #selector(presentColors))

        // setup sizes, text, colours etc.
        
        var h: CGFloat
        let pad:CGFloat = 8.0
            
        if (showAds){
            h = (view.frame.size.height - titleView.frame.size.height - adView.frame.size.height) / CGFloat(numItems) - pad
        } else {
            h = (view.frame.size.height - titleView.frame.size.height) / CGFloat(numItems) - pad
        }
        let w = displayWidth - 4
        
       
        setupMenuItem(label:aboutMenuItem, height:h, width:w,
                      title:"About", color:UIColor.flatMint, handler: tap1)
        
        setupMenuItem(label:changeBlendMenuItem, height:h, width:w,
                      title:"Set Blend Image", color:UIColor.flatMintDark, handler: tap2)
        
        setupMenuItem(label:changeSampleMenuItem, height:h, width:w,
                      title:"Set Sample Image", color:UIColor.flatTeal, handler: tap3)
        
        setupMenuItem(label:manageCategoriesMenuItem, height:h, width:w,
                      title:"Manage Categories", color:UIColor.flatBlue, handler: tap4)
        
        setupMenuItem(label:resetMenuItem, height:h, width:w,
                      title:"Reset Categories/Filters", color:UIColor.flatPurple, handler: tap5)
        
        setupMenuItem(label:colorsMenuItem, height:h, width:w,
                      title:"Choose Colours", color:UIColor.flatPurpleDark, handler: tap6)


        // set layout constraints
        view.groupAgainstEdge(group: .vertical,
                              views: [aboutMenuItem, changeBlendMenuItem, changeSampleMenuItem, manageCategoriesMenuItem, resetMenuItem, colorsMenuItem],
                              againstEdge: .bottom, padding: pad, width: w-pad, height: h)
        
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
    

    @objc func presentAbout(){
        //notImplemented()
        let vc = HTMLViewController()
        vc.setTitle("About")
        //vc.setText("<h1>About phixer</h1><p>blah, blah, blah...</p>")
        vc.loadFile(name: "About")
        present(vc, animated: true, completion: nil)
    }
    
    
    @objc func presentBlendGallery(){
        let vc = BlendGalleryViewController()
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }
    
    
    @objc func presentSampleGallery(){
        let vc = SampleGalleryViewController()
        vc.delegate = self
        present(vc, animated: true, completion: nil)
        
    }
    
 
    @objc func presentManageCategories(){
        /***
         let vc = ManagerCategoriesViewController()
         vc.delegate = self
         present(vc, animated: true, completion: nil)
         ***/
        notImplemented()
    }
    
    
    @objc func presentReset(){
        let vc = ResetViewController()
        //vc.delegate = self
        present(vc, animated: true, completion: nil)
        notImplemented()
    }
    
    @objc func presentColors(){
        let vc = ColorSchemeViewController()
        //vc.delegate = self
        present(vc, animated: true, completion: nil)
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

} // SettingsMenuController



// FilterGalleryViewControllerDelegate

extension SettingsMenuController: FilterGalleryViewControllerDelegate {
    internal func filterGalleryCompleted(){
        log.debug("Returned from Filter Gallery")
    }
}


// BlendGalleryViewControllerDelegate

extension SettingsMenuController: BlendGalleryViewControllerDelegate {
    internal func blendGalleryCompleted(){
        log.debug("Returned from Blend Gallery")
    }
}


// SampleGalleryViewControllerDelegate

extension SettingsMenuController: SampleGalleryViewControllerDelegate {
    internal func sampleGalleryCompleted(){
        log.debug("Returned from Sample Gallery")
    }
}

extension SettingsMenuController: TitleViewDelegate {
    func backPressed() {
        backDidPress()
    }
}
