//
//  SimpleSwipeView.swift
//  phixer
//
//  Created by Philip Price on 07/24/19
//  Copyright © 2018 Nateemma. All rights reserved.
//

// implements a horizontal swipeview of menu items that contain only text and/or an icon

import Foundation
import UIKit
import Neon



class SimpleSwipeView: UIView {
    
    
    
    //////////////////////////////////////////
    // MARK: - Menu/SwipeView setup and handling
    //////////////////////////////////////////
    
    var theme = ThemeManager.currentTheme()

    // delegate for handling events
    weak var delegate: AdornmentDelegate? = nil

    // the underlying swipeview display
    fileprivate var swipeview:SwipeView? = SwipeView()
    
    // list of adornments
    fileprivate var itemList: [Adornment] = []
    
    
    // the display views for each items
    fileprivate var itemViewList: [UIView] = []
    

    fileprivate var swipeviewHeight:CGFloat = 64.0 // default, likely to change
    fileprivate var itemSize:CGSize = CGSize(width: 64.0, height: 64.0)

    fileprivate var currIndex:Int = -1
    
    fileprivate var displayWidth : CGFloat = 0.0
    fileprivate var displayHeight : CGFloat = 0.0
    
    fileprivate var wrap:Bool = true // wrap by default
    
    fileprivate var addBorder:Bool = false
 
    
    ////////////////////////////////////////////
    //MARK: Accessors
    ////////////////////////////////////////////

