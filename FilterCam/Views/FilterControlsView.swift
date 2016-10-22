//
//  FilterControlsView.swift
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
protocol FilterControlsViewDelegate: class {
    func categoryPressed()
    func filterPressed()
    func filterSettingsPressed()
}


class FilterControlsView: UIView {
    
    var isLandscape : Bool = false
    
    // display items
    var categoryButton: SquareButton! = SquareButton()
    var filterButton: SquareButton! = SquareButton()
    var settingsButton: SquareButton! = SquareButton()

    var buttonSize : CGFloat = 32.0
    
    var initDone: Bool = false
   
    
    // delegate for handling events
    weak var delegate: FilterControlsViewDelegate?

    
    
    convenience init(){
        self.init(frame: CGRect.zero)
    }
    
    
    func initViews(){
        
        if (!initDone){
            // set the colors etc.

            self.backgroundColor = UIColor.black
            
            if (buttonSize>self.frame.size.height){ buttonSize = self.frame.size.height - 4 }
            
            categoryButton = SquareButton(bsize: buttonSize)
            filterButton = SquareButton(bsize: buttonSize)
            settingsButton = SquareButton(bsize: buttonSize)

            // initial values, just to have something there

            categoryButton.setImageAsset("ic_category")
            filterButton.setImageAsset("ic_filters")
            settingsButton.setImageAsset("ic_sliders")
            settingsButton.highlightOnSelection(true)

           
            // show the sub views
            self.addSubview(categoryButton)
            self.addSubview(filterButton)
            self.addSubview(settingsButton)
            
            update()
            
            initDone = true
        }
    }

    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // get orientation
        //isLandscape = UIDevice.current.orientation.isLandscape

        if !initDone {
            initViews()
        }
        
        //self.groupAndFill(.horizontal, views: [categoryButton, filterButton, settingsButton], padding: 2)
        categoryButton.anchorToEdge(.left, padding: 8, width: buttonSize, height: buttonSize)
        settingsButton.anchorToEdge(.right, padding: 8, width: buttonSize, height: buttonSize)
        filterButton.anchorInCenter(buttonSize, height: buttonSize)
        
        // TODO: update current values
        update()
        
        // register handler for the filter and settings button
        categoryButton.addTarget(self, action: #selector(self.categoryDidPress), for: .touchUpInside)
        filterButton.addTarget(self, action: #selector(self.filterDidPress), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(self.filterSettingsDidPress), for: .touchUpInside)
      
    }
    
    
    
    func update(){
        
        // leave filter for now, updated directly from setFilterName. Eventually replace when filter management is implemented
    }
    
    //MARK: - touch handlers
    
    func categoryDidPress() {
        delegate?.categoryPressed()
    }
    
    func filterDidPress() {
        delegate?.filterPressed()
    }
    
    func filterSettingsDidPress() {
        delegate?.filterSettingsPressed()
    }
    
}
