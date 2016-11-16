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
    func categorySelected(_ category:FilterManager.CategoryType)
}


class CategorySelectionView: UIView, iCarouselDelegate, iCarouselDataSource{

    var categoryCarousel:iCarousel = iCarousel()
    var filterManager: FilterManager? = FilterManager.sharedInstance
    var categoryList: [FilterManager.CategoryType] = []
    var categoryViewList: [UILabel] = []
    var currCategory:FilterManager.CategoryType = FilterManager.CategoryType.color
    var categoryLabel:UILabel = UILabel()
    var carouselHeight:CGFloat = 80.0
    var currIndex:Int = -1 // forces initialisation
    
    // delegate for handling events
    weak var delegate: CategorySelectionViewDelegate?

    //MARK: - Public accessors
    
    func setFilterCategory(_ category:FilterManager.CategoryType){
        if ((currCategory != category) || (currIndex<0)){
            currCategory = category
            log.debug("Filter category set to: \(category.rawValue)")
            update()
        } else {
            log.debug("Ignoring category \(category) change")
        }
    }
    
    func update(){
        //let newIndex = filterManager?.getCurrentCategory().getIndex()
        let newIndex = currCategory.getIndex()
        if (currIndex != newIndex){
            log.verbose("Scroll \(currIndex)->\(newIndex)")
            //categoryCarousel.scrollToItem(at: newIndex, animated: true)  // for some reason, animation causes a 'false' trigger at the end of the list
            categoryCarousel.scrollToItem(at: newIndex, animated: false)
            highlightSelection(categoryCarousel, index: newIndex)
            currIndex = newIndex
            //categoryCarousel.setNeedsLayout()
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
   
    fileprivate var initDone:Bool = false
    func doInit(){
        if (!initDone){
            carouselHeight = fmax((self.frame.size.height * 0.8), 80.0) // doesn't seem to work at less than 80 (empirical)
            //carouselHeight = self.frame.size.height * 0.82
            
            // Pre-allocate views for the filters, makes it much easier and we can update in the background if needed
            
            //setFilterCategory((filterManager?.getCurrentCategory())!)
            categoryList = (filterManager?.getCategoryList())!
            categoryViewList = []
            
            if (categoryList.count > 0){
                for _ in (0...categoryList.count-1) {
                    categoryViewList.append(UILabel())
                }
                
            }
            
            categoryLabel.text = "Categories"
            categoryLabel.textAlignment = .center
            categoryLabel.textColor = UIColor.white
            categoryLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
            categoryLabel.frame.size.height = carouselHeight * 0.18
            categoryLabel.frame.size.width = self.frame.size.width
            self.addSubview(categoryLabel)
           
            initDone = true
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
        //categoryCarousel.centerItemWhenSelected = true
        
        //self.groupAndFill(.vertical, views: [categoryLabel, categoryCarousel], padding: 4.0)
        categoryLabel.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: categoryLabel.frame.size.height)
        categoryCarousel.align(.underCentered, relativeTo: categoryLabel, padding: 0, width: categoryCarousel.frame.size.width, height: categoryCarousel.frame.size.height)

        //update()
       
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
        
        guard (isValidIndex(index)) else {
            return UIView()
        }
        
        var label:UILabel
        
        label = categoryViewList[index]
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.black
        label.font = UIFont.boldSystemFont(ofSize: 14.0)
        label.frame.size.height = carouselHeight * 0.95
        label.frame.size.width = label.frame.size.height // square
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 0
        
        if (index < categoryList.count){
            label.text = categoryList[index].rawValue
        }
        
        return label
    }
    
    
    // set custom options
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        
        // spacing between items
        if (option == iCarouselOption.spacing){
            return value * 1.1
            //return value
        } else if (option == iCarouselOption.wrap){
            //return value
            return 1.0
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
        highlightSelection(carousel, index: index)
        
        log.debug("Selected index:\(index)")
        currIndex = index
        // call delegate function to act on selection
        delegate?.categorySelected(categoryList[index])
    }
    
    // called when user stops scrolling through list
    func carouselDidEndScrollingAnimation(_ carousel: iCarousel) {
        let index = carousel.currentItemIndex
 
        log.debug("End scrolling at index:\(index)")
        //highlightSelection(carousel, index: index)
        
        // call delegate function to act on selection - debatable whether this is desirable or not...
        //delegate?.categorySelected(categoryList[index])
    }

    
    func isValidIndex(_ index:Int)->Bool{
        return ((index>=0) && (index < categoryViewList.count) && (categoryViewList.count>0))
    }

    
    fileprivate func highlightSelection(_ carousel: iCarousel, index: Int){
        
        guard (isValidIndex(index)) else {
            return
        }

        if (index != currIndex){
            
            log.debug("Highlight: \(categoryList[index]) (\(currIndex)->\(index))")

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
            //currIndex = index
            categoryCarousel.scrollToItem(at: index, animated: false)
           

        }
    }
    


}


