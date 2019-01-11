//
//  FilterGalleryView.swift
//  phixer
//
//  Created by Philip Price on 10/24/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import CoreImage
import Cosmos


// Interface required of controlling View
protocol FilterGalleryViewDelegate: class {
    func filterSelected(_ descriptor:FilterDescriptor?)
    func requestUpdate(category:String)
    func setHidden(key:String, hidden:Bool)
    func setFavourite(key:String, fav:Bool)
    func setRating(key:String, rating:Int)
}



// this class displays a CollectionView populated with the filters for the specified category
//class FilterGalleryView : UIView, UICollectionViewDataSource, UICollectionViewDelegate{
class FilterGalleryView : UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, FilterGalleryViewCellDelegate {
    
    var theme = ThemeManager.currentTheme()
    

    public static var showHidden:Bool = false // controls whether hidden filters are shown or not
    
    var isLandscape : Bool = false // moved to base class
    fileprivate var screenSize : CGRect = CGRect.zero
    fileprivate var displayWidth : CGFloat = 0.0
    fileprivate var displayHeight : CGFloat = 0.0
    
    fileprivate var aspectRatio : CGFloat = 1.0
    
    fileprivate var itemsPerRow: CGFloat = 3
    fileprivate var cellSpacing: CGFloat = 2
    fileprivate var indicatorWidth: CGFloat = 41
    fileprivate var indicatorHeight: CGFloat = 8
    
    fileprivate let leftOffset: CGFloat = 11
    fileprivate let rightOffset: CGFloat = 7
    fileprivate let height: CGFloat = 34
    
    //fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    //fileprivate let sectionInsets = UIEdgeInsets(top: 9.0, left: 10.0, bottom: 9.0, right: 10.0)
    fileprivate let sectionInsets = UIEdgeInsets(top: 4.0, left: 4.0, bottom: 4.0, right: 4.0) // layout is *really* sensitive to left/right for some reason
    
    
    fileprivate var filterList:[String] = []
    fileprivate var currCategory: String = FilterManager.defaultCategory
    fileprivate var filterManager:FilterManager = FilterManager.sharedInstance
    fileprivate var selectedIndex:Int = -1
    
    fileprivate let layout = UICollectionViewFlowLayout()
    
    fileprivate var filterGallery:UICollectionView? = nil
    fileprivate var firstTime:Bool = true
    fileprivate var reuseId:String = "FilterGalleryView"
    //fileprivate var opacityFilter:OpacityAdjustment? = nil
    
    
    // delegate for handling events
    weak var delegate: FilterGalleryViewDelegate?
    
    
    /////////////////////////////////////
    //MARK: - Initializers
    /////////////////////////////////////
    
    
    
