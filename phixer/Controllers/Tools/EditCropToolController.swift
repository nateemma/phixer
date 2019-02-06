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


// This View Controller is a Tool Subcontroller that provides the basic ability to crop & rotate an image
// This uses the ImageCropperView pod because that lets me use just a view, not a whole ViewController


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
    //var cropView: CroppableImageView! = CroppableImageView()
    var cropView: ImageCropperView! = ImageCropperView()
    
    
    var angle: CGFloat = 0.0

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
        
        cropView.delegate = self
        cropView.image = UIImage(ciImage: (EditManager.getPreviewImage())!)
        cropView.showOverlayView(animationDuration: 0.3)

        //cropView.aspectRatio = .ratio_1_1
        //cropView.angle = CGFloat(Double.pi / 4.0)
        
        // rotate gesture for rotation
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotateAction(sender:)))
        cropView.isUserInteractionEnabled = true
        cropView.addGestureRecognizer(rotateGesture)

    }
    
    
    
    private var initialAngle: CGFloat = 0.0
    
    @objc func rotateAction(sender:UIRotationGestureRecognizer){
        if sender.state == .began{
            log.verbose("Rotate Began")
            initialAngle = self.angle
        } else if sender.state == .changed{
            log.verbose(String(format:"rotation: %1.3f angle:%1.3f", sender.rotation, self.angle))
            self.angle = self.initialAngle - sender.rotation
            DispatchQueue.main.async {
                self.cropView.rotate(Double(self.angle))
            }
        } else if sender.state == .ended{
            log.verbose("Rotate Ended")
        }
    }
}
//////////////////////////////////////////
// MARK: - Delegate functions
//////////////////////////////////////////

extension EditCropToolController: ImageCropperViewDelegate {
    func imageCropperViewDidChangeCropRect(view: ImageCropperView, cropRect rect: CGRect){
        log.verbose("croprect:\(rect)")
    }
}

extension EditCropToolController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer)
        -> Bool {
            return true
    }
}

