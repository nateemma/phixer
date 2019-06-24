//
//  FilterGalleryViewCell.swift
//  phixer
//
//  Created by Philip Price on 10/25/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

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
    
    var renderView : RenderView! // only allocate when needed
    var label : UILabel = UILabel()
    var adornmentView: UIView = UIView()
    var descriptor: FilterDescriptor!
    
    let defaultWidth:CGFloat = 64.0
    let defaultHeight:CGFloat = 64.0
    
    // static vars (shared across all instances)
    fileprivate static var filterManager:FilterManager = FilterManager.sharedInstance
    //fileprivate static var sample:CIImage? = nil
    fileprivate static var blend:CIImage? = nil

    fileprivate var initDone:Bool = false
    
    fileprivate var filteredImage:UIImage? = nil
    
    fileprivate var filter:FilterDescriptor? = nil
    
    fileprivate var filterDescriptor:FilterDescriptor?

    
    
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
        
        renderView.contentMode = .scaleAspectFill
        //renderView.contentMode = .scaleAspectFit
        renderView.clipsToBounds = true
        //renderView.frame.size = CGSize(width:defaultWidth, height:defaultHeight)
        renderView.frame.size.width = self.width
        renderView.frame.size.height = self.height
        self.addSubview(renderView)
        
        label.textAlignment = .center
        label.textColor = theme.subtitleTextColor
        label.frame.size.width = self.width
        label.frame.size.height = (self.height * 0.2).rounded()
        label.backgroundColor = theme.subtitleColor.withAlphaComponent(0.9)
        label.font = UIFont.boldSystemFont(ofSize: 10.0)
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 0
        self.addSubview(label)
        
        //log.verbose("renderView h:\(self.height * 0.7)")
        //renderView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: self.height * 0.8)
        //label.alignAndFill(align: .underCentered, relativeTo: renderView, padding: 0)
        renderView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: self.height)
        label.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: label.frame.height)

        adornmentView.backgroundColor = UIColor.clear
        adornmentView.frame.size = renderView.frame.size
        self.addSubview(adornmentView)
        self.bringSubviewToFront(adornmentView)
        //adornmentView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: self.height * 0.8)
        adornmentView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: self.height)

        // position icons withing the adornment view
        layoutAdornments()

        self.bringSubviewToFront(label)
    }
 
    
    
    fileprivate func loadInputs(){

        //let size = (renderView?.frame.size)!
        let size = CGSize(width: (renderView?.frame.size.width)! * 6, height: (renderView?.frame.size.height)! * 6)

        //TODO: get images from cache (already downsized and filtered)
        
        /***
        // downsize input images since we really only need thumbnails
        //sample = ImageManager.getCurrentSampleImage(size:size)
        if FilterGalleryViewCell.sample == nil {
            FilterGalleryViewCell.sample = EditManager.getPreviewImage()?.resize(size: size)
            FilterGalleryViewCell.blend = ImageManager.getCurrentBlendImage(size:size)
        }
        ***/
    }
    
    
    
    // MARK: - Configuration