    public func setItems(_ items:[Adornment]) {
        itemList = items
        buildItemViews()
        //DispatchQueue.main.asyncAfter(deadline: <#T##DispatchTime#>, execute: <#T##() -> Void#>) { [weak self] in
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) { [weak self] in
            self?.swipeview?.reloadData()
        }
        //log.verbose("items:\(items)")
    }

    public func getNextItem() -> String {
        var index:Int = 0
        
        if itemList.count > 0 {
            if isValidIndex(currIndex) {
                index = (currIndex < (itemList.count-1)) ? (currIndex + 1) : 0
            } else {
                index = 0
            }
            return itemList[index].key
        } else {
            log.error("No items in list")
            return ""
        }
    }
    
    public func getPreviousItem() -> String {
        var index:Int = 0
        
        if itemList.count > 0 {
            if isValidIndex(currIndex) {
                index = (currIndex > 0) ? (currIndex - 1) : (itemList.count - 1)
            } else {
                index = 0
            }
            return itemList[index].key
        } else {
            log.error("No items in list")
            return ""
       }
    }

    public func nextItem(){
        var index:Int = 0
        
        if itemList.count > 0 {
            if isValidIndex(currIndex) {
                index = (currIndex < (itemList.count-1)) ? (currIndex + 1) : 0
            } else {
                index = 0
            }
            self.selectItem(index)
        } else {
            log.error("No items in list")
        }
    }
    
    public func previousItem(){
        var index:Int = 0
        
        if itemList.count > 0 {
            if isValidIndex(currIndex) {
                index = (currIndex > 0) ? (currIndex - 1) : (itemList.count - 1)
            } else {
                index = 0
            }
            self.selectItem(index)
        } else {
            log.error("No items in list")
        }
    }

    public func enableWrap(){
        self.wrap = true
    }

    public func disableWrap(){
        self.wrap = false
    }

    public func disableBorder(){
        addBorder = false
    }
    
    public func enableBorder(){
        addBorder = true
    }
    
    ////////////////////////////////////////////
    //MARK: Layout
    ////////////////////////////////////////////
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // get display dimensions (convenience)
        displayHeight = self.frame.size.height
        displayWidth = self.frame.size.width
        
        swipeviewHeight = displayHeight
        itemSize = CGSize(width: swipeviewHeight, height: swipeviewHeight)
        
        theme = ThemeManager.currentTheme()
        self.backgroundColor = theme.backgroundColor

        checkSetup()
        buildItemViews()
        setupSwipeView()
        addSubview(swipeview!)
        //swipeview?.fillSuperview()
        
        log.verbose("w:\(self.frame.size.width) h:\(self.frame.size.height)")
    }

    
    func checkSetup(){
        // since we have multiple APIs to set things up, just double-check
        if itemList.count <= 0 {
            log.warning("Items not set up")
        }
    }
    
    func buildItemViews(){
        // build display views
        itemViewList = []
        
        var icon:String = ""
        
        if (itemList.count > 0){
            for i in (0...itemList.count-1) {
                icon = ""
                if (itemList.count>0) && (i<itemList.count) {
                    icon = itemList[i].icon
                }
                itemViewList.append(makeItemView(icon:icon, text:itemList[i].text))
            }
        }
    }
    
    func makeItemView(icon:String, text:String) -> UIView {
        
        let view:ImageContainerView = ImageContainerView()
        view.frame.size.width = self.swipeviewHeight
        view.frame.size.height = self.swipeviewHeight
        view.disableBorder()
 
        let label:UILabel = UILabel()
        label.text = text
        label.textAlignment = .center
        label.textColor = self.theme.textColor
        label.backgroundColor = self.theme.backgroundColor
        label.frame.size.width = view.frame.size.width
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 0

        // configure the rest based on whether the icon is specified or not
        if icon.isEmpty {
            // no icon, so just provide a view with a centred label
            label.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.thin)
            label.frame.size.height = self.swipeviewHeight * 0.95
            view.addSubview(label)
            label.fillSuperview()
        } else {
            // icon specified so create a compound view using the supplied icon and text

            let imgView:UIView = UIView()
            imgView.frame.size = CGSize(width:swipeviewHeight, height:swipeviewHeight)
            
            let image: UIImageView = UIImageView()

            if text.isEmpty {
                // no label, so set to zero height and hide, fill cell with image
                label.frame.size.height = 0.0
                label.isHidden = true
                image.frame.size = CGSize(width:swipeviewHeight*0.9, height:swipeviewHeight*0.9)
            } else {
                image.frame.size = CGSize(width:swipeviewHeight*0.6, height:swipeviewHeight*0.6)
                // make label smaller
                label.frame.size = CGSize(width:swipeviewHeight, height:swipeviewHeight*0.4)
                label.font = UIFont.systemFont(ofSize: 10.0, weight: UIFont.Weight.thin)
                //label.fitTextToBounds()
            }

            // get the icon
            image.contentMode = .scaleAspectFit
            var icview: UIImage? = nil
            if icon.contains("/") {
                // can't tint managed assets, so just load
                icview = ImageManager.getImageFromAssets(assetID: icon, size: imgView.frame.size)
                image.image = icview
            } else {
                image.tintColor = theme.tintColor
                icview = UIImage(named: icon)
                let tintableImage = icview!.withRenderingMode(.alwaysTemplate)
                image.image = tintableImage
            }
            //var
            if (icview == nil){
                log.warning("icon not found: \(icon)")
                image.image = UIImage(named:"ic_unknown")?.withRenderingMode(.alwaysTemplate)
            }

            //view.imageView.tintColor =  UIColor(contrastingBlackOrWhiteColorOn:theme.backgroundColor, isFlat:true)
            //image.tintColor =  theme.tintColor
            
            image.backgroundColor = theme.backgroundColor
            if addBorder {
                imgView.layer.cornerRadius = 1.0
                imgView.layer.borderWidth = 0.2
                imgView.layer.borderColor = theme.borderColor.cgColor
                log.debug("border: \(theme.borderColor)")
            } else {
                imgView.layer.cornerRadius = 0.0
                imgView.layer.borderWidth = 0.0
                imgView.layer.borderColor = nil
            }

            imgView.addSubview(image)
            imgView.addSubview(label)

            image.anchorAndFillEdge(.top, xPad: 2.0, yPad: 2.0, otherSize: image.frame.size.height)
            label.alignAndFill(align: .underCentered, relativeTo: image, padding: 0)
            view.addSubview(imgView)
        }

        return view
    }
    
    func setupSwipeView(){
        
        // configure swipeview
        swipeviewHeight = max((self.displayHeight * 0.95), 32.0).rounded() // don't go below 32 pixels
        itemSize = CGSize(width: swipeviewHeight, height: swipeviewHeight)
        swipeview?.frame.size.width = self.displayWidth
        swipeview?.frame.size.height = swipeviewHeight
        
        swipeview?.dataSource = self
        swipeview?.delegate = self
        swipeview?.pagingEnabled = true
        swipeview?.alignment = SwipeViewAlignment.Edge
        swipeview?.bounces = false
        //swipeview?.autoscroll = 1.0
        swipeview?.decelerationRate = UIScrollView.DecelerationRate.normal.rawValue
        swipeview?.defersItemViewLoading = true

        //swipeview?.centerItemWhenSelected = true
    }
    
    
    ////////////////////////////////////////////
    //MARK: Utilities
    ////////////////////////////////////////////
    

    
    // convenience function to check the index
    func isValidIndex(_ index:Int)->Bool{
        return ((index>=0) && (index < itemList.count) && (itemList.count>0))
    }
    
    
    // highlights the selection and updates variables
    fileprivate func highlightSelection(_ swipeview: SwipeView, index: Int){
        
        guard (isValidIndex(index)) else {
            return
        }
        
        if itemViewList.count <= 0 {
            buildItemViews()
        }
        
        if (index != currIndex){
            
            log.debug("Highlight: \(itemList[index].text) (\(currIndex)->\(index))")
            
            // updates label colors of selected item, reset old selection
            if (isValidIndex(currIndex)){
                var oldView: UIView? = nil
                oldView = itemViewList[currIndex]
                //oldView.label.textColor = theme.textColor
                if (oldView != nil){
                    oldView?.backgroundColor = theme.backgroundColor
                    //oldView?.tintColor = theme.tintColor
                    if addBorder {
                        oldView?.layer.cornerRadius = 1.0
                        oldView?.layer.borderWidth = 0.5
                        oldView?.layer.borderColor = theme.borderColor.cgColor
                    }
                }
            }
            
            let newView = itemViewList[index]
            //newView.label.textColor = UIColor.flatLime()
            newView.backgroundColor = theme.backgroundColor
            //newView.tintColor = theme.highlightColor
            if addBorder {
                newView.layer.cornerRadius = 1.0
                newView.layer.borderWidth = 0.5
                newView.layer.borderColor = theme.highlightColor.cgColor
            }
            
            // scroll to selected item
            //swipeview.scrollToItem(at: index, animated: false)
            swipeview.scrollToItemAtIndex(index: index, duration: 0.01)
            
        }
    }
    
    // call the handler associated with the item
    func handleOption(_ index:Int){
        guard (self.isValidIndex(index)) else {
            log.error("Invalid index: \(index)")
            return
        }
        
        if ((index < itemList.count) && (itemList.count>0)){
            log.verbose("Calling handler for: \(itemList[index].text)")
            delegate?.adornmentItemSelected(key: itemList[index].key)
        } else {
            log.error("Invalid index for: \(itemList[index].text)")
        }
    }
    
    // select an item in the swipeview. Can be called manually or by touching the screen
    func selectItem(_ index:Int){
        guard (self.isValidIndex(index)) else {
            log.error("Invalid index: \(index)")
            return
        }
        
        log.debug("Selected index:\(index)")
        self.highlightSelection(swipeview!, index: index)
        
        self.currIndex = index
        self.handleOption(index)

    }
    
}




