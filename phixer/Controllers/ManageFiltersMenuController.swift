//
//  ManageFiltersMenuController.swift
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

class ManageFiltersMenuController: UIViewController, UINavigationControllerDelegate {


    
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
    
    // Menu items

    var viewFiltersMenuItem: UILabel = UILabel()
    var changeBlendMenuItem: UILabel = UILabel()
    var changeSampleMenuItem: UILabel = UILabel()
    var manageCategoriesMenuItem: UILabel = UILabel()
    var resetMenuItem: UILabel = UILabel()
    
    let numItems:CGFloat = 5
 
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        //doInit()
    }
    
    static var initDone:Bool = false
    
    func doInit(){
        
        if (!ManageFiltersMenuController.initDone){
            log.verbose("init")
            ManageFiltersMenuController.initDone = true
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
        view.addSubview(viewFiltersMenuItem)
        view.addSubview(changeBlendMenuItem)
        view.addSubview(changeSampleMenuItem)
        view.addSubview(manageCategoriesMenuItem)
        view.addSubview(resetMenuItem)
        
        
        // if room, increase size of ads
        if (bannerHeight < (view.frame.size.height/CGFloat(numItems+1.5))) {
            bannerHeight = view.frame.size.height/CGFloat(numItems+1.5) + 8
        }
        
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

        
        // set up touch handlers (couldn't do it in setupMenuItem for some reason - scope?!)
        
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(presentFilterGallery))
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(presentBlendGallery))
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(presentSampleGallery))
        let tap4 = UITapGestureRecognizer(target: self, action: #selector(presentManageCategories))
        let tap5 = UITapGestureRecognizer(target: self, action: #selector(presentReset))

        // setup sizes, text, colours etc.
        
        var h: CGFloat
        let pad:CGFloat = 8.0
            
        if (showAds){
            h = (view.frame.size.height - bannerView.frame.size.height - adView.frame.size.height) / CGFloat(numItems) - pad
        } else {
            h = (view.frame.size.height - bannerView.frame.size.height) / CGFloat(numItems) - pad
        }
        let w = displayWidth - 4
        
       
        setupMenuItem(label:viewFiltersMenuItem, height:h, width:w,
                      title:"View/Rate Filters", color:UIColor.flatMint, handler: tap1)
        
        setupMenuItem(label:changeBlendMenuItem, height:h, width:w,
                      title:"Manage Blend Image", color:UIColor.flatMintDark, handler: tap2)
        
        setupMenuItem(label:changeSampleMenuItem, height:h, width:w,
                      title:"Manage Sample Image", color:UIColor.flatTeal, handler: tap3)
        
        setupMenuItem(label:manageCategoriesMenuItem, height:h, width:w,
                      title:"Manage Categories", color:UIColor.flatBlue, handler: tap4)
        
        setupMenuItem(label:resetMenuItem, height:h, width:w,
                      title:"Reset Categories/Filters", color:UIColor.flatPurple, handler: tap5)
        

        // set layout constraints
        view.groupAgainstEdge(group: .vertical,
                              views: [viewFiltersMenuItem, changeBlendMenuItem, changeSampleMenuItem, manageCategoriesMenuItem, resetMenuItem],
                              againstEdge: .bottom, padding: pad, width: w-pad, height: h)
        
        // start Ads
        if (showAds){
            Admob.startAds(view:adView, viewController:self)
        }
        
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
        titleLabel.text = "Manage Categories/Filters"
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
    

    @objc func presentFilterGallery(){
        //launch Category Manager VC
        let vc = FilterGalleryViewController()
        vc.delegate = self
        present(vc, animated: true, completion: nil)
        //self.performSegueWithIdentifier(.categoryManager, sender: self)
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

} // ManageFiltersMenuController



// FilterGalleryViewControllerDelegate

extension ManageFiltersMenuController: FilterGalleryViewControllerDelegate {
    internal func filterGalleryCompleted(){
        log.debug("Returned from Filter Gallery")
    }
}


// BlendGalleryViewControllerDelegate

extension ManageFiltersMenuController: BlendGalleryViewControllerDelegate {
    internal func blendGalleryCompleted(){
        log.debug("Returned from Blend Gallery")
    }
}


// SampleGalleryViewControllerDelegate

extension ManageFiltersMenuController: SampleGalleryViewControllerDelegate {
    internal func sampleGalleryCompleted(){
        log.debug("Returned from Sample Gallery")
    }
}
