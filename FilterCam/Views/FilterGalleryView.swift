//
//  FilterGalleryView.swift
//  FilterCam
//
//  Created by Philip Price on 10/24/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage


// Interface required of controlling View
protocol FilterGalleryViewDelegate: class {
    func filterSelected(_ descriptor:FilterDescriptorInterface?)
    func requestUpdate(category:FilterManager.CategoryType)
}



// this class displays a CollectionView populated with the filters for the specified category
//class FilterGalleryView : UIView, UICollectionViewDataSource, UICollectionViewDelegate{
class FilterGalleryView : UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    
    fileprivate var isLandscape : Bool = false
    fileprivate var screenSize : CGRect = CGRect.zero
    fileprivate var displayWidth : CGFloat = 0.0
    fileprivate var displayHeight : CGFloat = 0.0
    
    fileprivate var itemsPerRow: CGFloat = 3
    fileprivate var cellSpacing: CGFloat = 2
    fileprivate var indicatorWidth: CGFloat = 41
    fileprivate var indicatorHeight: CGFloat = 8
    
    fileprivate let leftOffset: CGFloat = 11
    fileprivate let rightOffset: CGFloat = 7
    fileprivate let height: CGFloat = 34
    
    //fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    fileprivate let sectionInsets = UIEdgeInsets(top: 11.0, left: 10.0, bottom: 11.0, right: 10.0)
    
    
    fileprivate var filterList:[String] = []
    fileprivate var currCategory: FilterManager.CategoryType = FilterManager.CategoryType.imageProcessing
    fileprivate var filterManager:FilterManager = FilterManager.sharedInstance
    
    fileprivate let layout = UICollectionViewFlowLayout()
    
    fileprivate var filterGallery:UICollectionView? = nil
    fileprivate var firstTime:Bool = true
    fileprivate var reuseId:String = "FilterGalleryView"
    
    
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
        if (isLandscape != UIDevice.current.orientation.isLandscape){ // rotation change?
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
            isLandscape = UIDevice.current.orientation.isLandscape
            
        }
    }
    
    fileprivate func doLayout(){
        // get display dimensions
        displayHeight = self.frame.size.height
        displayWidth = self.frame.size.width
        
        log.verbose("w:\(displayWidth) h:\(displayHeight)")
        
        // get orientation
        //isLandscape = (displayWidth > displayHeight)
        isLandscape = UIDevice.current.orientation.isLandscape
        
        
        if (isLandscape){
            itemsPerRow = 5
        } else {
            itemsPerRow = 3
        }
        
        layout.itemSize = self.frame.size
        //log.debug("Gallery layout.itemSize: \(layout.itemSize)")
        filterGallery = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        filterGallery?.delegate   = self
        filterGallery?.dataSource = self
        reuseId = "FilterGalleryView_" + currCategory.rawValue
        filterGallery?.register(FilterGalleryViewCell2.self, forCellWithReuseIdentifier: reuseId)
        
        self.addSubview(filterGallery!)
        filterGallery?.fillSuperview()
        
    }
    
    fileprivate func doLoadData(){
        //log.verbose("activated")
        
        if (self.filterList.count > 0){
            self.filterList = []
        }
        
        // (Re-)build the list of filters
        self.filterList = self.filterManager.getFilterList(self.currCategory)!
        self.filterList.sort(by: { (value1: String, value2: String) -> Bool in return value1 < value2 }) // sort ascending
        log.debug ("Loading... \(self.filterList.count) filters for category: \(self.currCategory)")
 
        
        self.filterGallery?.reloadData()
        //self.filterGallery?.setNeedsDisplay()
    }
    
    open func update(){
        //self.filterGallery?.setNeedsDisplay()
        self.filterGallery?.reloadData()
        //doLoadData()
    }
    
    open func setCategory(_ category:FilterManager.CategoryType){
        if (currCategory == category) { log.warning("Warning: category was already set to: \(category). Check logic") }
        
        //if ((currCategory != category) || firstTime){
            log.debug("Category: \(category.rawValue)")
            currCategory = category
            firstTime = false
            doLayout()
            doLoadData()
        //} else {
        //    log.verbose("Ignoring Category change to: \(category)")
        //}
    }
    
    open func suspend(){
        let indexPath = filterGallery?.indexPathsForVisibleItems
        var cell: FilterGalleryViewCell2?
        if ((indexPath != nil) && (cell != nil)){ // there might not be any filters in the category
            for index in indexPath!{
                cell = filterGallery?.cellForItem(at: index) as! FilterGalleryViewCell2?
                cell?.suspend()
            }
        }
    }
    
    
    
    ////////////////////////////////////////////
    // MARK: - Rendering stuff
    ////////////////////////////////////////////
    
    fileprivate var sampleImageFull:UIImage!
    fileprivate var blendImageFull:UIImage!
    fileprivate var sampleImageSmall:UIImage? = nil
    fileprivate var blendImageSmall:UIImage? = nil
    fileprivate var sample:PictureInput? = nil
    fileprivate var blend:PictureInput? = nil
    
    
    
    fileprivate func loadInputs(){
        /***/
        //log.debug("creating scaled sample and blend images...")
        sampleImageFull = UIImage(named:"sample_emma_01.png")!
        blendImageFull = UIImage(named:"bl_topaz_warm.png")!
        
        // create scaled down versions of the sample and blend images
        //TODO: let user choose image
        let size = sampleImageFull.size.applying(CGAffineTransform(scaleX: 0.2, y: 0.2))
        
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        // downsize input images since we really only need thumbnails
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        sampleImageFull.draw(in: CGRect(origin: CGPoint.zero, size: size))
        sampleImageSmall = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        blendImageFull.draw(in: CGRect(origin: CGPoint.zero, size: size))
        blendImageSmall = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        sample = PictureInput(image:sampleImageSmall!)
        blend  = PictureInput(image:blendImageSmall!)
        /***/
    }
    
    
    
    
    // update the supplied RenderView with the supplied filter
    func updateRenderView(index:Int, key: String, renderView:RenderView){
        
        var descriptor: FilterDescriptorInterface?
        var filter:BasicOperation? = nil
        var filterGroup:OperationGroup? = nil
        
        descriptor = self.filterManager.getFilterDescriptor(key: key)
        
        //log.debug("index:\(index), key:\(key), view:\(Utilities.addressOf(renderView))")
        
        /***
         var sample:PictureInput? = nil // for some reason, need to use local variables
         var blend:PictureInput? = nil
         let sampleImageFull:UIImage = UIImage(named:"sample_emma_01.png")!
         let blendImageFull:UIImage = UIImage(named:"bl_topaz_warm.png")!
         sample = PictureInput(image:sampleImageFull)
         blend  = PictureInput(image:blendImageFull)
         //sample = PictureInput(image:sampleImage)
         //blend  = PictureInput(image:blendImage!)
         var filter:BasicOperation? = nil
         var filterGroup:OperationGroup? = nil
         ***/
        
        if (sample == nil){
            loadInputs()
        } else {
            sample?.removeAllTargets()
            blend?.removeAllTargets()
        }
        
        
        //TODO: start rendering in an asynch queue
        //TODO: render to UIImage, no need for RenderView since image is static
        
        guard (sample != nil) else {
            log.error("Could not load sample image")
            return
        }
        
        guard ((descriptor?.filter != nil) || (descriptor?.filterGroup != nil)) else {
            log.error("Both filter and filterGroup are NIL for filter:\(descriptor?.key)")
            return
        }
        
        
        
        // annoyingly, we have to treat single and multiple filters differently
        if (descriptor?.filter != nil){ // single filter
            filter = descriptor?.filter
            
            //log.debug("Run filter: \((descriptor?.key)!) filter:\(Utilities.addressOf(filter)) view:\(Utilities.addressOf(renderView))")
            
            let opType:FilterOperationType = (descriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                //log.debug("filter: \(descriptor?.key) address:\(Utilities.addressOf(filter))")
                sample! --> filter! --> renderView
                sample?.processImage(synchronously: true)
                break
            case .blend:
                //log.debug("Using BLEND mode for filter: \(descriptor?.key)")
                //TOFIX: blend image needs to be resized to fit the render view
                sample!.addTarget(filter!)
                blend! --> filter!
                sample! --> filter! --> renderView
                blend?.processImage(synchronously: true)
                sample?.processImage(synchronously: true)
                break
            }
            
            filter?.removeAllTargets()
            
        } else if (descriptor?.filterGroup != nil){ // group of filters
            filterGroup = descriptor?.filterGroup
            //log.debug("Run filterGroup: \(descriptor?.key) group:\(Utilities.addressOf(filterGroup)) view:\(Utilities.addressOf(renderView))")
            
            let opType:FilterOperationType = (descriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                //log.debug("filterGroup: \(descriptor?.key)")
                sample! --> filterGroup! --> renderView
                sample?.processImage(synchronously: true)
                break
            case .blend:
                //log.debug("Using BLEND mode for group: \(descriptor?.key)")
                //TOFIX: blend image needs to be resized to fit the render view
                sample!.addTarget(filterGroup!)
                blend! --> filterGroup!
                sample! --> filterGroup! --> renderView
                blend?.processImage(synchronously: true)
                sample?.processImage(synchronously: true)
                break
            }
            
            filterGroup?.removeAllTargets()
            
        } else {
            log.error("ERR!!! shouldn't be here!!!")
        }
        
        
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
        let cell = filterGallery?.dequeueReusableCell(withReuseIdentifier: reuseId, for: indexPath) as! FilterGalleryViewCell2
        
        // configure based on the index
        
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        //log.verbose("Index: \(index) (\(self.filterList[index]))")
        if ((index>=0) && (index<filterList.count)){
            let key = self.filterList[index]
            let renderView = filterManager.getRenderView(key:key)
            renderView?.frame = cell.frame
            self.updateRenderView(index:index, key: key, renderView: renderView!)
            cell.configureCell(frame: cell.frame, index:index, key:key, renderView: renderView!)
            
            //DispatchQueue.main.async(execute: {() -> Void in
            //    UIView.performWithoutAnimation {
            //        self.filterGallery?.reloadItems(at: [indexPath])
            //    }
            //})
            //cell.layoutIfNeeded()
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
        
        guard (filterGallery?.cellForItem(at: indexPath) as? FilterGalleryViewCell2) != nil else {
            log.error("NIL cell")
            return
        }
        
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        let descr:FilterDescriptorInterface? = (self.filterManager.getFilterDescriptor(key:self.filterList[index]))
        log.verbose("Selected filter: \((descr?.key)!)")
        
        // suspend all active rendering and launch viewer for this filter
        filterManager.setSelectedFilter(key: (descr?.key)!)
        suspend()
        //self.present(FilterDetailsViewController(), animated: true, completion: nil)
        delegate?.filterSelected(descr!)
    }
    
}




////////////////////////////////////////////
// MARK: - UICollectionViewFlowLayout
////////////////////////////////////////////

extension FilterGalleryView {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = self.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        //log.debug("ItemSize: \(widthPerItem)")
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

