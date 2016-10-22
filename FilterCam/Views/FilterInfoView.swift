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
    func swapCameraPressed()
}


class FilterInfoView: UIView {
    
    var isLandscape : Bool = false
    
    // display items
    var categoryIcon: SquareButton! = SquareButton()
    var categoryLabel: UILabel! = UILabel()
    var filterIcon: SquareButton! = SquareButton()
    var filterLabel: UILabel! = UILabel()
    var swapIcon: SquareButton! = SquareButton()

    var buttonSize : CGFloat = 32.0
    
    var initDone: Bool = false
    
    var filterManager:FilterManager = FilterManager.sharedInstance
   
    
    // delegate for handling events
    weak var delegate: FilterInfoViewDelegate?

    
    
    convenience init(){
        self.init(frame: CGRect.zero)
        
        //TODO: register callbacks with FilterManager
    }
    
    
    func initViews(){
        
        if (!initDone){
            // set the colors etc.

            self.backgroundColor = UIColor.black
            
            if (buttonSize>self.frame.size.height){ buttonSize = self.frame.size.height - 2 }
            
            categoryIcon = SquareButton(bsize: buttonSize)
            filterIcon = SquareButton(bsize: buttonSize)
            swapIcon = SquareButton(bsize: buttonSize)

            // initial values

            categoryIcon.setImageAsset("ic_category")
            

            categoryLabel.frame.size.height = self.frame.size.height * 0.9
            categoryLabel.frame.size.width = self.frame.size.width / 3.0
            categoryLabel.textAlignment = .left
            categoryLabel.textColor = UIColor.white
            categoryLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
            
            filterIcon.setImageAsset("ic_filters")
            
            filterLabel.frame.size.height = self.frame.size.height * 0.9
            filterLabel.frame.size.width = self.frame.size.width / 3.0
            filterLabel.textAlignment = .left
            filterLabel.textColor = UIColor.white
            filterLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
            
            swapIcon.setImageAsset("ic_front_back")

           
            // show the sub views
            self.addSubview(categoryIcon)
            self.addSubview(categoryLabel)
            self.addSubview(filterIcon)
            self.addSubview(filterLabel)
            self.addSubview(swapIcon)
            
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
        
        //self.groupAndFill(.horizontal, views: [categoryIcon, categoryLabel, filterIcon, filterLabel, swapIcon], padding: 8)
        categoryIcon.anchorToEdge(.left, padding: 8, width: buttonSize, height: buttonSize)
        categoryLabel.align(.toTheRightCentered, relativeTo: categoryIcon, padding: 0, width: categoryLabel.frame.size.width, height: categoryLabel.frame.size.height)
        filterIcon.anchorInCenter(buttonSize, height: buttonSize)
        filterLabel.align(.toTheRightCentered, relativeTo: filterIcon, padding: 0, width: filterLabel.frame.size.width, height: filterLabel.frame.size.height)
        swapIcon.anchorToEdge(.right, padding: 8, width: buttonSize, height: buttonSize)
        
        
        // register handler for the filter and settings button
        swapIcon.addTarget(self, action: #selector(self.swapDidPress), for: .touchUpInside)
      
        update()
    }
    

    func update(){
        categoryLabel.text = filterManager.getCurrentCategory().rawValue
        filterLabel.text = filterManager.getCurrentFilterKey()
    }
    
    //MARK: - touch handlers
    
    
    func swapDidPress() {
        delegate?.swapCameraPressed()
    }
    
}
