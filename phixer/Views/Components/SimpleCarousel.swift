//
//  SimpleCarousel.swift
//  phixer
//
//  Created by Philip Price on 12/18/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

// implements a carousel of menu items that contain only text and an optional icon

import Foundation
import UIKit
import Neon
import iCarousel



class SimpleCarousel: UIView {
    
    
    
    //////////////////////////////////////////
    // MARK: - Menu/Carousel setup and handling
    //////////////////////////////////////////
    
    var theme = ThemeManager.currentTheme()

    // delegate for handling events
    weak var delegate: AdornmentDelegate? = nil

    // the underlying carousel display
    fileprivate var carousel:iCarousel? = iCarousel()
    
    // list of adornments
    fileprivate var itemList: [Adornment] = []
    
    
    // the display views for each items
    fileprivate var itemViewList: [UIView] = []
    

    fileprivate var carouselHeight:CGFloat = 64.0
    
    fileprivate var currIndex:Int = -1
    
    fileprivate var displayWidth : CGFloat = 0.0
    fileprivate var displayHeight : CGFloat = 0.0
    
    fileprivate var wrap:Bool = true // wrap by default
 
    
    ////////////////////////////////////////////
    //MARK: Accessors
    ////////////////////////////////////////////

    public func setItems(_ items:[Adornment]) {
        itemList = items
        //log.verbose("items:\(items)")
//        if !self.wrap && (itemList.count >= 2) {
//            log.verbose("Scroll to 2")
//            carousel?.scrollToItem(at: 2, animated: true)
//        }
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

    ////////////////////////////////////////////
    //MARK: Layout
    ////////////////////////////////////////////
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // get display dimensions (convenience)
        displayHeight = self.frame.size.height
        displayWidth = self.frame.size.width
        
        carouselHeight = displayHeight
        
        theme = ThemeManager.currentTheme()
        self.backgroundColor = theme.backgroundColor

        checkSetup()
        setupCarousel()
        buildItemViews()
        addSubview(carousel!)
        //carousel?.fillSuperview()
        
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
        
        // we assume the title list is the 'main' list that drives others
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
        let cellSize = (self.carouselHeight - 1.0).rounded() // allow for border
        view.frame.size.width = cellSize // square
        view.frame.size.height = cellSize
 
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
            label.font = theme.getFont(ofSize: 12.0, weight: UIFont.Weight.thin)
            label.frame.size.height = (cellSize * 0.95).rounded()
            view.addSubview(label)
            label.fillSuperview()
        } else {
            // icon specified so create a compound view using the supplied icon and text

            let imgView:UIView = UIView()
            imgView.frame.size = CGSize(width:cellSize, height:cellSize)
            
            let image: UIImageView = UIImageView()

            if text.isEmpty {
                // no label, so set to zero height and hide, fill cell with image
                label.frame.size.height = 0.0
                label.isHidden = true
                image.frame.size = CGSize(width:cellSize, height:cellSize)
            } else {
                // both icon and text supplied
                image.frame.size = CGSize(width:(cellSize*0.6).rounded(), height:(cellSize*0.6).rounded())
                // make label smaller
                label.frame.size = CGSize(width:cellSize, height:(cellSize*0.4).rounded())
                label.font = theme.getFont(ofSize: 10.0, weight: UIFont.Weight.thin)
                //label.fitTextToBounds()
            }

            // get the icon
            image.contentMode = .scaleAspectFit
            var icview: UIImage? = nil
            if icon.contains("/") {
                // can't tint managed assets, so just load
                icview = ImageManager.getImageFromAssets(assetID: icon, size: image.frame.size)
                image.image = icview
            } else {
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
            image.tintColor =  theme.tintColor
            
            image.backgroundColor = theme.backgroundColor
            label.layer.borderColor = UIColor.clear.cgColor
            image.layer.borderColor = UIColor.clear.cgColor
            
            imgView.layer.cornerRadius = 4.0
            imgView.layer.borderWidth = 0.5
            imgView.layer.borderColor = theme.borderColor.withAlphaComponent(0.5).cgColor
            
            imgView.addSubview(image)
            imgView.addSubview(label)

            image.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: image.frame.size.height)
            label.alignAndFill(align: .underCentered, relativeTo: image, padding: 0)
            view.addSubview(imgView)
            
            image.isUserInteractionEnabled = false
            label.isUserInteractionEnabled = false
            imgView.isUserInteractionEnabled = false
        }

