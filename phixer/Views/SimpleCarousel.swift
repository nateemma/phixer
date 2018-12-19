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
    

    fileprivate var carouselHeight:CGFloat = 80.0
    
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

        checkSetup()
        buildItemViews()
        setupCarousel()
        addSubview(carousel!)
        carousel?.fillSuperview()
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
 
        // configure the rest based on whether the icon is specified or not
        if icon.isEmpty {
            // no icon, so just provide a view with a centred label
            let label:UILabel = UILabel()
            label.text = text
            label.textAlignment = .center
            label.textColor = self.theme.textColor
            label.backgroundColor = self.theme.backgroundColor
            label.frame.size.width = label.frame.size.height
            label.lineBreakMode = NSLineBreakMode.byWordWrapping
            label.numberOfLines = 0
            label.font = UIFont.boldSystemFont(ofSize: 12.0)
            label.frame.size.height = self.carouselHeight * 0.95
            view.addSubview(label)
            label.fillSuperview()
        } else {
            // icon specified so create an ImageView using the supplied icon and text

            let imgView:ImageContainerView = ImageContainerView()
            imgView.frame.size = CGSize(width:carouselHeight, height:carouselHeight)
            
            imgView.imageView.frame.size = CGSize(width:carouselHeight*0.6, height:carouselHeight*0.6)

            imgView.label.frame.size = CGSize(width:carouselHeight, height:carouselHeight*0.4)
            
            imgView.label.font = UIFont.systemFont(ofSize: 11.0)
            imgView.label.text = text
            imgView.label.textAlignment = .center
            imgView.label.textColor = theme.textColor
            imgView.label.lineBreakMode = NSLineBreakMode.byWordWrapping
            imgView.label.numberOfLines = 0

            imgView.imageView.contentMode = .scaleAspectFit
            var image = UIImage(named: icon)
            if (image == nil){
                log.warning("icon not found: \(icon)")
                image = UIImage(named:"ic_unknown")
            }
            let tintableImage = image!.withRenderingMode(.alwaysTemplate)
            imgView.imageView.image = tintableImage
            //view.imageView.tintColor =  UIColor(contrastingBlackOrWhiteColorOn:theme.backgroundColor, isFlat:true)
            imgView.imageView.tintColor =  theme.tintColor
            
            imgView.imageView.backgroundColor = theme.backgroundColor
            imgView.layer.borderColor = theme.tintColor.cgColor

            view.addSubview(imgView)
        }

        return view
    }
    
    func setupCarousel(){
        
        // configure carousel
        carouselHeight = max((self.displayHeight * 0.8), 80.0).rounded() // doesn't seem to work at less than 80 (empirical)
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
                    oldView?.layer.borderColor = theme.backgroundColor.cgColor
                }
            }
            
            let newView = itemViewList[index]
            //newView.label.textColor = UIColor.flatLime()
            newView.backgroundColor = theme.backgroundColor
            newView.tintColor = theme.highlightColor
            newView.layer.cornerRadius = 4.0
            newView.layer.borderWidth = 3.0
            newView.layer.borderColor = theme.highlightColor.cgColor
            
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
            return value * 1.05
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
