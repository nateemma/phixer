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
import AloeStackView

// Menu display for "Settings" Items

class SettingsMenuController: UIViewController, UINavigationControllerDelegate {
    
    
    var theme = ThemeManager.currentTheme()
    

    
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
    
    var aboutMenuItem: UIView = UIView()
    var changeBlendMenuItem: UIView = UIView()
    var changeSampleMenuItem: UIView = UIView()
    var manageCategoriesMenuItem: UIView = UIView()
    var resetMenuItem: UIView = UIView()
    var hideFiltersItem: UIView = UIView()
    var colorsMenuItem: UIView = UIView()
    
    var hideFiltersSwitch:UISwitch = UISwitch()
    
    let numItems:CGFloat = 7
    
    //let stackView = AloeStackView()
    var stackHeight:CGFloat = 0.0
    
    
    
    
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

    
    
    static var initDone:Bool = false
    
    func doInit(){
        
        if (!SettingsMenuController.initDone){
            log.verbose("init")
            SettingsMenuController.initDone = true
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // load theme here in case it changed
        theme = ThemeManager.currentTheme()
        
        view.backgroundColor = theme.backgroundColor
        
        // get display dimensions
        displayHeight = view.height
        displayWidth = view.width
        stackHeight = displayHeight
        
        // get orientation
        //isLandscape = UIDevice.current.orientation.isLandscape // doesn't always work properly, especially in simulator
        isLandscape = (displayWidth > displayHeight)
        
        showAds = (isLandscape == true) ? false : true // don't show in landscape mode, too cluttered
        
        
        //log.verbose("h:\(displayHeight) w:\(displayWidth) Landscape:\(isLandscape) showAds:\(showAds)")
        
        doInit()
        
        
        
        // Banner and filter info view are always at the top of the screen
        titleView.frame.size.height = bannerHeight * 0.8
        titleView.frame.size.width = displayWidth
        titleView.title = "Settings"
        titleView.delegate = self
        
        stackHeight = stackHeight - titleView.frame.size.height
        
        view.addSubview(titleView)
        titleView.anchorAndFillEdge(.top, xPad: 0, yPad: statusBarOffset/2.0, otherSize: titleView.frame.size.height)
        
        // Set up Ads
        if (showAds){
            adView.isHidden = false
            adView.frame.size.height = bannerHeight * 1.4
            adView.frame.size.width = displayWidth
            adView.layer.borderColor = theme.borderColor.cgColor
            adView.layer.borderWidth = 1.0
            
            view.addSubview(adView)
            adView.align(.underCentered, relativeTo: titleView, padding: 0, width: displayWidth, height: adView.frame.size.height)
            Admob.startAds(view:adView, viewController:self)
            stackHeight = stackHeight - adView.frame.size.height
        }
        
        
        //stackView.frame.size.height = stackHeight
        //stackView.frame.size.width = displayWidth
        
        // Note: need to add subviews before modifying constraints
        //let h = max((stackHeight/CGFloat(numItems)), bannerHeight).rounded()
        let h = (stackHeight/CGFloat(numItems)).rounded() - 8
        buildMenuViews(height:h)
        

        /***
        stackView.addRow(aboutMenuItem!)
        stackView.addRow(changeBlendMenuItem!)
        stackView.addRow(changeSampleMenuItem!)
        stackView.addRow(manageCategoriesMenuItem!)
        stackView.addRow(resetMenuItem!)
        stackView.addRow(colorsMenuItem!)
        
        view.addSubview(stackView)
        view.groupAgainstEdge(group: .vertical,
                              views: [stackView],
                              againstEdge: .bottom, padding: 4.0, width: displayWidth, height: stackHeight)
         ***/
        view.addSubview(aboutMenuItem)
        view.addSubview(changeBlendMenuItem)
        view.addSubview(changeSampleMenuItem)
        view.addSubview(manageCategoriesMenuItem)
        view.addSubview(resetMenuItem)
        view.addSubview(hideFiltersItem)
        view.addSubview(colorsMenuItem)
        view.groupAgainstEdge(group: .vertical,
                              views: [aboutMenuItem, changeBlendMenuItem, changeSampleMenuItem, manageCategoriesMenuItem, resetMenuItem, hideFiltersItem, colorsMenuItem],
                              againstEdge: .bottom, padding: 4.0, width: displayWidth, height: h)


    }
    
    
    private func buildMenuViews(height:CGFloat) {
        // set up touch handlers (couldn't do it in setupMenuItem for some reason - scope?!)
        
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(presentAbout))
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(presentBlendGallery))
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(presentSampleGallery))
        let tap4 = UITapGestureRecognizer(target: self, action: #selector(presentManageCategories))
        let tap5 = UITapGestureRecognizer(target: self, action: #selector(presentReset))
        let tap6 = UITapGestureRecognizer(target: self, action: #selector(presentColors))

        // setup switches
        hideFiltersSwitch.setOn(FilterGalleryView.showHidden, animated: false)
        hideFiltersSwitch.addTarget(self, action: #selector(hideFiltersSwitchChanged(_:)), for: .valueChanged)

        //let h = max ((stackHeight / CGFloat(numItems)), bannerHeight)
        let h = height
        let w = displayWidth - 8
        let iconSize = CGSize(width: h-4, height: h-4)
        
        setupMenuItem(aboutMenuItem, height:h, width:w, title:"About", image: nil, color:UIColor.flatMint, handler: tap1)
        
        setupMenuItem(changeBlendMenuItem, height:h, width:w, title:"Set Blend Image", image: ImageManager.getCurrentBlendImage(size: iconSize),
                      color:UIColor.flatMintDark, handler: tap2)
        
        setupMenuItem(changeSampleMenuItem, height:h, width:w, title:"Set Sample Image", image:  ImageManager.getCurrentSampleImage(size: iconSize),
                      color:UIColor.flatTeal, handler: tap3)
        
        setupMenuItem(manageCategoriesMenuItem, height:h, width:w, title:"Manage Categories", image: nil, color:UIColor.flatBlue, handler: tap4)
        
        setupMenuItem(resetMenuItem, height:h, width:w, title:"Reset Categories/Filters", image: nil, color:UIColor.flatPurpleDark, handler: tap5)

        setupSwitchItem(hideFiltersItem, height:h, width:w, title:"Show Hidden Filters", switchItem:hideFiltersSwitch, color:UIColor.flatPlum)

        setupMenuItem(colorsMenuItem, height:h, width:w, title:"Choose Colours", image: nil, color:UIColor.flatPlumDark, handler: tap6)
        

    }
    
 
    
    // utility function to setup a menu item
    func setupMenuItem(_ item:UIView, height:CGFloat, width:CGFloat, title:String, image:CIImage?, color:UIColor, handler:UITapGestureRecognizer) {
        
        let adornmentWidth:CGFloat = 48
        let side = min(adornmentWidth, height)
        let txtColor = UIColor(contrastingBlackOrWhiteColorOn:color, isFlat:true)
        let txtFont = UIFont.boldSystemFont(ofSize: 20)
        
        // set up  container view
        item.frame.size.height = height.rounded()
        item.frame.size.width = width.rounded()
        item.backgroundColor = color
        item.tintColor = color
        
        // set up the text part of the label
        let txtLabel = UILabel()
        txtLabel.frame.size.width = width - 2.0 * adornmentWidth
        txtLabel.frame.size.height = height
        txtLabel.font = txtFont
        txtLabel.backgroundColor = color
        txtLabel.textColor = txtColor
        txtLabel.textAlignment = .left
        txtLabel.text = title
        item.addSubview(txtLabel)
        txtLabel.anchorToEdge(.left, padding: 4.0, width: txtLabel.frame.size.width, height: txtLabel.frame.size.height)
        
        // set up the indicator
        let indLabel = UILabel()
        indLabel.frame.size.width = side
        indLabel.frame.size.height = side
        indLabel.font = txtFont
        indLabel.backgroundColor = color
        indLabel.textColor = txtColor
        indLabel.textAlignment = .right
        indLabel.text = ">"
        item.addSubview(indLabel)
        indLabel.anchorToEdge(.right, padding: 0.0, width: indLabel.frame.size.width, height: indLabel.frame.size.height)
        
        
        // set up the image (if specified)
        if (image != nil){
            let imgView:UIImageView = UIImageView(frame: (CGRect(x: 0, y: 0, width: side, height: side)))
            imgView.image = UIImage(ciImage: image!)
            imgView.frame.size.width = side
            imgView.frame.size.height = side
            imgView.backgroundColor = color
            item.addSubview(imgView)
            imgView.align(.toTheLeftCentered, relativeTo: indLabel, padding: 4.0, width: imgView.frame.size.width, height: imgView.frame.size.height)
        }
        
        // assign gesture handler
        item.isUserInteractionEnabled = true
        item.addGestureRecognizer(handler)
        
    }

    
    // utility function to setup an item containing a switch
    // NOTE: switch handler must be set up independently
    func setupSwitchItem(_ item:UIView, height:CGFloat, width:CGFloat, title:String, switchItem:UISwitch, color:UIColor) {
        
        let adornmentWidth:CGFloat = 64
        let side = min(adornmentWidth, height)
        let txtColor = UIColor(contrastingBlackOrWhiteColorOn:color, isFlat:true)
        let txtFont = UIFont.boldSystemFont(ofSize: 20)
        
        // set up  container view
        item.frame.size.height = height.rounded()
        item.frame.size.width = width.rounded()
        item.backgroundColor = color
        item.tintColor = color
        
        // set up the text part of the label
        let txtLabel = UILabel()
        txtLabel.frame.size.width = width - 2.0 * adornmentWidth
        txtLabel.frame.size.height = height
        txtLabel.font = txtFont
        txtLabel.backgroundColor = color
        txtLabel.textColor = txtColor
        txtLabel.textAlignment = .left
        txtLabel.text = title
        item.addSubview(txtLabel)
        txtLabel.anchorToEdge(.left, padding: 4.0, width: txtLabel.frame.size.width, height: txtLabel.frame.size.height)
        
        // set up the switch
        // have to be careful with onTint color to make sure it's visible
        switchItem.frame.size.width = side
        switchItem.frame.size.height = side
        switchItem.backgroundColor = color
        switchItem.thumbTintColor = txtColor
        switchItem.tintColor = txtColor
        switchItem.onTintColor = ColorUtilities.complementary(color)[0]
        item.addSubview(switchItem)
        switchItem.anchorToEdge(.right, padding: 4.0, width: switchItem.frame.size.width, height: switchItem.frame.size.height)
        
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
    
    @objc func hideFiltersSwitchChanged(_ sender:UISwitch){
        if (sender.isOn == true){
            log.verbose("Showing Hidden Filters")
            FilterGalleryView.showHidden = true
        }
        else{
            log.verbose("Hiding hidden filters")
            FilterGalleryView.showHidden = false
        }
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
