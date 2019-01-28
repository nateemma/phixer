//
//  ControllerFactory.swift
//  phixer
//
//  Created by Philip Price on 1/14/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit


// the list of Controllers that can be requested
// Note that multiple identifiers can result in the same controller being launched, but usually with different parameters

enum ControllerIdentifier: String {
    
    case none // mainly used for initialising
    
    // Full Controllers:
    
    case startup
    case home
    
    case edit
    case browseStyleTransfer
    case browseFilters
    case settings
    
    case help
    case about
    
    case filterGallery
    case sampleGallery
    case blendGallery
    case styleGallery

    case displayFilter
    
    case colorPicker
    case colorScheme
    case themeChooser
    
    case reset
    
    // Menu (Sub-) Controllers:
    
    case editMainMenu
    case editBasicAdjustmentsMenu
    
    // Tool (Sub-) Controllers:
    
    case curveTool
    case hsvTool
}


// enum that identifies the type of controller
enum ControllerType: String {
    case fullscreen
    case menu
    case tool
}

// Factory class to create instances of the requested Controller

class ControllerFactory {
    
    private init(){} // prevent instantiation
    
    private static var frameMap:[ControllerType:CGRect] = [:]
    
    private static var idMap:[String:ControllerIdentifier] = [:]
    
    
    
    // sets the frame for a type of controller
    public static func setFrame(_ ctype:ControllerType, frame:CGRect) {
        frameMap[ctype] = frame
        log.debug("Type: \(ctype.rawValue) Frame:\(frame)")
    }
    
    
    // returns the frame size for a controller type
    public static func getFrame(_ ctype:ControllerType) -> CGRect {
        if frameMap[ctype] == nil {
            log.error("Frame not set up for: \(ctype.rawValue). Using full screen")
            frameMap[ctype] = UIScreen.main.bounds
        }
        return frameMap[ctype]!
    }
    
    
    // creates the requested kind of controller
    public static func getController(_ controller: ControllerIdentifier) -> CoordinatedController? {
        
        var ctype:ControllerType = .fullscreen
        var instance:CoordinatedController? = nil
        
        switch (controller){
        case .startup:
            instance = nil // TODO
            
        case .home:
            instance = MainMenuController()
            
        case .edit:
            instance = BasicEditViewController()
            
        case .browseStyleTransfer:
            instance = StyleTransferGalleryViewController()
            
        case .browseFilters:
            instance = FilterGalleryViewController()
            
        case .settings:
            instance = SettingsMenuController()
            
        case .help:
            instance = HTMLViewController()
            
        case .about:
            instance = HTMLViewController(title: "About", file: "About")
            
        case .filterGallery:
            instance = FilterGalleryViewController()
            
        case .sampleGallery:
            instance = SampleGalleryViewController()
            
        case .blendGallery:
            instance = BlendGalleryViewController()
            
        case .styleGallery:
            instance = StyleTransferGalleryViewController()
            
        case .displayFilter:
            instance = FilterDetailsViewController()
            
        case .colorPicker:
            instance = ColorPickerController()
            
        case .colorScheme:
            instance = ColorSchemeViewController()
            
        case .themeChooser:
            instance = ThemeChooserController()
            
        case .reset:
            instance = ResetViewController()
            
            // Menus
            
        case .editMainMenu:
            instance = EditMainOptionsController()
            ctype = .menu
            
        case .editBasicAdjustmentsMenu:
            instance = EditBasicAdjustmentsController()
            ctype = .menu
            
            
            // Tools:
            
        case .curveTool:
            instance = EditCurvesToolController()
            ctype = .tool

        case .hsvTool:
            instance = EditHSVToolController()
            ctype = .tool

        default:
            instance = nil
        }
        
        // set the frame within which the (Sub-) controller will run
        if instance != nil {
            if frameMap[ctype] == nil {
                log.error("Frame not set up for: \(ctype.rawValue). Using full screen")
                frameMap[ctype] = UIScreen.main.bounds
            }
            instance?.view.frame = frameMap[ctype]!
            instance?.controllerType = ctype
            instance?.id = controller
            
            let tag = "\(String(describing: type(of: instance!)))"
            idMap[tag] = controller
            
            log.debug("Type:\(ctype) Tag:\(tag) Frame: \((instance?.view.frame)!)")
        } else {
            log.error("No Controller created for ID:\(controller)")
        }
        
        return instance
        
    }
    
    // returns the id given the tag (class name). Needed because of race condition between creating controller and viewDidLoad() activation
    public static func getId(tag: String) -> ControllerIdentifier {
        var id:ControllerIdentifier = .none
        if idMap[tag] != nil { id = (idMap[tag])! }
        log.debug("\(tag) -> \(id)")
        return id

    }
}
