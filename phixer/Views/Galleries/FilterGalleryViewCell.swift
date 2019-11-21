//
//  FilterGalleryViewCell.swift
//  phixer
//
//  Created by Philip Price on 10/25/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

// Collection cell that has an image above a label, with overlay touchable 'adornments' for rating, favourite and show/hide

import Foundation
import UIKit
//import Kingfisher
import CoreImage

// callback interfaces
protocol FilterGalleryViewCellDelegate: class {
    func hiddenTouched(key:String)
    func favouriteTouched(key:String)
    func ratingTouched(key:String)
}


class FilterGalleryViewCell: UICollectionViewCell {
    
    var theme = ThemeManager.currentTheme()
    

    
    // delegate for handling events
    weak var delegate: FilterGalleryViewCellDelegate?

    public static let reuseID: String = "FilterGalleryViewCell"
    
    var cellIndex:Int = -1 // used for tracking cell reuse
    var key:String = ""
    
    //var imageView : imageView! = imageView()
    var imageView : UIImageView! = UIImageView()
    var label : UILabel = UILabel()
    var adornmentView: UIView = UIView()
    
    var rating: Int = 0
    var favourite:Bool = false
    var show:Bool = true

    
    let defaultWidth:CGFloat = 64.0
    let defaultHeight:CGFloat = 64.0

