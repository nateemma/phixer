//
//  RatingView.swift
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
protocol RatingViewDelegate: class {
    func showPressed()
    func favoritePressed()
    func ratingPressed()
}



class RatingView: UIView {
    
    var theme = ThemeManager.currentTheme()
    
    var initDone: Bool = false
    
    var filterManager:FilterManager = FilterManager.sharedInstance
    var currFilterKey: String = ""
   
    
    // delegate for handling events
    weak var delegate: RatingViewDelegate?

    
    // individual display items
    fileprivate var showAdornment: UIImageView = UIImageView()
    fileprivate var favAdornment: UIImageView = UIImageView()
    fileprivate var ratingAdornment: UIImageView = UIImageView()

    // values controlling displays
    fileprivate var show: Bool = true
    fileprivate var fav: Bool = false
    fileprivate var rating: Int = 0

    
    convenience init(){
        self.init(frame: CGRect.zero)
    }
    
    
    func initViews(){
        
        if (!initDone){
            initDone = true
        }
    }


    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !initDone {
            initViews()
        }
        
        self.backgroundColor = theme.subtitleColor
        
        setupAdornments()
        layoutAdornments()
    }
    

    // update the display
    public func update(){
        setupAdornments()
    }
    
    // set the filter key
    public func setFilter(key: String){
        if (self.currFilterKey != key) {
            self.currFilterKey = key
            update()
        }
    }
    
    
    
    // setup the adornments (favourites, show/hide, ratings etc.) for the current filter
    
    fileprivate func setupAdornments() {
        
        if(self.currFilterKey.isEmpty)   {
            show = true
            fav = false
            rating = 0
        } else {
            show = !(filterManager.isHidden(key: self.currFilterKey))
            fav = filterManager.isFavourite(key: self.currFilterKey)
            rating = filterManager.getRating(key: self.currFilterKey)
        }
        
        
        // set size of adornments
        let dim: CGFloat = (self.frame.size.height * 0.8).rounded()
        let adornmentSize = CGSize(width: dim, height: dim)
        
        
        // show/hide
        let showAsset: String =  (self.show == true) ? "ic_accept" : "ic_reject"
        showAdornment.image = UIImage(named: showAsset)?.imageScaled(to: adornmentSize)
        
        // favourite
        var favAsset: String =  (self.fav == true) ? "ic_heart_filled" : "ic_heart_outline"
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
            ratingAsset = "ic_star"
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
    }
    
    
    fileprivate func layoutAdornments(){
        
        self.addSubview(showAdornment)
        self.addSubview(favAdornment)
        self.addSubview(ratingAdornment)

        let dim: CGFloat = (self.frame.size.height * 0.8).rounded()
        let pad: CGFloat = 2.0
        showAdornment.anchorInCorner(.bottomLeft, xPad:pad, yPad:pad, width: dim, height: dim)
        ratingAdornment.anchorInCorner(.bottomRight, xPad:pad, yPad:pad, width: dim, height: dim)
        favAdornment.anchorToEdge(.bottom, padding:pad, width:dim, height:dim)
        
        // add touch handlers for the adornments
        log.verbose("Adding adornment touch handlers")
        showAdornment.isUserInteractionEnabled = true
        favAdornment.isUserInteractionEnabled = true
        ratingAdornment.isUserInteractionEnabled = true
        
        
        let showRecognizer = UITapGestureRecognizer(target: self, action: #selector(showTouched))
        let favRecognizer = UITapGestureRecognizer(target: self, action: #selector(favTouched))
        let ratingRecognizer = UITapGestureRecognizer(target: self, action: #selector(ratingTouched))
        
        showAdornment.addGestureRecognizer(showRecognizer)
        favAdornment.addGestureRecognizer(favRecognizer)
        ratingAdornment.addGestureRecognizer(ratingRecognizer)
    }
    
    
    

    
    ///////////////////////////////////
    //MARK: - touch handlers
    ///////////////////////////////////
    
    @objc func showTouched() {
        delegate?.showPressed()
    }
    
    @objc func favTouched() {
        delegate?.favoritePressed()
    }
    @objc func ratingTouched() {
        delegate?.ratingPressed()
    }
    
}
