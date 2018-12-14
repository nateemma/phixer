//
//  StyleTransferGalleryView.swift
//  phixer
//
//  Created by Philip Price on 10/24/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import CoreImage
import Cosmos


// Interface required of controlling View
protocol StyleTransferGalleryViewDelegate: class {
    func filterSelected(_ descriptor:FilterDescriptor?)
}



// this class displays a CollectionView populated with the filters for the specified category
//class StyleTransferGalleryView : UIView, UICollectionViewDataSource, UICollectionViewDelegate{
class StyleTransferGalleryView : UIView {
    
    var theme = ThemeManager.currentTheme()
    

    public static var showHidden:Bool = false // controls whether hidden filters are shown or not
    
    private static let styleCategory = "style"
    
    fileprivate var isLandscape : Bool = false
    fileprivate var screenSize : CGRect = CGRect.zero
    fileprivate var displayWidth : CGFloat = 0.0
    fileprivate var displayHeight : CGFloat = 0.0
    
    fileprivate var aspectRatio : CGFloat = 1.0
    
    fileprivate var itemsPerRow: CGFloat = 1
    fileprivate var cellSpacing: CGFloat = 1
    
    fileprivate let leftOffset: CGFloat = 11
    fileprivate let rightOffset: CGFloat = 7
    fileprivate let height: CGFloat = 34
    fileprivate let rowHeight: CGFloat = 96
    
    fileprivate var rowSize:CGSize = CGSize.zero
    fileprivate var imgSize:CGSize = CGSize.zero


