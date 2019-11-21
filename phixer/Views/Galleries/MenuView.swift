//
//  MenuView.swift
//  phixer
//
//  Created by Philip Price on 07/25/19
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import CoreImage
import UIKit


// Interface required of controlling View
protocol MenuViewDelegate: class {
    func itemSelected(key:String)
}



// this class displays a CollectionView populated with the filters for the specified category
//class MenuView : UIView, UICollectionViewDataSource, UICollectionViewDelegate{
class MenuView : UIView, UICollectionViewDataSource {
    
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
    
    fileprivate var sectionInsets = UIEdgeInsets(top: 2.0, left: 3.0, bottom: 2.0, right: 3.0)

    
    fileprivate var menuItems:[MenuItem] = []
    fileprivate var colourList:[UIColor] = []
    fileprivate var seedColour:UIColor = UIColor.flatMint()
    
    fileprivate var currItemKey: String = ""
    fileprivate var filterManager:FilterManager = FilterManager.sharedInstance
    fileprivate var selectedIndex:Int = -1
    
    fileprivate let layout = UICollectionViewFlowLayout()
    
    fileprivate var menuGallery:UICollectionView? = nil
    fileprivate var firstTime:Bool = true
    fileprivate var reuseId:String = "MenuView"
    //fileprivate var opacityFilter:OpacityAdjustment? = nil
    
    
    // delegate for handling events
    weak var delegate: MenuViewDelegate?
    
    
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
        menuItems = []
        colourList = []
        menuGallery = nil
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
        
        // only do layout if menu items have been supplied
        if menuItems.count > 0 {
            self.layoutDone = true
            
            // get display dimensions
            displayHeight = self.frame.size.height
            displayWidth = self.frame.size.width
            
            log.verbose("w:\(displayWidth) h:\(displayHeight)")
            
            self.backgroundColor = theme.backgroundColor

            
            selectedIndex = -1
            
            // always 1 item per row //TODO: explore using 2 items per row if there are a lot of them
            itemsPerRow = 1
            
            // calculate the sizes for the input image and displayed view
            
            let paddingSpace = (sectionInsets.left * (itemsPerRow+1)) + (sectionInsets.right * (itemsPerRow+1)) + 2.0
            let availableWidth = self.frame.width - paddingSpace
            let widthPerItem = availableWidth / itemsPerRow
            
            cellSize = CGSize(width: widthPerItem, height: (UISettings.panelHeight).rounded())
            
            sectionInsets.bottom = (cellSize.height * 0.667).rounded() // otherwise, only half of bottom row shows
            
            // set up the gallery/collection view
            
            layout.itemSize = self.frame.size
            
            //log.debug("Gallery layout.itemSize: \(layout.itemSize)")
            menuGallery = UICollectionView(frame: self.frame, collectionViewLayout: layout)
            menuGallery?.backgroundColor = theme.backgroundColor

            menuGallery?.isPrefetchingEnabled = true
            menuGallery?.delegate   = self
            menuGallery?.dataSource = self
            reuseId = "MenuView_" + currItemKey
            menuGallery?.register(MenuViewCell.self, forCellWithReuseIdentifier: reuseId)
            
            self.addSubview(menuGallery!)
            menuGallery?.fillSuperview()
        }
        
    }
  
    ////////////////////////////////////////////
    // MARK: - Accessors
    ////////////////////////////////////////////

    open func update(){
        //self.menuGallery?.setNeedsDisplay()
        self.menuGallery?.reloadData()
        //doLoadData()
    }
    
    open func setItems(_ items:[MenuItem]){
        if items.count > 0 {
            menuItems = items
            doLayout()
            firstTime = false
        }
    }
    
    // Suspend all MetalPetal-related operations
    open func suspend(){

    }
    
    
    
    // releaes the resources that we used for the gallery items
    
    private func releaseResources(){

    }
    
    
}



////////////////////////////////////////////
// MARK: - Extensions
////////////////////////////////////////////



// MARK: - Private
private extension MenuView {
    func keyForIndexPath(_ indexPath: IndexPath) -> String {
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        if ((index>=0) && (index<menuItems.count)){
            return menuItems[index].key
        } else {
            log.error("Index:\(index) out of range (0..\(menuItems.count))")
            return ""
        }
    }
    
    func indexForKey(_ key:String) -> Int{
        var index:Int = 0
        if menuItems.count > 0 {
            for i in 0...(menuItems.count-1) {
                if menuItems[i].key == key {
                    index = i
                    break
                }
            }
        }
        return index
    }
}



////////////////////////////////////////////
// MARK: - UICollectionViewDataSource
////////////////////////////////////////////

extension MenuView {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // dequeue the cell
        let cell = menuGallery?.dequeueReusableCell(withReuseIdentifier: reuseId, for: indexPath) as! MenuViewCell
        
        // configure based on the index
        
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        if ((index>=0) && (index<menuItems.count)){
            DispatchQueue.main.async(execute: { () -> Void in
                //log.verbose("Index: \(index) key:(\(self.menuItems[index]))")
                _ = self.menuItems[index]

                cell.frame.size = self.cellSize
                cell.delegate = self
                cell.configureCell(frame: cell.frame, index:index, menuItem:self.menuItems[index])
            })
            
        } else {
            log.warning("Index out of range (\(index)/\(menuItems.count))")
        }
        return cell
    }
    
}





////////////////////////////////////////////
// MARK: - UICollectionViewDelegate
////////////////////////////////////////////

extension MenuView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard (menuGallery?.cellForItem(at: indexPath) as? MenuViewCell) != nil else {
            log.error("NIL cell")
            return
        }
        
        let index:Int = (indexPath as NSIndexPath).item
        selectedIndex = index
        let key = self.menuItems[index].key
        log.verbose("Selected key: \(key)")
        
        self.delegate?.itemSelected(key: key)
    }
    
}




////////////////////////////////////////////
// MARK: - MenuViewCell
////////////////////////////////////////////
extension MenuView: MenuViewCellDelegate {
    func itemSelected(key: String) {
        log.verbose("key selected: \(key)")
        self.delegate?.itemSelected(key: key)
    }
}

////////////////////////////////////////////
// MARK: - UICollectionViewFlowLayout
////////////////////////////////////////////

extension MenuView: UICollectionViewDelegateFlowLayout {
    
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

