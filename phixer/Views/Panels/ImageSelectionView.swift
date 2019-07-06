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
    
    let smallIconFactor : CGFloat = 0.75
    
    var imageButton: SquareButton!
    var blendButton: SquareButton!
    var saveButton: SquareButton!
    
    var imageLabel:UILabel! = UILabel()
    var blendLabel:UILabel! = UILabel()
    var saveLabel:UILabel! = UILabel()

    var initDone: Bool = false
    
    var showBlend:Bool = true
    var showSave:Bool = true

    //MARK: Accessors
    
    public func enableBlend(_ enable:Bool){
        showBlend = enable
    }
    
    public func enableSave(_ enable:Bool){
        showSave = enable
    }

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
            imageButton = SquareButton(bsize: UISettings.buttonSide)
            blendButton = SquareButton(bsize: UISettings.buttonSide)
            saveButton = SquareButton(bsize: UISettings.buttonSide)
            
            saveButton.setImageAsset("ic_save")
            saveButton.setTintable(true)
 
            imageLabel.text = "photo"
            blendLabel.text = "blend"
            saveLabel.text = "save"
            for l in [imageLabel,  blendLabel, saveLabel] {
                l!.font = UIFont.systemFont(ofSize: 10.0, weight: UIFont.Weight.thin)
                l!.textColor = theme.textColor
                l!.textAlignment = .center
            }

            // add the subviews to the main View
            self.addSubview(imageButton)
            self.addSubview(imageLabel)
 
            if showBlend {
                self.addSubview(blendButton)
                self.addSubview(blendLabel)
            }
            
            if showSave {
                self.addSubview(saveButton)
                self.addSubview(saveLabel)
            }

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
        
        // set up layout based on orientation
        if (UISettings.isLandscape){
            // Landscape: top-to-bottom layout scheme
            
            
            //self.anchorAndFillEdge(.right, xPad: 0, yPad: 0, otherSize: UISettings.panelHeight)
            
            // add items to the  view
            imageButton.anchorToEdge(.top, padding: pad, width: UISettings.buttonSide, height: UISettings.buttonSide)
            blendButton.anchorInCenter(width: UISettings.buttonSide, height: UISettings.buttonSide)
            saveButton.anchorToEdge(.bottom, padding: pad, width: UISettings.buttonSide, height: UISettings.buttonSide)
            
            imageLabel.align(.underCentered, relativeTo: imageButton, padding: pad, width: UISettings.buttonSide, height: UISettings.buttonSide/2)
            blendLabel.align(.underCentered, relativeTo: blendButton, padding: pad, width: UISettings.buttonSide, height: UISettings.buttonSide/2)
            saveLabel.align(.underCentered, relativeTo: saveButton, padding: pad, width: UISettings.buttonSide, height: UISettings.buttonSide/2)

        } else {
            // left-to-right layout scheme
            
            //self.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: UISettings.panelHeight)
            
            
            // add items to the  view
            imageButton.anchorToEdge(.left, padding: pad, width: UISettings.buttonSide, height: UISettings.buttonSide)
            blendButton.anchorInCenter(width: UISettings.buttonSide, height: UISettings.buttonSide)
            saveButton.anchorToEdge(.right, padding: pad, width: UISettings.buttonSide, height: UISettings.buttonSide)
            /***
            imageButton.anchorInCorner(.topLeft, xPad: 4*pad, yPad: pad, width: UISettings.buttonSide, height: UISettings.buttonSide)
            blendButton.anchorToEdge(.top, padding: pad, width: UISettings.buttonSide, height: UISettings.buttonSide)
            saveButton.anchorInCorner(.topRight, xPad: 4*pad, yPad: pad, width: UISettings.buttonSide, height: UISettings.buttonSide)
            ***/
            
            imageLabel.align(.underCentered, relativeTo: imageButton, padding: 0, width: UISettings.buttonSide, height: UISettings.buttonSide/2)
            blendLabel.align(.underCentered, relativeTo: blendButton, padding: 0, width: UISettings.buttonSide, height: UISettings.buttonSide/2)
            saveLabel.align(.underCentered, relativeTo: saveButton, padding: 0, width: UISettings.buttonSide, height: UISettings.buttonSide/2)

        }
        
        // register handlers for the various buttons
        imageButton.addTarget(self, action: #selector(self.imageDidPress), for: .touchUpInside)
        blendButton.addTarget(self, action: #selector(self.blendDidPress), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(self.saveDidPress), for: .touchUpInside)
        
    }
    
    
    // set photo image to the last photo in the camera roll
    func loadPhotoThumbnail(){
     
        let tgtSize = imageButton.bounds.size
        
        // set the photo thumbnail to the current input image
        if let currImage = InputSource.getCurrentImage() {
            self.imageButton.setImage(UIImage(ciImage: currImage.resize(size: tgtSize)!))
        } else {
            // no image, set to most recent photo
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            let last = fetchResult.lastObject
            
            if let lastAsset = last {
                let options = PHImageRequestOptions()
                options.version = .current
                
                PHImageManager.default().requestImage(
                    for: lastAsset,
                    targetSize: tgtSize,
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