//########################
//MARK: SwipeView delegate functions
//########################

extension SimpleSwipeView: SwipeViewDataSource {
    func numberOfItemsInSwipeView(swipeView: SwipeView) -> Int {
        //log.verbose("\(itemList.count) items")
        return itemList.count
    }
    
    func viewForItemAtIndex(index: Int, swipeView: SwipeView, reusingView: UIView?) -> UIView? {
        guard (self.isValidIndex(index)) else {
            log.error("Invalid index: \(index) (count:\(itemList.count))")
            return UIView()
        }
        
        //log.verbose("index:\(index) = \(itemList[index].text)")
        
        return self.itemViewList[index]
    }
}


extension SimpleSwipeView: SwipeViewDelegate {
    
    func swipeViewItemSize(swipeView: SwipeView) -> CGSize {
        return self.itemSize
    }

    func didSelectItemAtIndex(index: Int, swipeView: SwipeView) {
        self.selectItem(index)
    }
    
    func shouldSelectItemAtIndex(index: Int, swipeView: SwipeView) -> Bool {
        return true
    }
    
    /*** only uncomment if you want to auto choose an item when scrolling ends
     // called when user stops scrolling through list
     func swipeviewDidEndScrollingAnimation(_ swipeview: SwipeView) {
     let index = swipeview?.currentItemIndex
     
     log.debug("End scrolling at index:\(index)")
     highlightSelection(swipeview, index: index)
     }
     ***/
}
