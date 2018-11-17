//
//  SampleGalleryView.swift
//  phixer
//
//  Created by Philip Price on 10/24/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

import iCarousel


// Interface required of controlling View
protocol SampleGalleryViewDelegate: class {
    func imageSelected(name: String)
}



// this class displays a CollectionView populated with the available Sample images
class SampleGalleryView : UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    
    var theme = ThemeManager.currentTheme()
    

    fileprivate var isLandscape : Bool = false
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
    //fileprivate let sectionInsets = UIEdgeInsets(top: 11.0, left: 10.0, bottom: 11.0, right: 10.0)
    fileprivate let sectionInsets = UIEdgeInsets(top: 4.0, left: 4.0, bottom: 4.0, right: 4.0) // layout is *really* sensitive to left/right for some reason
    
    
    fileprivate var sampleList:[String] = []

    
    fileprivate let layout = UICollectionViewFlowLayout()
    
    fileprivate var sampleGallery:UICollectionView? = nil
    fileprivate var firstTime:Bool = true
    fileprivate var reuseId:String = "SampleGalleryView"
    
    
    // delegate for handling events
    weak var delegate: SampleGalleryViewDelegate?
    
    
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
        
        doLayout()
        doLoadData()
    }

    
    
    
    fileprivate static var initDone:Bool = false
    fileprivate static var layoutDone:Bool = false
    
    fileprivate func doInit(){
        
        if (!SampleGalleryView.initDone){
            SampleGalleryView.initDone = true
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
        
        // set items per row. Add 1 if landscape,
        
        if (isLandscape){
            itemsPerRow = 5
        } else {
            itemsPerRow = 3
        }
        
        layout.itemSize = self.frame.size
        //log.debug("Gallery layout.itemSize: \(layout.itemSize)")
        sampleGallery = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        sampleGallery?.delegate   = self
        sampleGallery?.dataSource = self
        sampleGallery?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseId)
        
        self.addSubview(sampleGallery!)
        sampleGallery?.fillSuperview()
        
    }
    
    fileprivate func doLoadData(){
        //log.verbose("activated")
        
        if (self.sampleList.count > 0){
            self.sampleList = []
        }
        
        // (Re-)build the list of filters
        sampleList = ImageManager.getSampleImageList()
        log.debug ("Loading... \(self.sampleList.count) images")
 
        
        self.sampleGallery?.reloadData()
    }
    
    open func update(){
        self.sampleGallery?.reloadData()
    }
    
    
    open func suspend(){
        // nothing to do in this case
    }
    
    
}



////////////////////////////////////////////
// MARK: - Extensions
////////////////////////////////////////////



// MARK: - Private
private extension SampleGalleryView {
    func keyForIndexPath(_ indexPath: IndexPath) -> String {
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        if ((index>=0) && (index<sampleList.count)){
            return sampleList[index]
        } else {
            log.error("Index:\(index) out of range (0..\(sampleList.count))")
            return ""
        }
    }
}




////////////////////////////////////////////
// MARK: - UICollectionViewDataSource
////////////////////////////////////////////

extension SampleGalleryView {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sampleList.count
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // dequeue the cell
        let cell:UICollectionViewCell = (sampleGallery?.dequeueReusableCell(withReuseIdentifier: reuseId, for: indexPath))!
        
        // configure based on the index
        
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        //log.verbose("Index: \(index) (\(self.sampleList[index]))")
        if ((index>=0) && (index<sampleList.count)){
            let name = self.sampleList[index]
            let size = cell.frame.size
            let imageView = UIImageView()
            let image = ImageManager.getSampleImage(name: name, size:size)
            imageView.image = UIImage(ciImage:image!)
            cell.contentView.addSubview(imageView)
            imageView.fillSuperview()
            
        } else {
            log.warning("Index out of range (\(index)/\(sampleList.count))")
        }
        return cell
    }
    
}





////////////////////////////////////////////
// MARK: - UICollectionViewDelegate
////////////////////////////////////////////

extension SampleGalleryView {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard (sampleGallery?.cellForItem(at: indexPath) != nil) else {
            log.error("NIL cell")
            return
        }
        
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        let name = sampleList[index]
        log.verbose("Selected image: \(name)")
        
        delegate?.imageSelected(name: name)
    }
    
}




////////////////////////////////////////////
// MARK: - UICollectionViewFlowLayout
////////////////////////////////////////////

extension SampleGalleryView {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        //let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let paddingSpace = (sectionInsets.left * (itemsPerRow+1)) + (sectionInsets.right * (itemsPerRow+1)) + 2.0
        let availableWidth = self.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        //log.debug("ItemSize: \(widthPerItem)")
        return CGSize(width: widthPerItem, height: widthPerItem*1.5) // use 2:3 (4:6) ratio
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

