//
//  CameraControlsView.swift
//  Philter
//
//  Created by Philip Price on 9/19/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import UIKit
import Neon


// Interface required of controlling View
protocol CameraControlsViewDelegate: class {
    func imagePreviewPressed()
    func takePicturePressed()
    func filterSelectionPressed()
    func settingsPressed()
}




// Class responsible for laying out the Camera Controls View

class CameraControlsView: UIView {
    
    //MARK: - Class variables:
    
    let bannerHeight : CGFloat = 64.0
    let buttonSize : CGFloat = 48.0
    let smallIconFactor : CGFloat = 0.75
    
    var isLandscape : Bool = false
    
    //var photoThumbnail: UIImageView! = UIImageView()
    
    //var activateButton: UIButton! = UIButton(type: .Custom)
    //var filterButton: UIButton! = UIButton()
    //var menuButton: UIButton! = UIButton()
    
    var photoThumbnail: SquareButton!
    var activateButton: SquareButton!
    var filterButton: SquareButton!
    var menuButton: SquareButton!
    
    var initDone: Bool = false
    
    // delegate for handling events
    weak var delegate: CameraControlsViewDelegate?
    
    
    
    //MARK: - Initialisation:
    convenience init(){
        self.init(frame: CGRect.zero)
        
    }
    
    func initViews(){
        
        if (!initDone){
            // set the colors etc.
            self.backgroundColor = UIColor.flatBlack() //temp
            
            photoThumbnail = SquareButton(bsize: buttonSize)
            photoThumbnail.setBackgroundColor(color: UIColor.blue)
            
            
            activateButton = SquareButton(bsize: buttonSize)
            filterButton = SquareButton(bsize: buttonSize*smallIconFactor)
            menuButton = SquareButton(bsize: buttonSize*smallIconFactor)
            
            activateButton.setImage("ic_stroked_circle.png")
            filterButton.setImage("ic_filters.png")
            menuButton.setImage("ic_gear.png")
            
            
            //TODO: Set photo thumbnail to most recent photo
            
            // add the subviews to the main View
            self.addSubview(photoThumbnail)
            self.addSubview(activateButton)
            self.addSubview(filterButton)
            self.addSubview(menuButton)
            
            
            initDone = true
        }
        
        weak var delegate: CameraControlsViewDelegate?
        
    }
    
    
    
    //MARK: - View functions
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        
        if !initDone {
            initViews()
        }
        
        // get orientation
        isLandscape = UIDevice.current.orientation.isLandscape
        
        // set up layout based on orientation
        if (isLandscape){
            // left-to-right layout scheme
            
            
            self.anchorAndFillEdge(.right, xPad: 0, yPad: 0, otherSize: bannerHeight)
            
            // add items to the  view
            photoThumbnail.anchorToEdge(.top, padding: 8, width: buttonSize, height: buttonSize)
            activateButton.anchorInCenter(buttonSize, height: buttonSize)
            filterButton.align(.underCentered, relativeTo: activateButton, padding: 8, width: buttonSize*smallIconFactor, height: buttonSize*smallIconFactor)
            menuButton.align(.underCentered, relativeTo: activateButton, padding: 8, width: buttonSize*smallIconFactor, height: buttonSize*smallIconFactor)
            self.groupAgainstEdge(.vertical, views: [filterButton, menuButton], againstEdge: .bottom, padding: (bannerHeight-buttonSize*smallIconFactor)/2, width: buttonSize*smallIconFactor, height: buttonSize*smallIconFactor)
            
        } else {
            // Portrait: top-to-bottom layout scheme
            
            self.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: bannerHeight)
            
            
            // add items to the  view
            photoThumbnail.anchorToEdge(.left, padding: 8, width: buttonSize, height: buttonSize)
            activateButton.anchorInCenter(buttonSize, height: buttonSize)
            self.groupAgainstEdge(.horizontal, views: [filterButton, menuButton], againstEdge: .right, padding: (bannerHeight-buttonSize*smallIconFactor)/2, width: buttonSize*smallIconFactor, height: buttonSize*smallIconFactor)
            
        }
        
        // register handlers for the various buttons
        photoThumbnail.addTarget(self, action: #selector(self.imagePreviewDidPress), for: .touchUpInside)
        activateButton.addTarget(self, action: #selector(self.takePictureDidPress), for: .touchUpInside)
        filterButton.addTarget(self, action: #selector(self.FilterSelectionDidPress), for: .touchUpInside)
        menuButton.addTarget(self, action: #selector(self.SettingsDidPress), for: .touchUpInside)

    
    }
    
    //MARK: - touch handlers
    
        
        func imagePreviewDidPress() {
            delegate?.imagePreviewPressed()
        }
    
        func takePictureDidPress() {
            delegate?.takePicturePressed()
        }
    
        func FilterSelectionDidPress() {
            delegate?.filterSelectionPressed()
        }
    
        func SettingsDidPress() {
            delegate?.settingsPressed()
        }
}
