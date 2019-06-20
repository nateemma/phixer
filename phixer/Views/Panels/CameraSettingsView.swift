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
    
    var theme = ThemeManager.currentTheme()
    

    var initDone: Bool = false
    
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
        self.backgroundColor = theme.backgroundColor
        
        //self.backgroundColor = GradientColor(UIGradientStyle.topToBottom, frame: self.frame, colors: [UIColor.gray, UIColor.lightGray])
        
        // Set up buttons/icons
        flashButton = SquareButton(bsize: UISettings.buttonSide)
        gridButton = SquareButton(bsize: UISettings.buttonSide)
        aspectButton = SquareButton(bsize: UISettings.buttonSide)
        cameraButton = SquareButton(bsize: UISettings.buttonSide)
        timerButton = SquareButton(bsize: UISettings.buttonSide)
        switchButton = SquareButton(bsize: UISettings.buttonSide)
        
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
        
        
        
        self.addSubview(flashButton)
        self.addSubview(gridButton)
        self.addSubview(aspectButton)
        self.addSubview(cameraButton)
        self.addSubview(timerButton)
        self.addSubview(switchButton)

        // set up layout based on orientation
        if (UISettings.isLandscape){
            // Landscape: icons/buttons are arranged vertically
            
            // figure out horizontal padding to center images
            hpad = (self.frame.size.width - UISettings.buttonSide)/2.0
            
            // figure out vertical padding (6 button means 7 spaces)
            vpad = ((self.frame.size.height - 6.0*(UISettings.buttonSide+2.0*hpad)) / 7.0)
            
            pad = fmin(abs(hpad), abs(vpad))
            
            spacer = SquareButton(bsize: vpad)
            
            print("*** Laying out CameraSettings (Landscape). vpad:\(vpad) hpad:\(hpad) pad:\(pad)")
            print("*** h:\(self.frame.size.height) w:\(self.frame.size.width)")
            self.groupAndFill(group: .vertical, views: [flashButton, gridButton, aspectButton, cameraButton, timerButton, switchButton], padding: pad)
            //self.groupAndFill(.vertical, views: [spacer, flashButton, spacer, gridButton, spacer, aspectButton, spacer, cameraButton, spacer, timerButton, spacer, switchButton, spacer], padding: hpad)
            
            
        } else {
            // Portrait: icons/buttons are arranged horizontally
            
            
            // figure out vertical padding to center images
            vpad = (self.frame.size.height - UISettings.buttonSide)/2.0 + 8 // +8 moves it away from the system banner a little (empirical)
            
            // figure out horizontal padding (6 button means 7 spaces)
            //hpad = ((self.frame.size.width - 6.0*(UISettings.buttonSide+2.0*vpad)) / 7.0)
            hpad = ((self.frame.size.width - 6.0*(UISettings.buttonSide)) / 7.0)
            
            spacer = SquareButton(bsize: hpad)
            
            //pad = (self.frame.size.width - 6.0*UISettings.buttonSide) / 7.0
            pad = fmin(abs(hpad), abs(vpad))
            
            print("Laying out CameraSettings (Portrait). vpad:\(vpad) hpad:\(hpad)")
            
            self.groupAndFill(group: .horizontal, views: [flashButton, gridButton, aspectButton, cameraButton, timerButton, switchButton], padding: pad)
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
    
    
    @objc func flashDidPress() {
        log.debug("Flash pressed")
        delegate?.flashPressed()
    }
    
    
    @objc func gridDidPress() {
        log.debug("Grid pressed")
        delegate?.gridPressed()
    }
    
    
    @objc func aspectDidPress() {
        log.debug("Aspect pressed")
        delegate?.aspectPressed()
    }
    
    
    @objc func cameraDidPress() {
        log.debug("Camera pressed")
        delegate?.cameraPressed()
    }
    
    
    @objc func timerDidPress() {
        log.debug("Timer pressed")
        delegate?.timerPressed()
    }
    
    
    @objc func switchDidPress() {
        log.debug("switch camera pressed")
        delegate?.switchPressed()
    }

}