    convenience init(){
        self.init(frame: CGRect.zero)
        doInit()
    }
    
    
    deinit{
        suspend()
    }
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
        // only do layout if this was caused by an orientation change
        if (isLandscape != ((UIApplication.shared.statusBarOrientation == .landscapeLeft) || (UIApplication.shared.statusBarOrientation == .landscapeRight))){ // rotation change?
            isLandscape = !isLandscape
            doLayout()
            doLoadData()
        }
    }

    
    
    
    fileprivate static var initDone:Bool = false
    fileprivate static var layoutDone:Bool = false
    
    fileprivate func doInit(){
        
        if (!FilterGalleryView.initDone){
            FilterGalleryView.initDone = true
            isLandscape = ((UIApplication.shared.statusBarOrientation == .landscapeLeft) || (UIApplication.shared.statusBarOrientation == .landscapeRight))
            
        }
    }
    
    fileprivate func doLayout(){
        // get display dimensions
        displayHeight = self.frame.size.height
        displayWidth = self.frame.size.width
        
        log.verbose("w:\(displayWidth) h:\(displayHeight)")
        
        // get orientation
        //isLandscape = (displayWidth > displayHeight)
        isLandscape = ((UIApplication.shared.statusBarOrientation == .landscapeLeft) || (UIApplication.shared.statusBarOrientation == .landscapeRight))
        
        // get aspect ratio of input (used for layout sizing)
        
        //aspectRatio = ImageManager.getSampleImageAspectRatio()
        aspectRatio = InputSource.getAspectRatio()

        selectedIndex = -1

        // set items per row. Add 1 if landscape, subtract one if sample is in landscape orientation
        
        if (isLandscape){
            if (aspectRatio > 1.0){ // w > h
                itemsPerRow = 4
            } else {
                itemsPerRow = 5
            }
        } else {
            if (aspectRatio > 1.0){ // w > h
                itemsPerRow = 2
            } else {
                itemsPerRow = 3
            }
        }
        
        layout.itemSize = self.frame.size
        //log.debug("Gallery layout.itemSize: \(layout.itemSize)")
        filterGallery = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        filterGallery?.delegate   = self
        filterGallery?.dataSource = self
        reuseId = "FilterGalleryView_" + currCategory
        filterGallery?.register(FilterGalleryViewCell.self, forCellWithReuseIdentifier: reuseId)
        
        self.addSubview(filterGallery!)
        filterGallery?.fillSuperview()
        
    }
    
    fileprivate func doLoadData(){
        //log.verbose("activated")
        //ignore compiler warnings
        var filter:FilterDescriptor? = nil
        var renderview:MetalImageView? = nil
        
        if (self.filterList.count > 0){
            self.filterList = []
        }
        
        // (Re-)build the list of filters
        if FilterGalleryView.showHidden {
            self.filterList = self.filterManager.getFilterList(self.currCategory)!
        } else {
            // only add filters if they are not hidden

            //if let list = self.filterManager.getShownFilterList(self.currCategory) {
            if let list = (FilterGalleryView.showHidden==true) ? self.filterManager.getFilterList(self.currCategory) : self.filterManager.getShownFilterList(self.currCategory) {
                if list.count > 0 {
                    for k in list {
                        if ((filterManager.getFilterDescriptor(key: k)?.show)!) || FilterGalleryView.showHidden {
                            self.filterList.append(k)
                        }
                    }
                }
            }
        }
        self.filterList.sort(by: { (value1: String, value2: String) -> Bool in return value1 < value2 }) // sort ascending
        log.debug ("Loading... \(self.filterList.count) filters for category: \(self.currCategory)")
        
        // pre-load filters. Inefficient, but it avoids multi-thread timing issues when rendering cells
        // ignore compiler warnings, the intent is to pre-load the filters
        if (self.filterList.count > 0){
            for key in self.filterList{
                filter = filterManager.getFilterDescriptor(key: key)
                renderview = filterManager.getRenderView(key: key)
            }
        }
 
        
        self.filterGallery?.reloadData()
        //self.filterGallery?.setNeedsDisplay()
    }
    
    ////////////////////////////////////////////
    // MARK: - Accessors
    ////////////////////////////////////////////

    open func update(){
        //self.filterGallery?.setNeedsDisplay()
        self.filterGallery?.reloadData()
        //doLoadData()
    }
    
    open func setCategory(_ category:String){
        if (currCategory == category) { log.warning("Warning: category was already set to: \(category). Check logic") }
        
        //if ((currCategory != category) || firstTime){
            log.debug("Category: \(category)")
            currCategory = category
            firstTime = false
            doLayout()
            doLoadData()
        //} else {
        //    log.verbose("Ignoring Category change to: \(category)")
        //}
    }
    
    // Suspend all MetalPetal-related operations
    open func suspend(){
        /***
        let indexPath = filterGallery?.indexPathsForVisibleItems
        var cell: FilterGalleryViewCell?
        if ((indexPath != nil) && (cell != nil)){ // there might not be any filters in the category
            for index in indexPath!{
                cell = filterGallery?.cellForItem(at: index) as! FilterGalleryViewCell?
                cell?.suspend()
            }
        }
        ***/
        
        //var descriptor:FilterDescriptor? = nil
        for key in filterList {
            filterManager.releaseFilterDescriptor(key: key)
            filterManager.releaseRenderView(key: key)
        }
    }
    
    
    // get the next filter after the specified key
    func getFilterAfter(key: String)->String {
        var newkey:String = ""
        let kIndex = indexForKey(key)
        if (kIndex >= 0) && (kIndex < self.filterList.count){
            let index = (kIndex < (filterList.count-1)) ? (kIndex + 1) : 0
            newkey = self.filterList[index]
        } else {
            newkey = self.filterList[0]
        }
        return newkey
    }
    
    // get the filter before the specified key
    func getFilterBefore(key: String)->String {
        var newkey:String = ""
        let kIndex = indexForKey(key)
        if (kIndex >= 0) && (kIndex < self.filterList.count){
            let index = (kIndex > 0) ? (kIndex - 1) : (filterList.count - 1)
            newkey = self.filterList[index]
        } else {
            newkey = self.filterList[0]
        }
        return newkey
    }

    ////////////////////////////////////////////
    // MARK: - Rating Alert (for showing rating and allowing change)
    ////////////////////////////////////////////
    
    fileprivate var ratingAlert:UIAlertController? = nil
    fileprivate var currRating: Int = 0
    fileprivate var currRatingKey: String = ""
    fileprivate static var starView: CosmosView? = nil
    
    fileprivate func displayRating(){
        
        
        // build the rating stars display based on the current rating
        // I'm using the 'Cosmos' class to do this
        if (FilterGalleryView.starView == nil){
            FilterGalleryView.starView = CosmosView()
            
            FilterGalleryView.starView?.settings.fillMode = .full // Show only fully filled stars
            //starView?.settings.starSize = 30
            FilterGalleryView.starView?.settings.starSize = Double(self.frame.size.width / 16.0) - 2.0
            //starView?.settings.starMargin = 5
            
            // Set the colours
            FilterGalleryView.starView?.settings.totalStars = 3
            FilterGalleryView.starView?.backgroundColor = UIColor.clear
            FilterGalleryView.starView?.settings.filledColor = UIColor.flatYellow
            FilterGalleryView.starView?.settings.emptyBorderColor = UIColor.flatGrayDark
            FilterGalleryView.starView?.settings.filledBorderColor = UIColor.flatBlack
            
            FilterGalleryView.starView?.didFinishTouchingCosmos = { rating in
                self.currRating = Int(rating)
                FilterGalleryView.starView?.anchorInCenter(width: self.frame.size.width / 4.0, height: self.frame.size.width / 16.0)
            }
        }
        FilterGalleryView.starView?.rating = Double(currRating)
        
        // igf not already done, build the alert
        if (ratingAlert == nil){
            // setup the basic info
            ratingAlert = UIAlertController(title: "Rating", message: " ", preferredStyle: .alert)
            
            // add the OK button
            let okAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                self.filterManager.setRating(key: self.currRatingKey, rating: self.currRating)
                log.debug("OK")
            }
            ratingAlert?.addAction(okAction)
            
            // add the Cancel Button
            let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action:UIAlertAction) in
                log.debug("Cancel")
            }
            ratingAlert?.addAction(cancelAction)
            
            
            // add the star rating view
            ratingAlert?.view.addSubview(FilterGalleryView.starView!)
        }
        
        FilterGalleryView.starView?.anchorInCenter(width: self.frame.size.width / 4.0, height: self.frame.size.width / 16.0)
        
        // launch the Alert. Need to get the Controller to do this though, since we are calling from a View
        DispatchQueue.main.async(execute: { () -> Void in
            let ctlr = self.getCurrentViewController()
            ctlr?.present(self.ratingAlert!, animated: true, completion:nil)
        })
    }
    
    func getCurrentViewController() -> UIViewController? {
        
        if let rootController = UIApplication.shared.keyWindow?.rootViewController {
            var currentController: UIViewController! = rootController
            while( currentController.presentedViewController != nil ) {
                currentController = currentController.presentedViewController
            }
            return currentController
        }
        return nil
        
    }
    
    ////////////////////////////////////////////
    // MARK: - Rendering stuff
    ////////////////////////////////////////////
    
    /***
    fileprivate var sampleImageFull:UIImage!
    fileprivate var blendImageFull:UIImage!
    fileprivate var sampleImageSmall:UIImage? = nil
    fileprivate var blendImageSmall:UIImage? = nil
    ***/
    fileprivate var sample:CIImage? = nil
    fileprivate var blend:CIImage? = nil
    
    
    
    fileprivate func loadInputs(size:CGSize){
        //sample = ImageManager.getCurrentSampleImage()
        //sample = ImageManager.getCurrentSampleImage(size:size)
        sample = InputSource.getCurrentImage(size: size)
        blend  = ImageManager.getCurrentBlendImage(size:size)
    }
    
    
    
    
    // update the supplied MetalImageView with the supplied filter
    func updateRenderView(index:Int, key: String, renderview:MetalImageView?){
        
        var descriptor: FilterDescriptor?
        
        descriptor = self.filterManager.getFilterDescriptor(key: key)
        
        
        guard (descriptor != nil)  else {
            log.error("filter NIL for:index:\(index) key:\(String(describing: descriptor?.key))")
            return
        }
        //log.debug("index:\(index), key:\(key), view:\(Utilities.addressOf(MetalImageView))")
        
        
        //if (sample == nil){
        loadInputs(size:(renderview?.frame.size)!)
        //}
        
        
        //TODO: start rendering in an asynch queue
        
        guard (sample != nil) else {
            log.error("Could not load sample image")
            return
        }
        
        if (blend == nil) && (descriptor?.filterOperationType == FilterOperationType.blend) {
            log.error("Could not load blend image")
            return
        }

        // run the filter
        renderview?.image = descriptor?.apply(image:sample, image2: blend)
        renderview?.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: self.height * 0.8)

        //renderView?.isHidden = false
 
    }
    
    
    
}



