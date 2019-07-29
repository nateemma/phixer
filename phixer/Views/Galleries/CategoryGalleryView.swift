//
//  CategoryGalleryView.swift
//  phixer
//
//  Created by Philip Price on 07/25/19
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import CoreImage
import Cosmos


// Interface required of controlling View
protocol CategoryGalleryViewDelegate: class {
    func categorySelected(category:String)
    func filterSelected(category:String, key:String)
}



// this class displays a CollectionView populated with the filters for the specified category
//class CategoryGalleryView : UIView, UICollectionViewDataSource, UICollectionViewDelegate{
class CategoryGalleryView : UIView, UICollectionViewDataSource {
    
    var theme = ThemeManager.currentTheme()
    

    public static var showHidden:Bool = false // controls whether hidden filters are shown or not
    
    fileprivate var displayWidth : CGFloat = 0.0
    fileprivate var displayHeight : CGFloat = 0.0
    
    fileprivate var aspectRatio : CGFloat = 1.0
    
    fileprivate var itemsPerRow: CGFloat = 3
    fileprivate var cellSpacing: CGFloat = 2
    fileprivate var cellSize: CGSize = CGSize.zero
    fileprivate var indicatorWidth: CGFloat = 41
    fileprivate var indicatorHeight: CGFloat = 8
    fileprivate var imgViewSize: CGSize = CGSize.zero

    fileprivate let leftOffset: CGFloat = 11
    fileprivate let rightOffset: CGFloat = 7
    fileprivate let height: CGFloat = 34
    
    fileprivate let sectionInsets = UIEdgeInsets(top: 2.0, left: 3.0, bottom: 2.0, right: 3.0) // layout is *really* sensitive to left/right for some reason

    
    fileprivate var categoryList:[String] = []
    fileprivate var currCollection: String = ""
    fileprivate var filterManager:FilterManager = FilterManager.sharedInstance
    fileprivate var selectedIndex:Int = -1
    
    fileprivate let layout = UICollectionViewFlowLayout()
    
    fileprivate var categoryGallery:UICollectionView? = nil
    fileprivate var firstTime:Bool = true
    fileprivate var reuseId:String = "CategoryGalleryView"
    //fileprivate var opacityFilter:OpacityAdjustment? = nil
    
    
    // delegate for handling events
    weak var delegate: CategoryGalleryViewDelegate?
    
    
    /////////////////////////////////////
    //MARK: - Initializers
    /////////////////////////////////////
    
    
    
    convenience init(){
        self.init(frame: CGRect(origin: CGPoint.zero, size: UISettings.screenSize))
       // self.init(frame: CGRect.zero)
    }
    
    
    deinit{
        //suspend()
        releaseResources()
        categoryList = []
        categoryGallery = nil
   }
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // only do layout if this was caused by an orientation change
        if (UISettings.isLandscape != ((UIApplication.shared.statusBarOrientation == .landscapeLeft) || (UIApplication.shared.statusBarOrientation == .landscapeRight))){ // rotation change?
            doLayout()
         }
    }

    
    
    fileprivate  var layoutDone:Bool = false
    
    
    fileprivate func doLayout(){
        
        self.layoutDone = true
        
        if currCollection.isEmpty {
            currCollection = filterManager.getCurrentCollection()
        }
        categoryList = filterManager.getCategoryList(collection: currCollection)
        
        // get display dimensions
        displayHeight = self.frame.size.height
        displayWidth = self.frame.size.width
        
        log.verbose("w:\(displayWidth) h:\(displayHeight)")
        
        selectedIndex = -1

        // always 1 item per row
        itemsPerRow = 1
        
        // calculate the sizes for the input image and displayed view
        
        let paddingSpace = (sectionInsets.left * (itemsPerRow+1)) + (sectionInsets.right * (itemsPerRow+1)) + 2.0
        let availableWidth = self.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        cellSize = CGSize(width: widthPerItem, height: (UISettings.panelHeight*2.0).rounded())

        // set up the gallery/collection view
        
        layout.itemSize = self.frame.size
        
        //log.debug("Gallery layout.itemSize: \(layout.itemSize)")
        categoryGallery = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        categoryGallery?.isPrefetchingEnabled = true
        categoryGallery?.delegate   = self
        categoryGallery?.dataSource = self
        reuseId = "CategoryGalleryView_" + currCollection
        categoryGallery?.register(CategoryGalleryViewCell.self, forCellWithReuseIdentifier: reuseId)
        
        self.addSubview(categoryGallery!)
        categoryGallery?.fillSuperview()
        
    }
  
    ////////////////////////////////////////////
    // MARK: - Accessors
    ////////////////////////////////////////////

    open func update(){
        //self.categoryGallery?.setNeedsDisplay()
        self.categoryGallery?.reloadData()
        //doLoadData()
    }
    
    open func setCollection(_ collection:String){
        if (currCollection == collection) {
            log.warning("Warning: collection was already set to: \(collection). Check logic")
        }
        
        log.debug("Collection: \(collection)")
        currCollection = collection
        firstTime = false
        doLayout()
    }
    
    // Suspend all MetalPetal-related operations
    open func suspend(){

    }
    
    
    
    // releaes the resources that we used for the gallery items
    
    private func releaseResources(){
        if (self.categoryList.count > 0){
            for c in categoryList {
                let flist = filterManager.getFilterList(c)
                if (flist!.count > 0){
                    for key in flist! {
                        ImageCache.remove(key: key)
                        RenderViewCache.remove(key: key)
                        FilterDescriptorCache.remove(key: key)
                    }
                }
            }
        }
    }
    
    
}