    //fileprivate let sectionInsets = UIEdgeInsets(top: 4.0, left: 4.0, bottom: 4.0, right: 4.0) // layout is *really* sensitive to left/right for some reason
    fileprivate let sectionInsets = UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0) // layout is *really* sensitive to left/right for some reason

    
    fileprivate var filterList:[String] = []
    fileprivate var arrowView:UIImageView? = nil
    fileprivate var sourceImageList:[String:UIImage?] = [:]
    fileprivate var styledImageList:[String:MetalImageView] = [:]

    fileprivate var currCategory: String = FilterManager.defaultCategory
    fileprivate var filterManager:FilterManager = FilterManager.sharedInstance
    
    fileprivate let layout = UICollectionViewFlowLayout()
    
    fileprivate var styleTransfer:UICollectionView? = nil
    fileprivate var firstTime:Bool = true
    fileprivate var reuseId:String = "StyleTransferGalleryView"
    //fileprivate var opacityFilter:OpacityAdjustment? = nil
    
    
    // delegate for handling events
    weak var delegate: StyleTransferGalleryViewDelegate?
    
    
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
        
        StyleTransferGalleryViewCell.reset()
        doLayout()
        doLoadData()
    }

    
    
    
    fileprivate static var initDone:Bool = false
    fileprivate static var layoutDone:Bool = false
    
    fileprivate func doInit(){
        
        if (!StyleTransferGalleryView.initDone){
            StyleTransferGalleryView.initDone = true
            isLandscape = UIDevice.current.orientation.isLandscape
            filterList = []
            sourceImageList = [:]
            styledImageList = [:]

            // arrow view
            if self.arrowView == nil {
                self.arrowView = UIImageView()
                self.arrowView?.image = UIImage(named:"ic_right_arrow")?.withRenderingMode(.alwaysTemplate)
                self.arrowView?.tintColor =  self.theme.tintColor
                self.arrowView?.alpha = 0.8
            }

        }
    }
    
    fileprivate func doLayout(){
        // get display dimensions
        displayHeight = self.frame.size.height
        displayWidth = self.frame.size.width
        
        rowSize = CGSize(width: displayWidth, height: rowHeight)
        imgSize = CGSize(width: displayWidth/4.0, height: rowHeight*0.9)

        log.verbose("w:\(displayWidth) h:\(displayHeight)")
        
        // get orientation
        //isLandscape = (displayWidth > displayHeight)
        isLandscape = UIDevice.current.orientation.isLandscape
        
        itemsPerRow = 1

        layout.itemSize = self.frame.size
        //log.debug("Gallery layout.itemSize: \(layout.itemSize)")
        styleTransfer = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        styleTransfer?.delegate   = self
        styleTransfer?.dataSource = self
        reuseId = "StyleTransferGalleryView"
        styleTransfer?.register(StyleTransferGalleryViewCell.self, forCellWithReuseIdentifier: reuseId)
        
        self.addSubview(styleTransfer!)
        styleTransfer?.fillSuperview()
        
    }
    
    fileprivate func doLoadData(){
        
        loadInputs(size: imgSize)
        
        if (self.filterList.count > 0){
            self.filterList = []
            self.sourceImageList = [:]
            styledImageList = [:]
       }
        
        // (Re-)build the list of filters

        // only add filters if they are not hidden
        
        //if let list = self.filterManager.getShownFilterList(self.currCategory) {
        if let list = (FilterGalleryView.showHidden==true) ? self.filterManager.getFilterList(StyleTransferGalleryView.styleCategory)
                                                                  : self.filterManager.getShownFilterList(StyleTransferGalleryView.styleCategory) {
            if list.count > 0 {
                for k in list {
                    if ((filterManager.getFilterDescriptor(key: k)?.show)!) || StyleTransferGalleryView.showHidden {
                        self.filterList.append(k)
                    }
                }
            }
        }

        self.filterList.sort(by: { (value1: String, value2: String) -> Bool in return value1 < value2 }) // sort ascending
        log.debug ("Loading... \(self.filterList.count) filters for category: \(self.currCategory)")
        
        loadFilteredData()
    }
    
    open func reset(){
        DispatchQueue.main.async(execute: { () -> Void in
            log.verbose("Resetting...")
            self.sample = InputSource.getCurrentImage()?.resize(size: self.imgSize)
            self.renderStyledImages()
            StyleTransferGalleryViewCell.reset()
            self.styleTransfer?.reloadData()
            //doLoadData()
        })
   }
    open func update(){
        //self.styleTransfer?.setNeedsDisplay()
        log.verbose("update requested")
        self.sample = InputSource.getCurrentImage()?.resize(size: self.imgSize)
        self.renderStyledImages()
        self.styleTransfer?.reloadData()
        //doLoadData()
    }
    
    
    // Suspend all Metal-related operations
    open func suspend(){
        
        //var descriptor:FilterDescriptor? = nil
        for key in filterList {
            filterManager.releaseFilterDescriptor(key: key)
            filterManager.releaseRenderView(key: key)
        }
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
 
    
    // load arrays with the data needed to populate displays. The intent is to avoid loading data every time the UI is updated
    fileprivate func  loadFilteredData() {
        
        //log.verbose("activated")
        //ignore compiler warnings
        
        loadInputs(size: imgSize)
        
        //DispatchQueue.main.async(execute: { () -> Void in
            var filter:FilterDescriptor? = nil
            var renderview:MetalImageView? = nil
 
            // loop through the list of filters and load the source image and init the styled image to the current input
            if (self.filterList.count > 0){
                log.debug("Pre-loading cell data...")
                for key in self.filterList{
                    // source image
                    filter = self.filterManager.getFilterDescriptor(key: key)
                    self.sourceImageList[key] = filter?.getSourceImage()
                    
                    // styled image
                    //renderview = self.filterManager.getRenderView(key: key)
                    renderview = MetalImageView()
                    renderview?.frame.size = self.imgSize
                    renderview?.image = self.sample
                    self.styledImageList[key] = renderview
                }
            }
        //})
        self.renderStyledImages()
    }

    ////////////////////////////////////////////
    // MARK: - Rendering stuff
    ////////////////////////////////////////////
    
    fileprivate var sample:CIImage? = nil
    
    
    
    fileprivate func loadInputs(size:CGSize){
        //sample = ImageManager.getCurrentSampleImage()
        if sample == nil {
            //sample = ImageManager.getCurrentSampleImage(size:size)
            sample = InputSource.getCurrentImage()?.resize(size: size)
       }
    }
    
    
    // apply the style associated with 'key'
    func getStyledImage(key:String) -> CIImage? {
        var descriptor: FilterDescriptor?
        
        descriptor = self.filterManager.getFilterDescriptor(key: key)
        
        
        guard (descriptor != nil)  else {
            log.error("filter NIL for key:\(String(describing: descriptor?.key))")
            return nil
        }
        
        loadInputs(size:imgSize)
        guard (sample != nil) else {
            log.error("Could not load sample image")
            return nil
        }
        

        // run the filter
        return descriptor?.apply(image:sample)

    }
    
    // apply styles for all filters in the list
    func renderStyledImages(){
        //DispatchQueue.main.async(execute: { () -> Void in
        DispatchQueue.global(qos: .background).async {
            
            // loop through the list of filters again and load the styled images
            var renderview:MetalImageView? = nil
            if (self.filterList.count > 0){
                log.debug("Loading styled data...")
                for key in self.filterList{
                    
                    // styled image
                    renderview =  self.styledImageList[key]!
                    renderview?.image = self.getStyledImage(key:key)
                }
            }
            
            // schedule an update of the collection view
            DispatchQueue.main.async(execute: { () -> Void in
                self.styleTransfer?.reloadData()
            })
            //self.styleTransfer?.setNeedsDisplay()
        }
        //})
    }
}