////////////////////////////////////////////
// MARK: - Extensions
////////////////////////////////////////////



// MARK: - Private
private extension FilterGalleryView {
    func keyForIndexPath(_ indexPath: IndexPath) -> String {
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        if ((index>=0) && (index<filterList.count)){
            return filterList[index]
        } else {
            log.error("Index:\(index) out of range (0..\(filterList.count))")
            return ""
        }
    }
    
    func indexForKey(_ key:String) -> Int{
        if let index = filterList.index(of: key) {
            return index
        } else {
            return 0
        }
    }
}




////////////////////////////////////////////
// MARK: - UIAlertController
////////////////////////////////////////////

// why do we have to do this?! when AlertController is set up, re-position the stars
extension UIAlertController {
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // TODO: figure out sizes
        FilterGalleryView.starView?.anchorInCenter(width: 128, height: 32)
    }
}

////////////////////////////////////////////
// MARK: - UICollectionViewDataSource
////////////////////////////////////////////

extension FilterGalleryView {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filterList.count
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // dequeue the cell
        let cell = filterGallery?.dequeueReusableCell(withReuseIdentifier: reuseId, for: indexPath) as! FilterGalleryViewCell
        
        // configure based on the index
        
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        if ((index>=0) && (index<filterList.count)){
            DispatchQueue.main.async(execute: { () -> Void in
                log.verbose("Index: \(index) key:(\(self.filterList[index]))")
                let key = self.filterList[index]
                let renderview = self.filterManager.getRenderView(key:key)
                renderview?.frame = cell.frame
                //renderview?.contentMode = .scaleAspectFit
                //renderview?.clipsToBounds = true
                //renderview?.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: self.height * 0.8)
                self.updateRenderView(index:index, key: key, renderview: renderview) // doesn't seem to work if we put this into the FilterGalleryViewCell logic (threading?!)
                cell.delegate = self
                cell.configureCell(frame: cell.frame, index:index, key:key)
            })
            
        } else {
            log.warning("Index out of range (\(index)/\(filterList.count))")
        }
        return cell
    }
    
}





