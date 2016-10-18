//
//  FilterInfoView.swift
//  Philter
//
//  Created by Philip Price on 9/16/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import Neon


// Class responsible for laying out the Filter Information View
// This is a container class for display the overlay that provides information about the current Filter view

// Interface required of controlling View
protocol FilterInfoViewDelegate: class {
    func filterPressed()
    func filterSettingsPressed()
}


class FilterInfoView: UIView {
    
    var isLandscape : Bool = false
    
    // display items
    var modeIcon: SquareButton! = SquareButton()
    var currFilter: UIButton! = UIButton()
    var settingsButton: SquareButton! = SquareButton()

    var buttonSize : CGFloat = 32.0
    
    var initDone: Bool = false
   
    
    // delegate for handling events
    weak var delegate: FilterInfoViewDelegate?

    
    
    convenience init(){
        self.init(frame: CGRect.zero)
    }
    
    
    func initViews(){
        
        if (!initDone){
            // set the colors etc.

            self.backgroundColor = UIColor.flatBlack()
            
            if (buttonSize>self.frame.size.height){ buttonSize = self.frame.size.height - 4 }
            
            modeIcon = SquareButton(bsize: buttonSize)
            initButton(currFilter)
            currFilter.frame = CGRect(x:0, y:0, width:128, height:buttonSize)
            settingsButton = SquareButton(bsize: buttonSize)

            // initial values, just to have something there

            modeIcon.setImageAsset("ic_filters")
            settingsButton.setImageAsset("ic_sliders")
            settingsButton.highlightOnSelection(true)
            setFilterName("(no filter)")

           
            // show the sub views
            self.addSubview(modeIcon)
            self.addSubview(currFilter)
            self.addSubview(settingsButton)
            
            update()
            
            initDone = true
        }
    }

    
    func initButton(_ button: UIButton){
        button.backgroundColor = UIColor.clear
        button.titleLabel?.textColor = UIColor.white
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.titleLabel?.textAlignment = .left
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // get orientation
        //isLandscape = UIDevice.current.orientation.isLandscape

        if !initDone {
            initViews()
        }
        
        self.groupAndFill(.horizontal, views: [modeIcon, settingsButton, currFilter], padding: 8)
        
        // TODO: update current values
        update()
        
        // register handler for the filter and settings button
        currFilter.addTarget(self, action: #selector(self.filterDidPress), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(self.filterSettingsDidPress), for: .touchUpInside)
      
    }
    
    
    func setFilterName(_ name:String){
        currFilter.setTitle(name, for: .normal)
        update()
    }
    
    
    func update(){
        
        // leave filter for now, updated directly from setFilterName. Eventually replace when filter management is implemented
    }
    
    //MARK: - touch handlers
    
    func filterDidPress() {
        delegate?.filterPressed()
    }
    
    func filterSettingsDidPress() {
        delegate?.filterSettingsPressed()
    }
    
}
