//
//  CameraControlsView.swift
//  Philter
//
//  Created by Philip Price on 9/19/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import UIKit
import Neon
import Photos


// Interface required of controlling View
protocol CameraControlsViewDelegate: class {
    func imagePreviewPressed()
    func takePicturePressed()
    func modePressed()
    func settingsPressed()
}



enum InfoMode {
    case camera
    case filter
}

// Class responsible for laying out the Camera Controls View

//TODO: split into distinct views for each mode

class CameraControlsView: UIView {
    
    var theme = ThemeManager.currentTheme()
    

    // delegate for handling events
    weak var delegate: CameraControlsViewDelegate?
    
   //MARK: - Class variables:
    

    let smallIconFactor : CGFloat = 0.75
    
    
    //var photoThumbnail: UIImageView! = UIImageView()
    
    //var activateButton: UIButton! = UIButton(type: .Custom)
    //var modeButton: UIButton! = UIButton()
    //var menuButton: UIButton! = UIButton()
    
    var photoThumbnail: SquareButton!
    var activateButton: SquareButton!
    var modeButton: SquareButton!
    var menuButton: SquareButton!
    
    var currInfoMode: InfoMode = .filter
    
    var initDone: Bool = false
    
    
    
    //MARK: - Initialisation:
    convenience init(){
        self.init(frame: CGRect.zero)
        
        
        activateButton = SquareButton(bsize: UISettings.buttonSide)
        modeButton = SquareButton(bsize: UISettings.buttonSide*smallIconFactor)
        menuButton = SquareButton(bsize: UISettings.buttonSide*smallIconFactor)
    }
    
    func initViews(){
        
        if (!initDone){
            // set the colors etc.
            self.backgroundColor = theme.backgroundColor //temp
            
            photoThumbnail = SquareButton(bsize: UISettings.buttonSide)
            photoThumbnail.setColor(theme.highlightColor)
            
            
            activateButton.setImageAsset("ic_stroked_circle.png")
            menuButton.setImageAsset("ic_gear.png")
            //modeButton.setImageAsset("ic_filters.png")
            setInfoMode(currInfoMode)
            
            
            //TODO: Set photo thumbnail to most recent photo
            
            // add the subviews to the main View
            self.addSubview(photoThumbnail)
            self.addSubview(activateButton)
            self.addSubview(modeButton)
            self.addSubview(menuButton)
            
            // populate values
            update()
            
            initDone = true
        }
        
        
    }
    
    
    
    //MARK: - View functions
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        
        if !initDone {
            initViews()
        }
        
        
        // set up layout based on orientation
        if (UISettings.isLandscape){
            // Landscape: top-to-bottom layout scheme
            
            
            //self.anchorAndFillEdge(.right, xPad: 0, yPad: 0, otherSize: UISettings.panelHeight)
            
            // add items to the  view
            photoThumbnail.anchorToEdge(.top, padding: 8, width: UISettings.buttonSide, height: UISettings.buttonSide)
            activateButton.anchorInCenter(width: UISettings.buttonSide, height: UISettings.buttonSide)
            modeButton.align(.underCentered, relativeTo: activateButton, padding: 8, width: UISettings.buttonSide*smallIconFactor, height: UISettings.buttonSide*smallIconFactor)
            menuButton.align(.underCentered, relativeTo: activateButton, padding: 8, width: UISettings.buttonSide*smallIconFactor, height: UISettings.buttonSide*smallIconFactor)
            self.groupAgainstEdge(group: .vertical, views: [modeButton, menuButton], againstEdge: .bottom, padding: (UISettings.panelHeight-UISettings.buttonSide*smallIconFactor)/2, width: UISettings.buttonSide*smallIconFactor, height: UISettings.buttonSide*smallIconFactor)
            
        } else {
            // left-to-right layout scheme
            
            //self.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: UISettings.panelHeight)
            
            
            // add items to the  view
            photoThumbnail.anchorToEdge(.left, padding: 8, width: UISettings.buttonSide, height: UISettings.buttonSide)
            activateButton.anchorInCenter(width: UISettings.buttonSide, height: UISettings.buttonSide)
            self.groupAgainstEdge(group: .horizontal, views: [modeButton, menuButton], againstEdge: .right, padding: (UISettings.panelHeight-UISettings.buttonSide*smallIconFactor)/2, width: UISettings.buttonSide*smallIconFactor, height: UISettings.buttonSide*smallIconFactor)
            
        }
        
        // register handlers for the various buttons
        photoThumbnail.addTarget(self, action: #selector(self.imagePreviewDidPress), for: .touchUpInside)
        activateButton.addTarget(self, action: #selector(self.takePictureDidPress), for: .touchUpInside)
        modeButton.addTarget(self, action: #selector(self.ModeDidPress), for: .touchUpInside)
        menuButton.addTarget(self, action: #selector(self.SettingsDidPress), for: .touchUpInside)        
        
    }
    
    
    func loadPhotoThumbnail(){
     
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        let last = fetchResult.lastObject
        
        if let lastAsset = last {
            let options = PHImageRequestOptions()
            options.version = .current
            
            PHImageManager.default().requestImage(
                for: lastAsset,
                targetSize: photoThumbnail.bounds.size,
                contentMode: .aspectFit,
                options: options,
                resultHandler: { image, _ in
                    DispatchQueue.main.async {
                        self.photoThumbnail.setImage(image!)
                    }
                }
            )
        }
    }
    
    
    // called to request an update of the view
    open func update(){
        log.debug("update requested")
        loadPhotoThumbnail()
    }
    
    
    // sets the info mode
    open func setInfoMode(_ mode:InfoMode){
        currInfoMode = mode
        
        // Note: set the icon to the opposite mode since it initiates a switch to that mode
        switch (currInfoMode){
        case .camera:
            modeButton.setImageAsset("ic_filters")
            break
        case .filter:
            modeButton.setImageAsset("ic_live")
            break
        }
    }
    
    
    /////////////////////////////////
    //MARK: - touch handlers
    /////////////////////////////////
    
    
    @objc func imagePreviewDidPress() {
        delegate?.imagePreviewPressed()
    }
    
    @objc func takePictureDidPress() {
        delegate?.takePicturePressed()
    }
    
    @objc func ModeDidPress() {
        delegate?.modePressed()
    }
    
    @objc func SettingsDidPress() {
        delegate?.settingsPressed()
    }

}