    fileprivate var initDone:Bool = false
    

    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    private func doInit(){
        if (!initDone){
            initDone = true
            //loadInputs()
        }
    }
    
    
    private func doLayout(){
        
        doInit()
        self.backgroundColor = theme.backgroundColor
        self.layer.cornerRadius = 2.0
        self.layer.borderWidth = 1.0
        self.layer.borderColor = theme.borderColor.cgColor
        self.clipsToBounds = true
        
        
        //imageView.contentMode = .scaleAspectFill
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.frame.size.width = self.width
        imageView.frame.size.height = self.height
        self.addSubview(imageView)
        
        label.textAlignment = .center
        label.textColor = theme.subtitleTextColor
        label.frame.size.width = self.width
        label.frame.size.height = (self.height * 0.2).rounded()
        label.backgroundColor = theme.subtitleColor.withAlphaComponent(0.9)
        label.font = theme.getFont(ofSize: 10.0, weight: UIFont.Weight.thin)
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 0
        self.addSubview(label)
        
        imageView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: self.height)
        label.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: label.frame.height)

        adornmentView.backgroundColor = UIColor.clear
        adornmentView.frame.size = imageView.frame.size
        self.addSubview(adornmentView)
        self.bringSubviewToFront(adornmentView)
        adornmentView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: self.height)

        // position icons withing the adornment view
        layoutAdornments()

        self.bringSubviewToFront(label)
    }
 
    
    
    // MARK: - Configuration

    
    
    public func configureCell(frame: CGRect, index:Int, key:String, image:CIImage?, label:String, rating:Int, favourite:Bool, show:Bool) {
        
        guard image != nil else {
            log.error("NIL image")
            return
        }
        //TODO: placeholder image?
        
        //DispatchQueue.main.async(execute: { () -> Void in
            //log.debug("index:\(index), key:\(key)")
            self.frame = frame
            self.cellIndex = index
            self.key = key
            self.imageView.image = UIImage(ciImage: (image?.resize(size: CGSize(width: self.width, height: self.height))!)!)
            self.label.text = label
            self.rating = rating
            self.favourite = favourite
            self.show = show
            
            // If filter is hidden, show at half intensity
            if (!show){
                self.imageView.alpha = 0.25
                self.label.alpha = 0.4
                //self.layer.borderColor = UIColor(white: 0.6, alpha: 0.4).cgColor
                self.layer.borderColor = self.theme.borderColor.cgColor
            }
            // create the adornment overlay (even if hidden, because you need to be able to un-hide)
            self.setupAdornments()
            
            self.imageView.isHidden = false
            self.doLayout()
            self.setNeedsDisplay()
            
        //})
        
    }
    
    // setup the adornments (favourites, show/hide, ratings etc.) for the current filter
    
    // individual adornments
    fileprivate var showAdornment: UIImageView = UIImageView()
    fileprivate var favAdornment: UIImageView = UIImageView()
    fileprivate var ratingAdornment: UIImageView = UIImageView()
    
    fileprivate func setupAdornments() {
        
        if self.imageView != nil {
            adornmentView.frame = self.imageView.frame
        } else {
            adornmentView.frame = self.frame
        }
        
        // set size of adornments
        let dim: CGFloat = adornmentView.frame.size.height / 8.0

        let adornmentSize = CGSize(width: dim, height: dim)
        
        
        // show/hide
        let showAsset: String =  (self.show == true) ? "ic_accept" : "ic_reject"
        showAdornment.image = UIImage(named: showAsset)?.imageScaled(to: adornmentSize)
        
        // favourite
        var favAsset: String =  "ic_heart_outline"
        // TODO" figure out how to identify something in the favourite (quick select) list
        if (self.favourite){
            favAsset = "ic_heart_filled"
        }
        favAdornment.image = UIImage(named: favAsset)?.imageScaled(to: adornmentSize)
        
        // rating
        var ratingAsset: String =  "ic_star"
        switch (self.rating){
        case 1:
            ratingAsset = "ic_star_filled_1"
        case 2:
            ratingAsset = "ic_star_filled_2"
        case 3:
            ratingAsset = "ic_star_filled_3"
        default:
            break
        }
        ratingAdornment.image = UIImage(named: ratingAsset)?.imageScaled(to: adornmentSize)
        

        // add a little background so that you can see the icons
        showAdornment.backgroundColor = theme.secondaryColor.withAlphaComponent(0.5)
        showAdornment.layer.cornerRadius = 2.0
        
        favAdornment.backgroundColor = showAdornment.backgroundColor
        favAdornment.alpha = showAdornment.alpha
        favAdornment.layer.cornerRadius = showAdornment.layer.cornerRadius
        
        ratingAdornment.backgroundColor = showAdornment.backgroundColor
        ratingAdornment.alpha = showAdornment.alpha
        ratingAdornment.layer.cornerRadius = showAdornment.layer.cornerRadius
        
        // add icons to the adornment view
        adornmentView.addSubview(showAdornment)
        adornmentView.addSubview(favAdornment)
        adornmentView.addSubview(ratingAdornment)
        
    }
    
    
    fileprivate func layoutAdornments(){
        // layout the adornments across the top of the cell
        let dim: CGFloat = adornmentView.frame.size.height / 8.0
        showAdornment.anchorInCorner(.topLeft, xPad: 2.0, yPad: 2.0, width: dim, height: dim)
        favAdornment.anchorToEdge(.top, padding:2.0, width:dim, height:dim)
        ratingAdornment.anchorInCorner(.topRight, xPad: 2.0, yPad: 2.0, width: dim, height: dim)
        
        // make sure the adornment overlay is on top
        self.bringSubviewToFront(adornmentView)
        
        // set the touch handlers
        setAdornmentTouchHandlers()
    }
    
  
    
    /////////////////////
    // Touch Handlers
    /////////////////////
    
    func setAdornmentTouchHandlers(){
        //log.verbose("Adding adornment touch handlers")
        showAdornment.isUserInteractionEnabled = true
        favAdornment.isUserInteractionEnabled = true
        ratingAdornment.isUserInteractionEnabled = true
        adornmentView.isUserInteractionEnabled = true
        
        
        let showRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.showHandler))
        let favRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.favHandler))
        let ratingRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.ratingHandler))
        
        showAdornment.addGestureRecognizer(showRecognizer)
        favAdornment.addGestureRecognizer(favRecognizer)
        ratingAdornment.addGestureRecognizer(ratingRecognizer)

    }

    
    
    // handles touch of the favourite icon
    @objc func showHandler(){
        //log.verbose("hide/show touched")
        if (delegate != nil){
            delegate?.hiddenTouched(key: self.key)
        }
    }
    
    // handles touch of the show/hide icon
    @objc func favHandler(){
        //log.verbose("favourite touched")
        if (delegate != nil){
            delegate?.favouriteTouched(key: self.key)
        }
    }
    
    // handles touch of the rating icon
    @objc func ratingHandler(){
        //log.verbose("rating touched")
        if (delegate != nil){
            delegate?.ratingTouched(key: self.key)
        }
    }

}