/***
    override func prepareForReuse() {
        //renderView = RenderView()
        renderView = nil
        //renderView.isHidden = true
        super.prepareForReuse()
    }
***/
    
    
    public func configureCell(frame: CGRect, index:Int, key:String) {
        
        DispatchQueue.main.async(execute: { () -> Void in
            //log.debug("index:\(index), key:\(key)")
            self.cellIndex = index
    
            // allocate the RenderView
            self.renderView = FilterGalleryViewCell.filterManager.getRenderView(key: key)

            /***
            //FilterGalleryViewCell.sample = ImageCache.get(key: key)
            
            // re-size the contents to match the cell
            self.renderView.frame = frame
            self.renderView.image = ImageCache.get(key: key)
             ***/
            
            // get the descriptor and setup adornments etc. accordingly
            self.descriptor = FilterGalleryViewCell.filterManager.getFilterDescriptor(key: key)

            
            //self.renderContainer.label.text = descriptor?.key
            //self.label.text = key
            self.label.text = self.descriptor?.title

            // If filter is disabled, show at half intensity
            if (self.descriptor != nil){
                if (FilterGalleryViewCell.filterManager.isHidden(key: key)){
                    self.renderView.alpha = 0.25
                    self.label.alpha = 0.4
                    //self.layer.borderColor = UIColor(white: 0.6, alpha: 0.4).cgColor
                    self.layer.borderColor = self.theme.borderColor.cgColor
                }
                // create the adornment overlay (even if hidden, because you need to be able to un-hide)
                self.setupAdornments()
                
            } else {
                log.error("NIL descriptor for key: \(key)")
            }
            
            //TODO: set overlay image based on whether filter is in Quick Select category or not and define touch handlers
            
            self.doLayout()
        })
        
    }
    
    // setup the adornments (favourites, show/hide, ratings etc.) for the current filter
    
    // individual adornments
    fileprivate var showAdornment: UIImageView = UIImageView()
    fileprivate var favAdornment: UIImageView = UIImageView()
    fileprivate var ratingAdornment: UIImageView = UIImageView()
    
    fileprivate func setupAdornments() {
    
        guard (self.descriptor != nil)  else {
            log.error ("NIL descriptor")
            return
        }
        
        adornmentView.frame = self.renderView.frame
        
        // set size of adornments
        let dim: CGFloat = adornmentView.frame.size.height / 8.0

        let adornmentSize = CGSize(width: dim, height: dim)
        
        
        let key = (self.descriptor?.key)!

        // show/hide
        let showAsset: String =  (FilterGalleryViewCell.filterManager.isHidden(key: key) == true) ? "ic_reject" : "ic_accept"
        showAdornment.image = UIImage(named: showAsset)?.imageScaled(to: adornmentSize)
        
        // favourite
        var favAsset: String =  "ic_heart_outline"
        // TODO" figure out how to identify something in the favourite (quick select) list
        if (FilterGalleryViewCell.filterManager.isFavourite(key: key)){
            favAsset = "ic_heart_filled"
        }
        favAdornment.image = UIImage(named: favAsset)?.imageScaled(to: adornmentSize)
        
        // rating
        var ratingAsset: String =  "ic_star"
        switch (FilterGalleryViewCell.filterManager.getRating(key: key)){
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
    
    
    // update the supplied RenderView with the supplied filter
    public func updateRenderView(key: String, renderView:RenderView?){
        
        //var descriptor: FilterDescriptor?
        
        self.descriptor = FilterGalleryViewCell.filterManager.getFilterDescriptor(key: key)
 
        /***
        if (FilterGalleryViewCell.sample == nil){
            loadInputs()
        }
        **/
        
        //TODO: start rendering in an asynch queue
        //TODO: render to UIImage, no need for RenderView since image is static
        
       // guard (FilterGalleryViewCell.sample != nil) else {
       //     log.error("Could not load sample image")
        //    return
        //}



        log.debug("key: \(key) found in cache: \(ImageCache.contains(key: key))")
        //renderView?.setImageSize(InputSource.getSize())
        renderView?.setImageSize(EditManager.getImageSize())
        renderView?.image = ImageCache.get(key: key)


        //DispatchQueue.main.async(execute: { () -> Void in
            //renderView?.image = self.descriptor?.apply(image: FilterGalleryViewCell.sample, image2: FilterGalleryViewCell.blend)
        //})


        //renderView.isHidden = false

 
    }

    open func suspend(){
        //log.debug("Suspending cell: \((filterDescriptor?.key)!)")
        //sample?.removeAllTargets()
        //blend?.removeAllTargets()
        //filter?.removeAllTargets()
        //filterGroup?.removeAllTargets()
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
        guard (self.descriptor != nil) else {
            log.error("NIL descriptor")
            return
        }
        
        if (delegate != nil){
            delegate?.hiddenTouched(key: self.descriptor.key)
        }
    }
    
    // handles touch of the show/hide icon
    @objc func favHandler(){
        //log.verbose("favourite touched")
        guard (self.descriptor != nil) else {
            log.error("NIL descriptor")
            return
        }
        
        if (delegate != nil){
            delegate?.favouriteTouched(key: self.descriptor.key)
        }
    }
    
    // handles touch of the rating icon
    @objc func ratingHandler(){
        //log.verbose("rating touched")
        guard (self.descriptor != nil) else {
            log.error("NIL descriptor")
            return
        }
        
        if (delegate != nil){
            delegate?.ratingTouched(key: self.descriptor.key)
        }
    }

}
