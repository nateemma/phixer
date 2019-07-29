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

class MainMenuController: CoordinatedController, UINavigationControllerDelegate {
    
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    
    // Advertisements View
    var adView: GADBannerView! = GADBannerView()

    // menu item descriptors
    var menuItems:[MenuItem] = []
    
    // gallery of menu items
    var menuView: MenuView = MenuView()
    
    /////////////////////////////
    // MARK: - Override Base Class functions
    /////////////////////////////
    
    // return the display title for this Controller
    override public func getTitle() -> String {
        return "Main Menu"
    }
    
    // return the name of the help file associated with this Controller (without extension)
    override public func getHelpKey() -> String {
        return "About"
    }
    
    /////////////////////////////
    // INIT
    /////////////////////////////
    

    convenience init(){
        self.init(nibName:nil, bundle:nil)
        //log.debug("=== MainMenuController() ===")
        //doInit()
    }
    
    var initDone:Bool = false
    
    func doInit(){
        
        if (!initDone){
            log.verbose("init")
            initDone = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // common setup
        self.prepController()

        // get display dimensions
        displayHeight = view.height
        displayWidth = view.width
        
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        UISettings.showAds = (UISettings.isLandscape == true) ? false : true // don't show in landscape mode, too cluttered
        
        doInit()
        
        // Note: need to add subviews before modifying constraints
        view.addSubview(adView)
        view.addSubview(menuView)
        
        
        
        // set up Ads
        if (UISettings.showAds){
            adView.isHidden = false
            adView.frame.size.height = UISettings.panelHeight
            adView.frame.size.width = displayWidth
            adView.layer.borderColor = theme.borderColor.cgColor
            adView.layer.borderWidth = 1.0
            view.addSubview(adView)
            adView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: adView.frame.size.height)
            Admob.startAds(view:adView, viewController:self)
        } else {
            adView.frame.size.height = 0
            adView.isHidden = true
        }

        // set up menu
        
        menuView.frame.size.height = displayHeight - adView.frame.size.height
        menuView.frame.size.width = displayWidth

        let side = (menuView.frame.size.height * 0.667).rounded()
        let iconSize = CGSize(width: side, height: side)
        let curPhoto:UIImage = UIImage(ciImage: EditManager.getPreviewImage(size:iconSize)!)
            
        menuItems = [ MenuItem(key: "changePhoto", title: "Change Photo", subtitile: "", icon: "", view: curPhoto, isHidden: false),
                      MenuItem(key: "simpleEditor", title: "Picture Editor", subtitile: "Edit 'basic' image settings\n (exposure, colors, tone, vignette, sharpen etc.)",
                               icon: "ic_basic", view: nil, isHidden: false),
                      MenuItem(key: "favourites", title: "Favorites", subtitile: "Browse favorite prests & filters", icon: "ic_heart_outline", view: nil, isHidden: false),
                      MenuItem(key: "styleTransfer", title: "Style Transfer", subtitile: "Apply a painting style to the photo", icon: "ic_brush", view: nil, isHidden: false),
                      MenuItem(key: "browseFilters", title: "Browse Filters", subtitile: "Browse available filters/presets", icon: "ic_filter", view: nil, isHidden: false),
                      MenuItem(key: "browsePresets", title: "Browse Presets", subtitile: "Browse preset collections", icon: "ic_preset", view: nil, isHidden: false),
                      MenuItem(key: "b&w", title: "Black & White", subtitile: "Black & White (or monochrome) filters and presets", icon: "ic_contrast", view: nil, isHidden: false),
                      MenuItem(key: "analog", title: "Analog Film Types", subtitile: "Classic Analog film presets", icon: "ic_filmstrip", view: nil, isHidden: false),
                      MenuItem(key: "transforms", title: "Transforms", subtitile: "Image transforming filters (warps, sketches etc.)", icon: "ic_transform", view: nil, isHidden: false),
                      MenuItem(key: "settings", title: "Settings", subtitile: "Change app settings", icon: "ic_gear", view: nil, isHidden: false)
        ]
        
        menuView.setItems(menuItems)
        menuView.delegate = self
        
        if (UISettings.showAds){
            view.addSubview(adView)
            view.addSubview(menuView)
            adView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: adView.frame.size.height)
            menuView.align(.underCentered, relativeTo: adView, padding: 4.0, width: menuView.frame.size.width, height: menuView.frame.size.height)
            Admob.startAds(view:adView, viewController:self)
        } else {
            view.addSubview(menuView)
            menuView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: menuView.frame.size.height)
       }

    }
    

    
    /////////////////////////////////
    // Handlers for menu items
    /////////////////////////////////
    
    func handleSelection(_ key: String){
        guard !key.isEmpty else {
            log.error("NIL menu item supplied")
            return
        }
        
        switch key {
        case "changePhoto":
            presentPhotoChooser()
        case "simpleEditor":
            presentSimpleImageEditor()
        case "styleTransfer":
            presentStyleTransfer()
        case "browseFilters":
            presentFilterGallery()
        case "browsePresets":
            presentPresetGallery()
        case "favourites":
            presentFavourites()
        case "b&w":
            presentBlackAndWhite()
        case "transforms":
            presentTranforms()
        case "analog":
            presentAnalogFilm()
        case "settings":
            presentSettings()
        default:
            log.warning("Unknown menu item: \(key)")
        }
    }
    
    
    @objc func presentPhotoChooser(){
        InputSource.setCurrent(source: .edit)
        self.coordinator?.activateRequest(id: .choosePhoto)
    }
    
    @objc func presentSimpleImageEditor(){
        InputSource.setCurrent(source: .edit)
        self.coordinator?.activateRequest(id: .edit)
    }

    @objc func presentStyleTransfer(){
        InputSource.setCurrent(source: .edit)
        self.coordinator?.activateRequest(id: .browseStyleTransfer)
    }

    
    @objc func presentFilterGallery(){
        InputSource.setCurrent(source: .edit)
        //self.coordinator?.activateRequest(id: .browseFilters)
        filterManager.setCurrentCollection("filters") //TODO: make a constant
        self.coordinator?.activateRequest(id: .categoryGallery)
    }
    
    @objc func presentPresetGallery(){
        InputSource.setCurrent(source: .edit)
        filterManager.setCurrentCollection("presets") //TODO: make a constant
        self.coordinator?.activateRequest(id: .categoryGallery)
    }


    @objc func presentSettings(){
        self.coordinator?.activateRequest(id: .settings)
    }
    
    @objc func presentFavourites(){
        InputSource.setCurrent(source: .edit)
        filterManager.setCurrentCollection("favorites") //TODO: make a constant
        self.coordinator?.activateRequest(id: .categoryGallery)
    }
    

    @objc func presentBlackAndWhite(){
        InputSource.setCurrent(source: .edit)
        filterManager.setCurrentCollection("blackwhite") //TODO: make a constant
        self.coordinator?.activateRequest(id: .categoryGallery)
    }
    

    @objc func presentTranforms(){
        InputSource.setCurrent(source: .edit)
        filterManager.setCurrentCollection("transforms") //TODO: make a constant
        self.coordinator?.activateRequest(id: .categoryGallery)
    }
    @objc func presentAnalogFilm(){
        InputSource.setCurrent(source: .edit)
        filterManager.setCurrentCollection("analog") //TODO: make a constant
        self.coordinator?.activateRequest(id: .categoryGallery)
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

extension MainMenuController: MenuViewDelegate {
    func itemSelected(key:String){
        DispatchQueue.main.async { [weak self] in
            self?.handleSelection(key)
        }
    }
}
