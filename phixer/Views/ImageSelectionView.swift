//
//  ImageSelectionView.swift
//  Philter
//
//  Created by Philip Price on 9/19/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import UIKit
import Neon
import Photos


// Interface required of controlling View
protocol ImageSelectionViewDelegate: class {
    func changeImagePressed()
    func changeBlendPressed()
    func savePressed()
}



// Class responsible for laying out the Image Selection View (edit/blend image, save)


class ImageSelectionView: UIView {
    
    var theme = ThemeManager.currentTheme()
    

    // delegate for handling events
    weak var delegate: ImageSelectionViewDelegate?
    
   //MARK: - Class variables:
    
    let bannerHeight : CGFloat = 64.0
    let buttonSize : CGFloat = 32.0
    let smallIconFactor : CGFloat = 0.75
    
    var isLandscape : Bool = false
    
    var imageButton: SquareButton!
    var blendButton: SquareButton!
    var saveButton: SquareButton!
    
    var imageLabel:UILabel! = UILabel()
    var blendLabel:UILabel! = UILabel()
    var saveLabel:UILabel! = UILabel()

    var initDone: Bool = false
    
    
    
    //MARK: - Initialisation:
    convenience init(){
        self.init(frame: CGRect.zero)
    }
    
    func initViews(){
        
        if (!initDone){
            initDone = true
 
            // set the colors etc.
            self.backgroundColor = theme.backgroundColor
            
            // set up buttons and labels
            imageButton = SquareButton(bsize: buttonSize)
            blendButton = SquareButton(bsize: buttonSize)
            saveButton = SquareButton(bsize: buttonSize)
            
            saveButton.setImageAsset("ic_unknown")  // TEMP: replace when icon available
            saveButton.setTintable(true)
 
            imageLabel.text = "photo"
            blendLabel.text = "blend"
            saveLabel.text = "save"
            for l in [imageLabel,  blendLabel, saveLabel] {
                l!.font = UIFont.systemFont(ofSize: 10.0)
                l!.textColor = theme.textColor
                l!.textAlignment = .center
            }

            // add the subviews to the main View
            self.addSubview(imageButton)
            self.addSubview(blendButton)
            self.addSubview(saveButton)
            self.addSubview(imageLabel)
            self.addSubview(blendLabel)
            self.addSubview(saveLabel)

            // populate values
            update()
            
            initDone = true
        }
        
        
    }
    
    
    
    //MARK: - View functions
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        theme = ThemeManager.currentTheme()
        initViews()
        
        let pad:CGFloat = 4
        
        // get orientation
        isLandscape = UIDevice.current.orientation.isLandscape
        
        // set up layout based on orientation
        if (isLandscape){
            // Landscape: top-to-bottom layout scheme
            
            
            //self.anchorAndFillEdge(.right, xPad: 0, yPad: 0, otherSize: bannerHeight)
            
            // add items to the  view
            imageButton.anchorToEdge(.top, padding: pad, width: buttonSize, height: buttonSize)
            blendButton.anchorInCenter(width: buttonSize, height: buttonSize)
            saveButton.anchorToEdge(.bottom, padding: pad, width: buttonSize, height: buttonSize)
            
            imageLabel.align(.underCentered, relativeTo: imageButton, padding: pad, width: buttonSize, height: buttonSize/2)
            blendLabel.align(.underCentered, relativeTo: blendButton, padding: pad, width: buttonSize, height: buttonSize/2)
            saveLabel.align(.underCentered, relativeTo: saveButton, padding: pad, width: buttonSize, height: buttonSize/2)

        } else {
            // left-to-right layout scheme
            
            //self.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: bannerHeight)
            
            
            // add items to the  view
            imageButton.anchorToEdge(.left, padding: pad, width: buttonSize, height: buttonSize)
            blendButton.anchorInCenter(width: buttonSize, height: buttonSize)
            saveButton.anchorToEdge(.right, padding: pad, width: buttonSize, height: buttonSize)
            /***
            imageButton.anchorInCorner(.topLeft, xPad: 4*pad, yPad: pad, width: buttonSize, height: buttonSize)
            blendButton.anchorToEdge(.top, padding: pad, width: buttonSize, height: buttonSize)
            saveButton.anchorInCorner(.topRight, xPad: 4*pad, yPad: pad, width: buttonSize, height: buttonSize)
            ***/
            
            imageLabel.align(.underCentered, relativeTo: imageButton, padding: 0, width: buttonSize, height: buttonSize/2)
            blendLabel.align(.underCentered, relativeTo: blendButton, padding: 0, width: buttonSize, height: buttonSize/2)
            saveLabel.align(.underCentered, relativeTo: saveButton, padding: 0, width: buttonSize, height: buttonSize/2)

        }
        
        // register handlers for the various buttons
        imageButton.addTarget(self, action: #selector(self.imageDidPress), for: .touchUpInside)
        blendButton.addTarget(self, action: #selector(self.blendDidPress), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(self.saveDidPress), for: .touchUpInside)
        
    }
    
    
    // set photo image to the last photo in the camera roll
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
                targetSize: imageButton.bounds.size,
                contentMode: .aspectFit,
                options: options,
                resultHandler: { image, _ in
                    DispatchQueue.main.async {
                        self.imageButton.setImage(image!)
                    }
                }
            )
        }
    }
    
    private func loadBlendThumbnail(){
        DispatchQueue.main.async {
            let image = UIImage(ciImage: ImageManager.getCurrentBlendImage(size:self.blendButton.frame.size)!)
            self.blendButton.setImage(image)
        }
    }
    
    
    // called to request an update of the view
    open func update(){
        log.debug("update requested")
        loadPhotoThumbnail()
        loadBlendThumbnail()
    }
    
    
    
    
    /////////////////////////////////
    //MARK: - touch handlers
    /////////////////////////////////
    
    
    @objc func imageDidPress() {
        delegate?.changeImagePressed()
    }
    
    @objc func saveDidPress() {
        delegate?.savePressed()
    }
    
    
    @objc func blendDidPress() {
        delegate?.changeBlendPressed()
    }

}
