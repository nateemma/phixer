//
//  EditCropToolController.swift
//  phixer
//
//  Created by Philip Price on 01/27/19
//  Copyright © 2018 Nateemma. All rights reserved.
//

import UIKit
import Neon
import CoreImage

import Photos
import AKImageCropperView


// This View Controller is a Tool Subcontroller that provides the basic ability to crop & rotate an image
// This uses the AKImageCropperView pod because that lets me use just a view, not a whole ViewController


class EditCropToolController: EditBaseToolController {
    
    
    
    
    
    ////////////////////
    // Override the default 'Virtual' funcs
    ////////////////////
    
    override func getTitle() -> String{
        return "Crop Tool"
    }
    
    // return the name of the help file associated with this Controller (without extension)
    override public func getHelpKey() -> String {
        return "SimpleEditor" // TODO: write custom help file
    }
    
    // this is called by the Controller base class to build the tool-speciifc display
    override func loadToolView(toolview: UIView){
        buildView(toolview)
    }
    
    
    override func getToolType() -> ControllerType {
        return .fulltool
    }
    
    
    override func end() {
        log.verbose("Restoring navbar")
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        dismiss()
    }
    
    ////////////////////
    // Tool-specific code
    ////////////////////
    
    
    ////////////////////////
    // the main func, called by the base class
    ////////////////////////
    
    var optionsView:UIView! = UIView()
    var cropView: CroppableImageView! = CroppableImageView()
    
    private func buildView(_ toolview: UIView){
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        toolview.backgroundColor = theme.backgroundColor
 
        toolview.addSubview(optionsView)
        toolview.addSubview(cropView)
        
        optionsView.frame.size.width = toolView.frame.size.width
        optionsView.frame.size.height = UISettings.panelHeight
        
        cropView.frame.size.width = toolView.frame.size.width
        cropView.frame.size.height = toolView.frame.size.height - optionsView.frame.size.height

        optionsView.anchorToEdge(.bottom, padding: 0, width: optionsView.frame.size.width, height: optionsView.frame.size.height)
        cropView.align(.aboveCentered, relativeTo: optionsView, padding: 0, width: cropView.frame.size.width, height: cropView.frame.size.height)
        
        cropView.image = EditManager.getPreviewImage()
        cropView.aspectRatio = .ratio_1_1
        cropView.angle = CGFloat(Double.pi / 4.0)
        

    }
    
}
//////////////////////////////////////////
// MARK: - Delegate functions
//////////////////////////////////////////