////////////////////////////////////////////
// MARK: - Extensions
////////////////////////////////////////////



// MARK: - Private
private extension CategoryGalleryView {
    func keyForIndexPath(_ indexPath: IndexPath) -> String {
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        if ((index>=0) && (index<categoryList.count)){
            return categoryList[index]
        } else {
            log.error("Index:\(index) out of range (0..\(categoryList.count))")
            return ""
        }
    }
    
    func indexForKey(_ key:String) -> Int{
        if let index = categoryList.firstIndex(of: key) {
            return index
        } else {
            return 0
        }
    }
}



////////////////////////////////////////////
// MARK: - UICollectionViewDataSource
////////////////////////////////////////////

extension CategoryGalleryView {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categoryList.count
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // dequeue the cell
        let cell = categoryGallery?.dequeueReusableCell(withReuseIdentifier: reuseId, for: indexPath) as! CategoryGalleryViewCell
        
        // configure based on the index
        
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        if ((index>=0) && (index<categoryList.count)){
            DispatchQueue.main.async(execute: { () -> Void in
                log.verbose("Index: \(index) key:(\(self.categoryList[index]))")
                let category = self.categoryList[index]

                cell.frame.size = self.cellSize
                cell.delegate = self
                cell.configureCell(frame: cell.frame, index:index, category:category)
            })
            
        } else {
            log.warning("Index out of range (\(index)/\(categoryList.count))")
        }
        return cell
    }
    
}





////////////////////////////////////////////
// MARK: - UICollectionViewDelegate
////////////////////////////////////////////

extension CategoryGalleryView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard (categoryGallery?.cellForItem(at: indexPath) as? CategoryGalleryViewCell) != nil else {
            log.error("NIL cell")
            return
        }
        
        let index:Int = (indexPath as NSIndexPath).item
        selectedIndex = index
        let category = self.categoryList[index]
        let title = self.filterManager.getCategoryTitle(key:category)
        log.verbose("Selected category: \(category) (\(title))")
        
        self.delegate?.categorySelected(category: category)
    }
    
}




////////////////////////////////////////////
// MARK: - CategoryGalleryViewCell
////////////////////////////////////////////
extension CategoryGalleryView: CategoryGalleryViewCellDelegate {
    func categorySelected(category: String) {
        log.verbose("Category selected: \(category)")
        self.delegate?.categorySelected(category: category)
    }
    
    func filterSelected(category: String, key: String) {
        log.verbose("Category: \(category) Filter: \(key)")
        self.delegate?.filterSelected(category: category, key: key)
    }
    
}

////////////////////////////////////////////
// MARK: - UICollectionViewFlowLayout
////////////////////////////////////////////

extension CategoryGalleryView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