////////////////////////////////////////////
// MARK: - Extensions
////////////////////////////////////////////



// MARK: - Private
private extension StyleTransferGalleryView {
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

extension StyleTransferGalleryView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filterList.count
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // dequeue the cell
        let cell = styleTransfer?.dequeueReusableCell(withReuseIdentifier: reuseId, for: indexPath) as! StyleTransferGalleryViewCell
        
        // configure based on the index
        
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        if ((index>=0) && (index<filterList.count)){
            DispatchQueue.main.async(execute: { () -> Void in
                cell.frame.size.width = self.displayWidth
                cell.frame.size.height = self.rowHeight
                //log.verbose("Index: \(index) key:(\(self.filterList[index]))")
                let key = self.filterList[index]
                //let renderview = self.filterManager.getRenderView(key:key)
                //renderview?.frame.size.width = cell.frame.size.width / 4.0
                //renderview?.frame.size.height = cell.frame.size.height * 0.9
                //self.updateRenderView(index:index, key: key, renderview: renderview) // doesn't seem to work if we put this into the StyleTransferGalleryViewCell logic (threading?!)
                
                //cell.setStyledImage(index:index, key: key, image:self.getStyledImage(key:key))
                //cell.configure(index: index, srcImage: (self.sourceImageList[key])!,  styledImage: self.filterManager.getRenderView(key: key))
                let renderview =  self.styledImageList[key]
                renderview?.frame.size = self.imgSize // can change

                cell.configure(index: index, srcImage: (self.sourceImageList[key])!,  styledImage:renderview!)
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

extension StyleTransferGalleryView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard (styleTransfer?.cellForItem(at: indexPath) as? StyleTransferGalleryViewCell) != nil else {
            log.error("NIL cell")
            return
        }
        
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        let descr:FilterDescriptor? = (self.filterManager.getFilterDescriptor(key:self.filterList[index]))
        log.verbose("Selected filter: \((descr?.key)!)")
        
        // suspend all active rendering and launch viewer for this filter
        filterManager.setSelectedCategory(StyleTransferGalleryView.styleCategory)
        filterManager.setSelectedFilter(key: (descr?.key)!)
        //suspend()
        //self.present(FilterDetailsViewController(), animated: true, completion: nil)
        delegate?.filterSelected(descr!)
    }
    
}





////////////////////////////////////////////
// MARK: - UICollectionViewFlowLayout
////////////////////////////////////////////

extension StyleTransferGalleryView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        //let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        //let paddingSpace = sectionInsets.left * (itemsPerRow + 2)
        let paddingSpace = (sectionInsets.left * (itemsPerRow+1)) + (sectionInsets.right * (itemsPerRow+1)) + 2.0
        let availableWidth = self.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        //log.debug("view:\(availableWidth) cell: w:\(widthPerItem) h:\(rowHeight) insets:\(sectionInsets)")
        //return CGSize(width: widthPerItem, height: widthPerItem*1.5) // use 2:3 (4:6) ratio
        return CGSize(width: widthPerItem, height: rowHeight)
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

