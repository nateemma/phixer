//
//  CategorySelectionView.swift
//  FilterCam
//
//  Created by Philip Price on 10/18/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage

// A view that implements an iCarousel scrolling list for showing categories



// Interface required of controlling View
protocol CategorySelectionViewDelegate: class {
    func categorySelected(_ category:FilterCategoryType)
}


class CategorySelectionView: UIView, iCarouselDelegate, iCarouselDataSource{

    var categoryCarousel:iCarousel = iCarousel()
    var filterManager: FilterManager? = FilterManager.sharedInstance
    var categoryList: [FilterCategoryType] = []
    var categoryViewList: [UILabel] = []
    var currCategory:FilterCategoryType = FilterCategoryType.quickSelect
    var categoryLabel:UILabel = UILabel()
    var carouselHeight:CGFloat = 80.0
    var currIndex:Int = -1
    
    // delegate for handling events
    weak var delegate: CategorySelectionViewDelegate?

    //MARK: - Public accessors
    
    func setFilterCategory(_ category:FilterCategoryType){
        currCategory = category
        log.debug("Filter category set to: \(category.rawValue)")
        categoryCarousel.setNeedsLayout()
    }
    
    func update(){
        let newIndex = filterManager?.getCurrentCategory().getIndex()
        if (currIndex != newIndex){
            categoryCarousel.scrollToItem(at: newIndex!, animated: true)
            currIndex = newIndex!
        }
    }
    
    func getCurrentSelection()->String{
        guard ((categoryList.count>0) && (currIndex<categoryList.count) && (currIndex>=0)) else {
            return ""
        }
        
        return categoryList[currIndex].rawValue
    }
    
    /*** //TODO: define container view for categories. Probably just 2 labels (title and description)
    private func createCategoryContainerView(_ descriptor: FilterDescriptorInterface) -> RenderContainerView{
        var view:RenderContainerView = RenderContainerView()
        view.frame.size = CGSize(width:carouselHeight, height:carouselHeight)
        view.label.text = descriptor.key
        
        //TODO: start rendering in an asynch queue
        
        return view
    }
 ***/
   
    fileprivate static var initDone:Bool = false
    func doInit(){
        if (!CategorySelectionView.initDone){
            carouselHeight = fmax((self.frame.size.height * 0.8), 80.0) // doesn't seem to work at less than 80 (empirical)
            //carouselHeight = self.frame.size.height * 0.82
            
            // Pre-allocate views for the filters, makes it much easier and we can update in the background if needed
            
            categoryList = (filterManager?.getCategoryList())!
            categoryViewList = []
            
            if (categoryList.count > 0){
                for i in (0...categoryList.count-1) {
                    categoryViewList.append(UILabel())
                }
                
            }
            
            categoryLabel.text = "Categories"
            categoryLabel.textAlignment = .center
            categoryLabel.textColor = UIColor.white
            categoryLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
            categoryLabel.frame.size.height = carouselHeight * 0.18
            categoryLabel.frame.size.width = self.frame.size.width
            self.addSubview(categoryLabel)
           
            CategorySelectionView.initDone = true
        }
    }
    //MARK: - UIView required functions
    convenience init(){
        self.init(frame: CGRect.zero)
        doInit()
    }

    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        doInit()
        
        categoryCarousel.frame = self.frame
        self.addSubview(categoryCarousel)
        //categoryCarousel.fillSuperview()
        
        categoryCarousel.dataSource = self
        categoryCarousel.delegate = self
        categoryCarousel.type = .linear
        
        //self.groupAndFill(.vertical, views: [categoryLabel, categoryCarousel], padding: 4.0)
        categoryLabel.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: categoryLabel.frame.size.height)
        categoryCarousel.align(.underCentered, relativeTo: categoryLabel, padding: 0, width: categoryCarousel.frame.size.width, height: categoryCarousel.frame.size.height)

        update()
       
        // don't do anything until category list has been assigned
    }

    
    //MARK: - iCarousel required functions

    // TODO: pre-load images for initial display
    
    // number of items in list
    func numberOfItems(in carousel: iCarousel) -> Int {
        log.verbose("\(categoryList.count) items")
        return categoryList.count
    }
    
    
    // returns view for item at specific index
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        
        guard ((carousel != nil) && isValidIndex(index)) else {
            return UIView()
        }

        var label:UILabel
        
        //if (view != nil){
        //   label = view as! UILabel
        //} else {
            //label = UILabel()
            label = categoryViewList[index]
            label.textAlignment = .center
            label.textColor = UIColor.white
            label.backgroundColor = UIColor.black
            label.font = UIFont.boldSystemFont(ofSize: 16.0)
            label.frame.size.height = carouselHeight * 0.95
            label.frame.size.width = label.frame.size.height // square
            label.lineBreakMode = NSLineBreakMode.byWordWrapping
            label.numberOfLines = 0
        //}

        
        if (index < categoryList.count){
            label.text = categoryList[index].rawValue
        }
        
        return label
    }
    
    
    // set custom options
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        
        // spacing between items
        if (option == iCarouselOption.spacing){
            //return value * 1.1
            return value
        }
        
        // default
        return value
    }


    /* // don't use this as it will cause too many updates
     // called whenever an ite passes to/through the center spot
    func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
        let index = carousel.currentItemIndex
        log.debug("Selected: \(categoryList[index])")
    }
    */
    
    // called when an item is selected manually (i.e. touched).
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        updateSelection(carousel, index: index)
    }
    
    // called when user stops scrolling through list
    func carouselDidEndScrollingAnimation(_ carousel: iCarousel) {
        let index = carousel.currentItemIndex
 
        updateSelection(carousel, index: index)
    }

    
    func isValidIndex(_ index:Int)->Bool{
        return ((index>=0) && (index < categoryViewList.count) && (categoryViewList.count>0))
    }

    
    fileprivate func updateSelection(_ carousel: iCarousel, index: Int){
        
        guard ((carousel != nil) && isValidIndex(index)) else {
            return
        }

        if (index != currIndex){
            
            log.debug("Selected: \(categoryList[index]) (\(currIndex)->\(index))")

            // updates label colors of selected item, reset old selection
            if (isValidIndex(currIndex)){
                var oldView: UILabel? = nil
                oldView = categoryViewList[currIndex]
                //oldView.label.textColor = UIColor.white
                if (oldView != nil){
                    oldView?.textColor = UIColor.white
                    oldView?.layer.cornerRadius = 4.0
                    oldView?.layer.borderWidth = 1.0
                    oldView?.layer.borderColor = UIColor.black.cgColor
                }
            }
            
            let newView = categoryViewList[index]
            //newView.label.textColor = UIColor.flatLime()
            newView.textColor = UIColor.flatLime()
            newView.layer.cornerRadius = 4.0
            newView.layer.borderWidth = 1.0
            newView.layer.borderColor = UIColor.flatLime().cgColor
            
            // update current index
            currIndex = index
            
            filterManager?.setCurrentCategory(categoryList[index])
            
            
            // call delegate function to act on selection
            delegate?.categorySelected(categoryList[index])

        }
    }
    


}