        return view
    }
    
    func setupCarousel(){
        
        // configure carousel
        //carouselHeight = max((self.displayHeight * 0.8), 80.0).rounded() // doesn't seem to work at less than 80 (empirical)
        //carouselHeight = max((self.displayHeight * 0.8), 32.0).rounded() // don't go below 32 pixels
        //carouselHeight = max((self.displayHeight-1.0), 32.0).rounded() // don't go below 32 pixels
        carouselHeight = max((self.displayHeight), 32.0).rounded() // don't go below 32 pixels
        carousel?.frame.size.width = self.displayWidth
        carousel?.frame.size.height = carouselHeight
        carousel?.type = .linear
        carousel?.isUserInteractionEnabled = true
        
        carousel?.dataSource = self
        carousel?.delegate = self
        
        //carousel?.centerItemWhenSelected = true
    }
    
    
    ////////////////////////////////////////////
    //MARK: Utilities
    ////////////////////////////////////////////
    

    
    // convenience function to check the index
    func isValidIndex(_ index:Int)->Bool{
        return ((index>=0) && (index < itemList.count) && (itemList.count>0))
    }
    
    
    // highlights the selection and updates variables
    fileprivate func highlightSelection(_ carousel: iCarousel, index: Int){
        
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
                   oldView?.tintColor = theme.tintColor
                    oldView?.layer.cornerRadius = 4.0
                    oldView?.layer.borderWidth = 0.5
                    oldView?.layer.borderColor = theme.borderColor.withAlphaComponent(0.5).cgColor
                }
            }
            
            let newView = itemViewList[index]
            //newView.label.textColor = UIColor.flatLime()
            newView.backgroundColor = theme.backgroundColor
            newView.tintColor = theme.highlightColor
            newView.layer.cornerRadius = 4.0
            newView.layer.borderWidth = 3.0
            newView.layer.borderColor = theme.highlightColor.withAlphaComponent(0.5).cgColor
            
            // scroll to selected item
            carousel.scrollToItem(at: index, animated: false)
            
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
    
    // select an item in the carousel. Can be called manually or by touching the screen
    func selectItem(_ index:Int){
        guard (self.isValidIndex(index)) else {
            log.error("Invalid index: \(index)")
            return
        }
        
        log.debug("Selected index:\(index)")
        self.highlightSelection(carousel!, index: index)
        
        self.currIndex = index
        self.handleOption(index)

    }
    
}




//########################
//MARK: iCarousel delegate functions
//########################

extension SimpleCarousel: iCarouselDelegate{
}

extension SimpleCarousel: iCarouselDataSource{
    
    // number of items in list
    func numberOfItems(in carousel: iCarousel) -> Int {
        log.verbose("\(itemList.count) items")
        return itemList.count
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        guard (self.isValidIndex(index)) else {
            log.error("Invalid index: \(index) (count:\(itemList.count))")
            return UIView()
        }
        
        //log.verbose("index:\(index) = \(itemList[index].text)")
        
        return self.itemViewList[index]
    }
    
    
    // set custom items
    func carousel(_ carousel: iCarousel, valueFor item: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        
        // spacing between items
        if (item == iCarouselOption.spacing){
            return value * 1.0
        } else if (item == iCarouselOption.wrap){
            //return 1.0
            if self.wrap {
                return 1.0
            } else {
                return 0.0
            }
        }
        
        // default
        return value
    }
    
    
    /* // don't use this as it will cause too many updates
     // called whenever an ite passes to/through the center spot
     func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
     let index = carousel?.currentItemIndex
     log.debug("Selected: \(categoryList[index])")
     }
     */
    
    // called when an item is selected manually (i.e. touched).
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        self.selectItem(index)
    }
    
    /*** only uncomment if you want to auto choose an item when scrolling ends
     // called when user stops scrolling through list
     func carouselDidEndScrollingAnimation(_ carousel: iCarousel) {
     let index = carousel?.currentItemIndex
     
     log.debug("End scrolling at index:\(index)")
     highlightSelection(carousel, index: index)
     }
     ***/
}
