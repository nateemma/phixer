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
}


class FilterGalleryView : UIView, UICollectionViewDataSource, UICollectionViewDelegate{
    
    var isLandscape : Bool = false
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    var itemsPerRow: CGFloat = 3
    var cellSpacing: CGFloat = 2
    var indicatorWidth: CGFloat = 41
    var indicatorHeight: CGFloat = 8
    
    let leftOffset: CGFloat = 11
    let rightOffset: CGFloat = 7
    let height: CGFloat = 34
    
    fileprivate let reuseIdentifier = "FilterGalleryCell"
    //fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    fileprivate let sectionInsets = UIEdgeInsets(top: 11.0, left: 10.0, bottom: 11.0, right: 10.0)
    
    
    fileprivate var filterList:[String] = []
    fileprivate var currCategory: FilterManager.CategoryType = FilterManager.CategoryType.none
    fileprivate var filterManager:FilterManager = FilterManager.sharedInstance
    
    let layout = UICollectionViewFlowLayout()

    fileprivate var filterGallery:UICollectionView? = nil
    fileprivate var firstTime:Bool = true
    
    
    // delegate for handling events
    weak var delegate: FilterGalleryViewDelegate?
  
    
    /////////////////////////////////////
    //MARK: - Initializers
    /////////////////////////////////////
    
    
    
    convenience init(){
        self.init(frame: CGRect.zero)
        doInit()
    }
    
    static var initDone:Bool = false
    static var layoutDone:Bool = false
    
    func doInit(){
        
        if (!FilterGalleryView.initDone){
            FilterGalleryView.initDone = true
            isLandscape = UIDevice.current.orientation.isLandscape

       }
    }
    
    func doLayout(){
        // get display dimensions
        displayHeight = self.frame.size.height
        displayWidth = self.frame.size.width
        
        log.verbose("w:\(displayWidth) h:\(displayHeight)")
        
        // get orientation
        //isLandscape = (displayWidth > displayHeight)
        isLandscape = UIDevice.current.orientation.isLandscape

        
        if (isLandscape){
            itemsPerRow = 4
        } else {
            itemsPerRow = 3
        }
        
        if (layout != nil){
            layout.itemSize = self.frame.size
            log.debug("Gallery layout.itemSize: \(layout.itemSize)")
            filterGallery = UICollectionView(frame: self.frame, collectionViewLayout: layout)
            filterGallery?.delegate   = self
            filterGallery?.dataSource = self
            filterGallery?.register(FilterGalleryViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        } else {
            log.error("UICollectionViewFlowLayout() returned nil")
        }
       
        self.addSubview(filterGallery!)
        filterGallery?.fillSuperview()
        
    }
    
    func doLoadData(){
        //log.verbose("activated")
        
        if (self.filterList.count > 0){
            self.filterList = []
        }
        
        self.filterList = self.filterManager.getFilterList(self.currCategory)!
        self.filterList.sort(by: { (value1: String, value2: String) -> Bool in return value1 < value2 }) // sort ascending
        log.debug ("Loading... \(self.filterList.count) filters for category: \(self.currCategory)")
        
        self.filterGallery?.reloadData()
        //self.filterGallery?.setNeedsDisplay()
    }
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        

        //doLayout() // wait until category is set
        if (isLandscape != UIDevice.current.orientation.isLandscape){ // rotation change?
            isLandscape = !isLandscape
            doLayout()
            doLoadData()
        }
        //self.filterGallery?.reloadData()
        //self.filterGallery?.setNeedsDisplay()
    }
    
    
    open func setCategory(_ category:FilterManager.CategoryType){
        if (currCategory != category){
            currCategory = category
            doLayout()
            doLoadData()
        }
    }
    
    open func suspend(){
        
    }
}

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

// MARK: CollectionViewFlowLayout delegate methods


extension FilterGalleryView : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = self.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
    
    @objc(collectionView:didSelectItemAtIndexPath:)
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? FilterGalleryViewCell else {
            return
        }
        
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        let descr:FilterDescriptorInterface? = (self.filterManager.getFilterDescriptor(key:self.filterList[index]))
        log.verbose("Selected filter: \(self.filterList[index])")
        delegate?.filterSelected(descr!)
    }
    
}



// MARK: - UICollectionViewDataSource
extension FilterGalleryView {
    
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //self.filterList = self.filterManager.getFilterList(self.currCategory)
        //self.filterList.sort(by: { (value1: String, value2: String) -> Bool in return value1 < value2 }) // sort ascending
        //log.debug("Items: \(filterList.count)")
        return filterList.count
    }
    
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    @objc(collectionView:cellForItemAtIndexPath:)
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FilterGalleryViewCell
        if (cell == nil){
            log.debug("Creating new cell")
            cell = FilterGalleryViewCell()
        }
        
        // Configure the cell
        
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        //log.verbose("Index: \(index) (\(self.filterList[index]))")
        if ((index>=0) && (index<filterList.count)){
            //cell.imageContainer =  self.createCell((self.filterManager.getFilterDescriptor(self.currCategory, name:self.filterList[index]))!)
            let descr:FilterDescriptorInterface? = (self.filterManager.getFilterDescriptor(key:self.filterList[index]))
            if (descr != nil){
                //cell.configureCell(descriptor:descr, render:false)
                cell.configureCell(frame: cell.frame, descriptor:descr, render:true)
            } else {
                log.error("NIL descriptor for (\(self.currCategory), \(self.filterList[index]))")
            }
            
        } else {
            log.warning("Index out of range (\(index)/\(filterList.count))")
        }
        //cell.layoutIfNeeded()
        return cell
    }
    
    
    @objc(numberOfSectionsInCollectionView:)
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
}
