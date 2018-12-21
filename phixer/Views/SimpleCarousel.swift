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

    
    fileprivate var carousel:iCarousel? = iCarousel()
    
    // the list of controls (not sorted, so put in the order you want displayed)
    fileprivate var itemTitleList: [String] = []
    
    // array of handlers (no args, no return). Order must match the names
    fileprivate var itemHandlerList:[()->()] = []
    
    // array of icon names. An empty string (or array) results in a text-only item. Order must match the names
    fileprivate var itemIconList:[String] = []
    
    // the display views for each items
    fileprivate var itemViewList: [UIView] = []
    

    fileprivate var carouselHeight:CGFloat = 64.0
    
    fileprivate var currIndex:Int = -1
    
    fileprivate var displayWidth : CGFloat = 0.0
    fileprivate var displayHeight : CGFloat = 0.0

    
    public func setTitles(_ titles:[String]) {
        itemTitleList = titles
        log.verbose("titles:\(titles)")
    }
    
    public func setHandlers(_ handlers:Array< () -> Void>){
        itemHandlerList = handlers
    }
    
    public func setIcons(_ icons:[String]){
        itemIconList = icons
    }

    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // get display dimensions (convenience)
        displayHeight = self.frame.size.height
        displayWidth = self.frame.size.width
        
        carouselHeight = displayHeight

        checkSetup()
        buildItemViews()
        setupCarousel()
        addSubview(carousel!)
        //carousel?.fillSuperview()
        
        log.verbose("w:\(self.frame.size.width) h:\(self.frame.size.height)")
    }

    
    func checkSetup(){
        // since we have multiple APIs to set things up, just double-check
        if itemTitleList.count <= 0 {
            log.error("Titles not set up")
        }
        if itemHandlerList.count <= 0 {
            log.error("Handlers not set up")
        }
        if itemTitleList.count != itemHandlerList.count {
            log.error("Titles (\(itemTitleList.count)) and Handlers (\(itemHandlerList.count)) do not match")
        }
    }
    
    func buildItemViews(){
        // build display views
        itemViewList = []
        
        var icon:String = ""
        
        // we assume the title list is the 'main' list that drives others
        if (itemTitleList.count > 0){
            for i in (0...itemTitleList.count-1) {
                icon = ""
                if (itemIconList.count>0) && (i<itemIconList.count) {
                    icon = itemIconList[i]
                }
                itemViewList.append(makeItemView(icon:icon, text:itemTitleList[i]))
            }
        }
    }
    
    func makeItemView(icon:String, text:String) -> UIView {
        
        let view:ImageContainerView = ImageContainerView()
        view.frame.size.width = self.carouselHeight
        view.frame.size.height = self.carouselHeight
 
        let label:UILabel = UILabel()
        label.text = text
        label.textAlignment = .center
        label.textColor = self.theme.textColor
        label.backgroundColor = self.theme.backgroundColor
        label.frame.size.width = label.frame.size.height
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 0

        // configure the rest based on whether the icon is specified or not
        if icon.isEmpty {
            // no icon, so just provide a view with a centred label
            label.font = UIFont.boldSystemFont(ofSize: 12.0)
            label.frame.size.height = self.carouselHeight * 0.95
            view.addSubview(label)
            label.fillSuperview()
        } else {
            // icon specified so create a compound view using the supplied icon and text

            let imgView:UIView = UIView()
            imgView.frame.size = CGSize(width:carouselHeight, height:carouselHeight)
            
            let image: UIImageView = UIImageView()
            image.frame.size = CGSize(width:carouselHeight*0.6, height:carouselHeight*0.6)

            // make label smaller
            label.frame.size = CGSize(width:carouselHeight, height:carouselHeight*0.4)
            label.font = UIFont.systemFont(ofSize: 10.0)
            //label.fitTextToBounds()

            // get the icon
            image.contentMode = .scaleAspectFit
            var icview = UIImage(named: icon)
            if (icview == nil){
                log.warning("icon not found: \(icon)")
                icview = UIImage(named:"ic_unknown")
            }
            let tintableImage = icview!.withRenderingMode(.alwaysTemplate)
            image.image = tintableImage
            //view.imageView.tintColor =  UIColor(contrastingBlackOrWhiteColorOn:theme.backgroundColor, isFlat:true)
            image.tintColor =  theme.tintColor
            
            image.backgroundColor = theme.backgroundColor
            imgView.layer.borderColor = theme.tintColor.cgColor

            imgView.addSubview(image)
            imgView.addSubview(label)

            image.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: image.frame.size.height)
            label.alignAndFill(align: .underCentered, relativeTo: image, padding: 0)
            view.addSubview(imgView)
        }

        return view
    }
    
    func setupCarousel(){
        
        // configure carousel
        //carouselHeight = max((self.displayHeight * 0.8), 80.0).rounded() // doesn't seem to work at less than 80 (empirical)
        carouselHeight = max((self.displayHeight * 0.8), 32.0).rounded() // don't go below 32 pixels
        carousel?.frame.size.width = self.displayWidth
        carousel?.frame.size.height = carouselHeight
        
        carousel?.dataSource = self
        carousel?.delegate = self
        carousel?.type = .linear
        //carousel?.centerItemWhenSelected = true
    }
    
   
    
    // convenience function to check the index
    func isValidIndex(_ index:Int)->Bool{
        return ((index>=0) && (index < itemTitleList.count) && (itemTitleList.count>0))
    }
    
    
    // highlights the selection and updates variables
    fileprivate func highlightSelection(_ carousel: iCarousel, index: Int){
        
        guard (isValidIndex(index)) else {
            return
        }
        
        if (index != currIndex){
            
            log.debug("Highlight: \(itemTitleList[index]) (\(currIndex)->\(index))")
            
            // updates label colors of selected item, reset old selection
            if (isValidIndex(currIndex)){
                var oldView: UIView? = nil
                oldView = itemViewList[currIndex]
                //oldView.label.textColor = theme.textColor
                if (oldView != nil){
                    oldView?.backgroundColor = theme.backgroundColor
                   oldView?.tintColor = theme.textColor
                    oldView?.layer.cornerRadius = 4.0
                    oldView?.layer.borderWidth = 1.0
                    oldView?.layer.borderColor = theme.backgroundColor.withAlphaComponent(0.5).cgColor
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
    
    
    func handleOption(_ index:Int){
        guard (self.isValidIndex(index)) else {
            log.error("Invalid index: \(index)")
            return
        }
        
        if ((index < itemHandlerList.count) && (itemHandlerList.count>0)){
            log.verbose("Calling handler for: \(itemTitleList[index])")
            let f = itemHandlerList[index]
            f()
        } else {
            log.error("Handler not set up for: \(itemTitleList[index])")
        }
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
        log.verbose("\(itemTitleList.count) items")
        return itemTitleList.count
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        guard (self.isValidIndex(index)) else {
            log.error("Invalid index: \(index) (count:\(itemTitleList.count))")
            return UIView()
        }
        
        //log.verbose("index:\(index) = \(itemTitleList[index])")
        
        return self.itemViewList[index]
    }
    
    
    // set custom items
    func carousel(_ carousel: iCarousel, valueFor item: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        
        // spacing between items
        if (item == iCarouselOption.spacing){
            return value * 1.0
            //return value
        } else if (item == iCarouselOption.wrap){
            //return value
            return 1.0
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
        self.highlightSelection(carousel, index: index)
        
        //log.debug("Selected index:\(index)")
        self.currIndex = index
        self.handleOption(index)
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
