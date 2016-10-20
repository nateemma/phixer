//
//  CameraInfoView.swift
//  Philter
//
//  Created by Philip Price on 9/16/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import Neon


// Class responsible for laying out the Camera Information View
// This is a container class for display the overlay that provides information about the current Camera/Image view

// No callbacks, just an information-only display


class CameraInfoView: UIView {
    
    var isLandscape : Bool = false
    
    // display items
    var modeIcon: SquareButton! = SquareButton()
    var currISO: UIButton! = UIButton()
    var currSpeed: UIButton! = UIButton()
    var currWB: UIButton! = UIButton()
    
    let buttonSize : CGFloat = 32.0
   
    var initDone: Bool = false
   
    
    // delegate for handling events
    //weak var delegate: CameraInfoViewDelegate?

    
    
    convenience init(){
        self.init(frame: CGRect.zero)
    }
    
    
    func initViews(){
        
        if (!initDone){
            // set the colors etc.
            //self.backgroundColor = UIColor.clear
            //self.isOpaque = false
            self.backgroundColor = UIColor.black
            //self.alpha = 0.8
            
            modeIcon  = SquareButton(bsize: buttonSize)
            initButton(currISO)
            initButton(currSpeed)
            initButton(currWB)

            modeIcon.setImageAsset("ic_live")
            // initial values, just to have something there
            currISO.setTitle("ISO: ?", for: .normal)
            currSpeed.setTitle("Speed: ?", for: .normal)
            currWB.setTitle("WB: ?", for: .normal)
           
            // show the sub views
            self.addSubview(modeIcon)
            self.addSubview(currISO)
            self.addSubview(currSpeed)
            self.addSubview(currWB)
            
            update()
            
            initDone = true
        }
    }

    
    func initButton(_ button: UIButton){
        button.backgroundColor = UIColor.clear
        button.titleLabel?.textColor = UIColor.white
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.titleLabel?.textAlignment = .left
        //button.frame.height = 32
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // get orientation
        //isLandscape = UIDevice.current.orientation.isLandscape

        if !initDone {
            initViews()
        }
        
        self.groupAndFill(.horizontal, views: [modeIcon, currISO, currSpeed, currWB], padding: 8)
        
        // TODO: update current values
        update()
              
    }
    
    
    func update(){
        currISO.setTitle("ISO: \(CameraManager.getCurrentISO())", for: .normal)
        currSpeed.setTitle("Speed: \(CameraManager.getCurrentSpeed())", for: .normal)
        currWB.setTitle("WB: ?", for: .normal)
        
        // leave filter for now, updated directly from setFilterName. Eventually replace when filter management is implemented
    }
    
    
}
