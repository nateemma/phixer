//
//  BlendGalleryView.swift
//  phixer
//
//  Created by Philip Price on 10/24/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

import iCarousel

// Interface required of controlling View
protocol BlendGalleryViewDelegate: class {
    func imageSelected(name: String)
}



// this class displays a CollectionView populated with the available Blend images
class BlendGalleryView : UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    
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
    
    
    fileprivate var blendList:[String] = []

    
    fileprivate let layout = UICollectionViewFlowLayout()
    
    fileprivate var blendGallery:UICollectionView? = nil
    fileprivate var firstTime:Bool = true
    fileprivate var reuseId:String = "BlendGalleryView"
    
    
    // delegate for handling events
    weak var delegate: BlendGalleryViewDelegate?
    
    
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
        
        if (!BlendGalleryView.initDone){
            BlendGalleryView.initDone = true
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
        blendGallery = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        blendGallery?.delegate   = self
        blendGallery?.dataSource = self
        blendGallery?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseId)
        
        self.addSubview(blendGallery!)
        blendGallery?.fillSuperview()
        
    }
    
    fileprivate func doLoadData(){
        //log.verbose("activated")
        
        if (self.blendList.count > 0){
            self.blendList = []
        }
        
        // (Re-)build the list of filters
        blendList = ImageManager.getBlendImageList()
        log.debug ("Loading... \(self.blendList.count) images")
 
        
        self.blendGallery?.reloadData()
    }
    
    open func update(){
        self.blendGallery?.reloadData()
    }
    
    
    open func suspend(){
        // nothing to do in this case
    }
    
    
}



////////////////////////////////////////////
// MARK: - Extensions
////////////////////////////////////////////



// MARK: - Private
private extension BlendGalleryView {
    func keyForIndexPath(_ indexPath: IndexPath) -> String {
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        if ((index>=0) && (index<blendList.count)){
            return blendList[index]
        } else {
            log.error("Index:\(index) out of range (0..\(blendList.count))")
            return ""
        }
    }
}




////////////////////////////////////////////
// MARK: - UICollectionViewDataSource
////////////////////////////////////////////

extension BlendGalleryView {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return blendList.count
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // dequeue the cell
        let cell:UICollectionViewCell = (blendGallery?.dequeueReusableCell(withReuseIdentifier: reuseId, for: indexPath))!
        
        // configure based on the index
        
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        //log.verbose("Index: \(index) (\(self.blendList[index]))")
        if ((index>=0) && (index<blendList.count)){
            let name = self.blendList[index]
            let size = cell.frame.size
            let imageView = UIImageView()
            let image = ImageManager.getBlendImage(name: name, size:size)
            imageView.image = image
            cell.contentView.addSubview(imageView)
            imageView.fillSuperview()
            
        } else {
            log.warning("Index out of range (\(index)/\(blendList.count))")
        }
        return cell
    }
    
}





////////////////////////////////////////////
// MARK: - UICollectionViewDelegate
////////////////////////////////////////////

extension BlendGalleryView {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard (blendGallery?.cellForItem(at: indexPath) != nil) else {
            log.error("NIL cell")
            return
        }
        
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        let name = blendList[index]
        log.verbose("Selected image: \(name)")
        
        delegate?.imageSelected(name: name)
    }
    
}




////////////////////////////////////////////
// MARK: - UICollectionViewFlowLayout
////////////////////////////////////////////

extension BlendGalleryView {
    
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