////////////////////////////////////////////
// MARK: - UICollectionViewDelegate
////////////////////////////////////////////

extension FilterGalleryView {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard (filterGallery?.cellForItem(at: indexPath) as? FilterGalleryViewCell) != nil else {
            log.error("NIL cell")
            return
        }
        
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        selectedIndex = index
        let descr:FilterDescriptor? = (self.filterManager.getFilterDescriptor(key:self.filterList[index]))
        log.verbose("Selected filter: \((descr?.key)!)")
        
        // suspend all active rendering and launch viewer for this filter
        filterManager.setSelectedCategory(currCategory)
        filterManager.setSelectedFilter(key: (descr?.key)!)
        //suspend()
        //self.present(FilterDetailsViewController(), animated: true, completion: nil)
        delegate?.filterSelected(descr!)
    }
    
}




////////////////////////////////////////////
// MARK: - FilterGalleryViewCell
////////////////////////////////////////////
extension FilterGalleryView {
    
    // handle touch of show/hide icon in cell
    func hiddenTouched(key:String){
        log.verbose("key: \(key)")
        let hidden =  (self.filterManager.isHidden(key: key)) ? false : true
        self.filterManager.setHidden(key: key, hidden: hidden)
        self.update()
    }
    
    // handle touch of favourite icon in cell
    func favouriteTouched(key:String){
        log.verbose("key: \(key)")
        //TODO: confirmation dialog?
        if (self.filterManager.isFavourite(key: key)){
            log.verbose ("Removing from Favourites: \(key)")
            self.filterManager.removeFromFavourites(key: key)
        } else {
            log.verbose ("Adding to Favourites: \(key)")
            self.filterManager.addToFavourites(key: key)
        }
        self.update()
    }
    
    // handle touch of rating icon in cell
    func ratingTouched(key:String){
        log.verbose("key: \(key)")
        currRating = self.filterManager.getRating(key: key)
        currRatingKey = key
        displayRating()
    }

}

////////////////////////////////////////////
// MARK: - UICollectionViewFlowLayout
////////////////////////////////////////////

extension FilterGalleryView {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        //let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        //let paddingSpace = sectionInsets.left * (itemsPerRow + 2)
        let paddingSpace = (sectionInsets.left * (itemsPerRow+1)) + (sectionInsets.right * (itemsPerRow+1)) + 2.0
        let availableWidth = self.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        //log.debug("view:\(availableWidth) cell: \(widthPerItem)")
        //return CGSize(width: widthPerItem, height: widthPerItem*1.5) // use 2:3 (4:6) ratio
        return CGSize(width: widthPerItem, height: widthPerItem/aspectRatio) // use same aspect ratio as sample image
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

