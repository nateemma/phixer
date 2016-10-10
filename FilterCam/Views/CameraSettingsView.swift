//
//  CameraSettingsView.swift
//  Philter
//
//  Created by Philip Price on 9/16/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import UIKit
import Neon
import ChameleonFramework



// Interface required of controlling View
protocol CameraSettingsViewDelegate: class {
    func flashPressed()
    func gridPressed()
    func aspectPressed()
    func cameraPressed()
    func timerPressed()
    func switchPressed()
}



// Class responsible for laying out the Camera Settings View
class CameraSettingsView: UIView {
    
    var isLandscape : Bool = false
    var initDone: Bool = false
    
    let bannerHeight : CGFloat = 48.0
    let buttonSize : CGFloat = 40.0
    
    // Buttons within the view
    var flashButton: SquareButton! = SquareButton()
    var gridButton: SquareButton! = SquareButton()
    var aspectButton: SquareButton! = SquareButton()
    var cameraButton: SquareButton! = SquareButton()
    var timerButton: SquareButton! = SquareButton()
    var switchButton: SquareButton! = SquareButton()
    var spacer: SquareButton! = SquareButton()
    
    
    // delegate for handling events
    weak var delegate: CameraSettingsViewDelegate?

    
    convenience init(){
        self.init(frame: CGRect.zero)
        initViews()
    }
    
    
    // Initialise the views
    func initViews(){
        if (!initDone){
            
            layoutFrames()
            //TODO: define handlers for touches
            
            initDone = true
        }
    }
    
   
    func layoutFrames(){
        // setup colors etc.
        self.backgroundColor = UIColor.flatBlack()
        
        //self.backgroundColor = GradientColor(UIGradientStyle.topToBottom, frame: self.frame, colors: [UIColor.gray, UIColor.lightGray])
        
        // Set up buttons/icons
        flashButton = SquareButton(bsize: buttonSize)
        gridButton = SquareButton(bsize: buttonSize)
        aspectButton = SquareButton(bsize: buttonSize)
        cameraButton = SquareButton(bsize: buttonSize)
        timerButton = SquareButton(bsize: buttonSize)
        switchButton = SquareButton(bsize: buttonSize)
        
        assignIcons()
    }
    
    //MARK: - Utility functions:

    // Assign icons to the various buttons based upon current settings
    func assignIcons(){
        // temp: fixed icons for now
        // TODO: set icons based on current settings
        
        flashButton.setImageAsset("ic_flash_auto.png")
        gridButton.setImageAsset("ic_grid_none.png")
        aspectButton.setImageAsset("ic_aspect_4_3.png")
        cameraButton.setImageAsset("ic_camera.png")
        timerButton.setImageAsset("ic_timer.png")
        switchButton.setImageAsset("ic_front_back.png")
        
    }

    
 
    // Called when this view needs to be updated
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        //var pad: CGFloat = 0.0
        var vpad: CGFloat = 0.0
        var hpad: CGFloat = 0.0
        var pad: CGFloat = 0.0
        
        
        if !initDone {
            initViews()
        } else {
            
            // Set icons for various camera settings based on the current value
            assignIcons()
        }
        
        // get orientation
        isLandscape = UIDevice.current.orientation.isLandscape
        
        
        
        self.addSubview(flashButton)
        self.addSubview(gridButton)
        self.addSubview(aspectButton)
        self.addSubview(cameraButton)
        self.addSubview(timerButton)
        self.addSubview(switchButton)

        // set up layout based on orientation
        if (isLandscape){
            // Landscape: icons/buttons are arranged vertically
            
            // figure out horizontal padding to center images
            hpad = (self.frame.size.width - buttonSize)/2.0
            
            // figure out vertical padding (6 button means 7 spaces)
            vpad = ((self.frame.size.height - 6.0*(buttonSize+2.0*hpad)) / 7.0)
            
            pad = fmin(fabs(hpad), fabs(vpad))
            
            spacer = SquareButton(bsize: vpad)
            
            print("*** Laying out CameraSettings (Landscape). vpad:\(vpad) hpad:\(hpad) pad:\(pad)")
            print("*** h:\(self.frame.size.height) w:\(self.frame.size.width)")
            self.groupAndFill(.vertical, views: [flashButton, gridButton, aspectButton, cameraButton, timerButton, switchButton], padding: pad)
            //self.groupAndFill(.vertical, views: [spacer, flashButton, spacer, gridButton, spacer, aspectButton, spacer, cameraButton, spacer, timerButton, spacer, switchButton, spacer], padding: hpad)
            
            
        } else {
            // Portrait: icons/buttons are arranged horizontally
            
            
            // figure out vertical padding to center images
            vpad = (self.frame.size.height - buttonSize)/2.0 + 8 // +8 moves it away from the system banner a little (empirical)
            
            // figure out horizontal padding (6 button means 7 spaces)
            //hpad = ((self.frame.size.width - 6.0*(buttonSize+2.0*vpad)) / 7.0)
            hpad = ((self.frame.size.width - 6.0*(buttonSize)) / 7.0)
            
            spacer = SquareButton(bsize: hpad)
            
            //pad = (self.frame.size.width - 6.0*buttonSize) / 7.0
            pad = fmin(fabs(hpad), fabs(vpad))
            
            print("Laying out CameraSettings (Portrait). vpad:\(vpad) hpad:\(hpad)")
            
            self.groupAndFill(.horizontal, views: [flashButton, gridButton, aspectButton, cameraButton, timerButton, switchButton], padding: pad)
            //self.groupAndFill(.horizontal, views: [spacer, flashButton, spacer, gridButton, spacer, aspectButton, spacer, cameraButton, spacer, timerButton, spacer, switchButton, spacer], padding: vpad)
            

        }
 
        //log.verbose("Touch handlers...")
        flashButton.addTarget(self, action: #selector(self.flashDidPress), for: .touchUpInside)
        gridButton.addTarget(self, action: #selector(self.gridDidPress), for: .touchUpInside)
        aspectButton.addTarget(self, action: #selector(self.aspectDidPress), for: .touchUpInside)
        cameraButton.addTarget(self, action: #selector(self.cameraDidPress), for: .touchUpInside)
        timerButton.addTarget(self, action: #selector(self.timerDidPress), for: .touchUpInside)
        switchButton.addTarget(self, action: #selector(self.switchDidPress), for: .touchDown)

    }
    
    
    //MARK: - touch handlers
    
    
    func flashDidPress() {
        log.debug("Flash pressed")
        delegate?.flashPressed()
    }
    
    
    func gridDidPress() {
        log.debug("Grid pressed")
        delegate?.gridPressed()
    }
    
    
    func aspectDidPress() {
        log.debug("Aspect pressed")
        delegate?.aspectPressed()
    }
    
    
    func cameraDidPress() {
        log.debug("Camera pressed")
        delegate?.cameraPressed()
    }
    
    
    func timerDidPress() {
        log.debug("Timer pressed")
        delegate?.timerPressed()
    }
    
    
    func switchDidPress() {
        log.debug("switch camera pressed")
        delegate?.switchPressed()
    }

}
