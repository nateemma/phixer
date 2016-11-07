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

class CameraControlsView: UIView {
    
    // delegate for handling events
    weak var delegate: CameraControlsViewDelegate?
    
   //MARK: - Class variables:
    
    let bannerHeight : CGFloat = 64.0
    let buttonSize : CGFloat = 48.0
    let smallIconFactor : CGFloat = 0.75
    
    var isLandscape : Bool = false
    
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
        
        
        activateButton = SquareButton(bsize: buttonSize)
        modeButton = SquareButton(bsize: buttonSize*smallIconFactor)
        menuButton = SquareButton(bsize: buttonSize*smallIconFactor)
    }
    
    func initViews(){
        
        if (!initDone){
            // set the colors etc.
            self.backgroundColor = UIColor.black //temp
            
            photoThumbnail = SquareButton(bsize: buttonSize)
            photoThumbnail.setColor(UIColor.blue)
            
            
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
        
        // get orientation
        isLandscape = UIDevice.current.orientation.isLandscape
        
        // set up layout based on orientation
        if (isLandscape){
            // Landscape: top-to-bottom layout scheme
            
            
            //self.anchorAndFillEdge(.right, xPad: 0, yPad: 0, otherSize: bannerHeight)
            
            // add items to the  view
            photoThumbnail.anchorToEdge(.top, padding: 8, width: buttonSize, height: buttonSize)
            activateButton.anchorInCenter(buttonSize, height: buttonSize)
            modeButton.align(.underCentered, relativeTo: activateButton, padding: 8, width: buttonSize*smallIconFactor, height: buttonSize*smallIconFactor)
            menuButton.align(.underCentered, relativeTo: activateButton, padding: 8, width: buttonSize*smallIconFactor, height: buttonSize*smallIconFactor)
            self.groupAgainstEdge(.vertical, views: [modeButton, menuButton], againstEdge: .bottom, padding: (bannerHeight-buttonSize*smallIconFactor)/2, width: buttonSize*smallIconFactor, height: buttonSize*smallIconFactor)
            
        } else {
            // left-to-right layout scheme
            
            //self.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: bannerHeight)
            
            
            // add items to the  view
            photoThumbnail.anchorToEdge(.left, padding: 8, width: buttonSize, height: buttonSize)
            activateButton.anchorInCenter(buttonSize, height: buttonSize)
            self.groupAgainstEdge(.horizontal, views: [modeButton, menuButton], againstEdge: .right, padding: (bannerHeight-buttonSize*smallIconFactor)/2, width: buttonSize*smallIconFactor, height: buttonSize*smallIconFactor)
            
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
    
    //MARK: - touch handlers
    
    
    func imagePreviewDidPress() {
        delegate?.imagePreviewPressed()
    }
    
    func takePictureDidPress() {
        delegate?.takePicturePressed()
    }
    
    func ModeDidPress() {
        delegate?.modePressed()
    }
    
    func SettingsDidPress() {
        delegate?.settingsPressed()
    }
}
