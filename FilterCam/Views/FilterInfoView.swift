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
    func categoryPressed()
    func filterPressed()
    func swapCameraPressed()
}



class FilterInfoView: UIView {
    
    var isLandscape : Bool = false
    
    // display items
    var categoryIcon: SquareButton! = SquareButton()
    var categoryLabel: UIButton! = UIButton()
    var filterIcon: SquareButton! = SquareButton()
    var filterLabel: UIButton! = UIButton()
    var swapIcon: SquareButton! = SquareButton()

    var buttonSize : CGFloat = 48.0
    
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
            
            //if (buttonSize>self.frame.size.height){ buttonSize = self.frame.size.height - 4 }
            buttonSize = fmin(self.frame.size.height, self.frame.size.width) - 8
            
            categoryIcon = SquareButton(bsize: buttonSize)
            filterIcon = SquareButton(bsize: buttonSize)
            swapIcon = SquareButton(bsize: buttonSize)

            // initial values

            categoryIcon.setImageAsset("ic_category")
            

            categoryLabel.frame.size.height = self.frame.size.height * 0.9
            categoryLabel.frame.size.width = self.frame.size.width / 3.0
            categoryLabel.setTitleColor(UIColor.white, for: .normal)
            categoryLabel.titleLabel!.font = UIFont.boldSystemFont(ofSize: 14.0)
            //categoryLabel.titleLabel!.textAlignment = .left
            categoryLabel.contentHorizontalAlignment = UIControlContentHorizontalAlignment.left

            
            filterIcon.setImageAsset("ic_filters")
            
            filterLabel.frame.size.height = self.frame.size.height * 0.9
            filterLabel.frame.size.width = self.frame.size.width / 3.0
            filterLabel.setTitleColor(UIColor.white, for: .normal)
            filterLabel.titleLabel!.font = UIFont.boldSystemFont(ofSize: 14.0)
            //filterLabel.titleLabel!.textAlignment = .left
            filterLabel.contentHorizontalAlignment = UIControlContentHorizontalAlignment.left
            
            swapIcon.setImageAsset("ic_swap")

           
            // show the sub views
            self.addSubview(categoryIcon)
            self.addSubview(categoryLabel)
            self.addSubview(filterIcon)
            self.addSubview(filterLabel)
            self.addSubview(swapIcon)
                    
            
            // register for change notifications (don't do this before the views are set up)
            //filterManager.setCategoryChangeNotification(callback: self.categoryChanged())
            //filterManager.setFilterChangeNotification(callback: self.filterChanged())
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
        

        // place at the bottom of the view to avoid the battery icon
        categoryIcon.anchorInCorner(.bottomLeft, xPad: 2, yPad: 2, width: buttonSize, height: buttonSize)
        categoryLabel.align(.toTheRightCentered, relativeTo: categoryIcon, padding: 0, width: categoryLabel.frame.size.width, height: categoryLabel.frame.size.height)
        filterIcon.anchorToEdge(.bottom, padding: 2, width: buttonSize, height: buttonSize)
        filterLabel.align(.toTheRightCentered, relativeTo: filterIcon, padding: 0, width: filterLabel.frame.size.width, height: filterLabel.frame.size.height)
        swapIcon.anchorInCorner(.bottomRight, xPad: 2, yPad: 2, width: buttonSize, height: buttonSize)

        
        // register touch handlers
        categoryIcon.addTarget(self, action: #selector(self.categoryDidPress), for: .touchUpInside)
        categoryLabel.addTarget(self, action: #selector(self.categoryDidPress), for: .touchUpInside)
        filterIcon.addTarget(self, action: #selector(self.filterDidPress), for: .touchUpInside)
        filterLabel.addTarget(self, action: #selector(self.filterDidPress), for: .touchUpInside)
        swapIcon.addTarget(self, action: #selector(self.swapDidPress), for: .touchUpInside)
      
        update()
    }
    

    func update(){
        categoryLabel.setTitle(filterManager.getCurrentCategory(), for: .normal)
        filterLabel.setTitle(filterManager.getCurrentFilterKey(), for: .normal)
        //log.verbose("key: \(filterManager.getCurrentFilterKey())")
    }
    
    


    
    ///////////////////////////////////
    //MARK: - touch handlers
    ///////////////////////////////////
    
    @objc func categoryDidPress() {
        delegate?.categoryPressed()
    }
    
    @objc func filterDidPress() {
        delegate?.filterPressed()
    }
    @objc func swapDidPress() {
        delegate?.swapCameraPressed()
    }
    
}
