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

class SettingsMenuController: CoordinatedController, UINavigationControllerDelegate {
    
    
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
     // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    
    // Menu items
    
    var aboutMenuItem: UIView = UIView()
    var changeBlendMenuItem: UIView = UIView()
    var changeSampleMenuItem: UIView = UIView()
    var resetMenuItem: UIView = UIView()
    var hideFiltersItem: UIView = UIView()
    var themeMenuItem: UIView = UIView()
    
    var itemList: [UIView] = []
    var itemStack: UIView = UIView()

    var hideFiltersSwitch:UISwitch = UISwitch()
    
    var numItems:CGFloat = 5
    
    //let stackView = AloeStackView()
    var stackHeight:CGFloat = 0.0
    
    
    
    
    /////////////////////////////
    // MARK: - Override Base Class functions
    /////////////////////////////
    
    // return the display title for this Controller
    override public func getTitle() -> String {
        return "Settings"
    }
    
    // return the name of the help file associated with this Controller (without extension)
    override public func getHelpKey() -> String {
        return "Settings"
    }
    
    /////////////////////////////
    // INIT
    /////////////////////////////
    

    
    static var initDone:Bool = false
    
    func doInit(){
        
        if (!SettingsMenuController.initDone){
            log.verbose("init")
            SettingsMenuController.initDone = true
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // common setup
        self.prepController()

        itemList = []
        
        // get display dimensions
        displayHeight = view.height
        displayWidth = view.width
        stackHeight = displayHeight
        
        UISettings.showAds = (UISettings.isLandscape == true) ? false : true // don't show in landscape mode, too cluttered
        
        
        //log.verbose("h:\(displayHeight) w:\(displayWidth) Landscape:\(UISettings.isLandscape) UISettings.showAds:\(UISettings.showAds)")
        
        doInit()
        
        
        stackHeight = stackHeight - UISettings.panelHeight
        
        // Set up Ads
        if (UISettings.showAds){
            adView.isHidden = false
            adView.frame.size.height = UISettings.panelHeight * 1.4
            adView.frame.size.width = displayWidth
            adView.layer.borderColor = theme.borderColor.cgColor
            adView.layer.borderWidth = 1.0
            
            view.addSubview(adView)
           adView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: adView.frame.size.height)
            Admob.startAds(view:adView, viewController:self)
            stackHeight = stackHeight - adView.frame.size.height
        } else {
            adView.frame.size.height = 0.0
        }
        
        
        //stackView.frame.size.height = stackHeight
        //stackView.frame.size.width = displayWidth
        
        // Note: need to add subviews before modifying constraints
        //let h = max((stackHeight/CGFloat(numItems)), UISettings.panelHeight).rounded()
        //let h = (stackHeight/CGFloat(numItems)).rounded() - 8
        let h = UISettings.panelHeight
        buildMenuViews(height:h)
        
        // create a stackview from the items
        if itemList.count > 0 {

            itemStack.frame.size.width = displayWidth
            itemStack.frame.size.height = displayHeight - adView.frame.size.height
            //itemStack.backgroundColor = theme.backgroundColor
            for item in itemList {
                itemStack.addSubview(item)
            }
            itemStack.groupAgainstEdge(group: .vertical, views: itemList, againstEdge: .top, padding: 4,
                                       width: itemStack.frame.size.width, height: h)
            
            view.addSubview(itemStack)
            log.verbose("Adding \(itemList.count) items. (\(itemStack.frame.size.width) x \(itemStack.frame.size.height))")

             if (UISettings.showAds){
                 itemStack.align(.underCentered, relativeTo: adView, padding: 4.0,
                                 width: itemStack.frame.size.width, height: itemStack.frame.size.height)
             } else {
                 itemStack.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: itemStack.frame.size.height)
            }
        } else {
            log.error("No Menu Items!")
        }
    }
    
    
    private func buildMenuViews(height:CGFloat) {

        // setup switches
        hideFiltersSwitch.setOn(FilterGalleryView.showHidden, animated: false)
        hideFiltersSwitch.addTarget(self, action: #selector(hideFiltersSwitchChanged(_:)), for: .valueChanged)

        //let h = max ((stackHeight / CGFloat(numItems)), UISettings.panelHeight)
        let h = UISettings.panelHeight
        let w = displayWidth - 8
        let iconSize = CGSize(width: h-4, height: h-4)
        let bkColor = theme.titleColor
        
        // Note: I switched to using system colours to allow compatibility with light/dark mode
        
        setupMenuItem(aboutMenuItem, height:h, width:w,
                      title:"About",
                      image: nil,
                      color:bkColor,
                      handler: UITapGestureRecognizer(target: self, action: #selector(presentAbout)))
        
        setupMenuItem(changeBlendMenuItem, height:h, width:w,
                      title:"Set Blend Image",
                      image: ImageManager.getCurrentBlendImage(size: iconSize),
                      color:bkColor,
                      handler: UITapGestureRecognizer(target: self, action: #selector(presentBlendGallery)))
        
//        setupMenuItem(changeSampleMenuItem, height:h, width:w,
//                      title:"Set Sample Image",
//                      image:  ImageManager.getCurrentSampleImage(size: iconSize),
//                      color:UIColor.flatTeal,
//                      handler: UITapGestureRecognizer(target: self, action: #selector(presentSampleGallery)))
        
        setupMenuItem(resetMenuItem, height:h, width:w,
                      title:"Reset Categories/Filters",
                      image: nil,
                      color:bkColor,
                      handler: UITapGestureRecognizer(target: self, action: #selector(presentReset)))

        setupSwitchItem(hideFiltersItem, height:h, width:w,
                        title:"Show Hidden Filters",
                        switchItem:hideFiltersSwitch,
                        color:bkColor)

        // only add set theme if earlier than iOS13. If later, we will just use the system colours anyway
        if #available(iOS 13.0, *) {
            // do nothing
        } else {
            setupMenuItem(themeMenuItem, height:h, width:w,
                          title:"Change Theme",
                          image: nil,
                          color:bkColor,
                          handler: UITapGestureRecognizer(target: self, action: #selector(presentThemes)))
        }
        
        numItems = CGFloat(itemList.count)


    }
    
 
    
    // utility function to setup a menu item
    func setupMenuItem(_ item:UIView, height:CGFloat, width:CGFloat, title:String, image:CIImage?, color:UIColor, handler:UITapGestureRecognizer) {
        
        let adornmentWidth:CGFloat = 48
        let pad:CGFloat = 2.0
        let side = min(adornmentWidth, height)
        //let txtColor = UIColor(contrastingBlackOrWhiteColorOn:color, isFlat:true)
        let txtColor = theme.textColor
        let txtFont = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.thin)
        
        // set up  container view
        item.frame.size.height = (height-2*pad).rounded()
        item.frame.size.width = (width-2*pad).rounded()
        item.backgroundColor = color
        item.tintColor = color
        item.layer.borderColor = self.theme.backgroundColor.cgColor
        item.layer.borderWidth = 1.0

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
        
        // add to list
        itemList.append(item)
    }

    
    // utility function to setup an item containing a switch
    // NOTE: switch handler must be set up independently
    func setupSwitchItem(_ item:UIView, height:CGFloat, width:CGFloat, title:String, switchItem:UISwitch, color:UIColor) {
        
        let adornmentWidth:CGFloat = 64
        let pad:CGFloat = 2.0
        let side = min(adornmentWidth, height)
        
        let txtColor = UIColor(contrastingBlackOrWhiteColorOn:color, isFlat:true)
        let txtFont = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.thin)
        
        // set up  container view
        item.frame.size.height = (height-2*pad).rounded()
        item.frame.size.width = (width-2*pad).rounded()
        item.backgroundColor = color
        item.tintColor = color
        item.layer.borderColor = self.theme.backgroundColor.cgColor
        item.layer.borderWidth = 1.0

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
        switchItem.thumbTintColor = color
        //switchItem.tintColor = txtColor
        //switchItem.onTintColor = ColorUtilities.complementary(color)[0]
        item.addSubview(switchItem)
        switchItem.anchorToEdge(.right, padding: 4.0, width: switchItem.frame.size.width, height: switchItem.frame.size.height)
        
        // add to list
        itemList.append(item)

    }

    /////////////////////////////////
    // Handlers for menu items
    /////////////////////////////////
    
    
    @objc func presentAbout(){
        self.coordinator?.activateRequest(id: ControllerIdentifier.about)
    }
    
    
    @objc func presentBlendGallery(){
        self.coordinator?.activateRequest(id: ControllerIdentifier.blendGallery)
    }
        
    
    @objc func presentReset(){
        self.coordinator?.activateRequest(id: ControllerIdentifier.reset)
    }
    
    @objc func presentThemes(){
        self.coordinator?.activateRequest(id: ControllerIdentifier.themeChooser)
    }
    
    @objc func presentColors(){
        self.coordinator?.activateRequest(id: ControllerIdentifier.colorScheme)
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
