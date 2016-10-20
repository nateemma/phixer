//
//  FilterCarouselView.swift
//  FilterCam
//
//  Created by Philip Price on 10/18/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage

// A view that implements an iCarousel scrolling list for showing filters



// Interface required of controlling View
protocol FilterCarouselViewDelegate: class {
    func filterSelected(_ key:String)
}


class FilterCarouselView: UIView, iCarouselDelegate, iCarouselDataSource{

    var filterCarousel:iCarousel = iCarousel()
    var filterManager: FilterManager? = FilterManager.sharedInstance
    var filterNameList: [String] = []
    var filterViewList: [RenderContainerView] = []
    var filterCategory:FilterCategoryType = FilterCategoryType.quickSelect
    var filterLabel:UILabel = UILabel()
    var carouselHeight:CGFloat = 96.0
    var camera: Camera? = nil
    var currFilter: FilterDescriptorInterface? = nil
    var currIndex:Int = -1
    var cameraPreviewInput: PictureInput? = nil
    var previewURL: URL? = nil
    
    // delegate for handling events
    weak var delegate: FilterCarouselViewDelegate?

    //MARK: - Public accessors
    
    func setFilterCategory(_ category:FilterCategoryType){
        filterCategory = category
        filterNameList = (filterManager?.getFilterList(category))!
        filterNameList.sort(by: { (value1: String, value2: String) -> Bool in return value1 < value2 }) // sort ascending
        log.debug("Filter category set to: \(category.rawValue)")
        
        // Pre-allocate views for the filters, makes it much easier and we can update in the background if needed
        filterViewList = []
        for i in (0...filterNameList.count-1) {
            filterViewList.append(createFilterContainerView((filterManager?.getFilterDescriptor(category, name:filterNameList[i]))!))
        }
        
        //updateVisibleItems()
        
        filterCarousel.setNeedsLayout()
    }
    
    func update(){
        updateVisibleItems()
    }
    
    func getCurrentSelection()->String{
        guard ((filterNameList.count>0) && (currIndex<filterNameList.count) && (currIndex>=0)) else {
            return ""
        }
        
        return filterNameList[currIndex]
    }
    
    
    private func createFilterContainerView(_ descriptor: FilterDescriptorInterface) -> RenderContainerView{
        var view:RenderContainerView = RenderContainerView()
        view.frame.size = CGSize(width:carouselHeight, height:carouselHeight)
        view.label.text = descriptor.key
        
        //TODO: start rendering in an asynch queue
        
        return view
    }
    
    //MARK: - UIView required functions
    convenience init(){
        self.init(frame: CGRect.zero)
        
        camera = CameraManager.getCamera()!

        carouselHeight = fmax((self.frame.size.height * 0.8), 80.0)
        
        
        filterLabel.textAlignment = .center
        filterLabel.textColor = UIColor.white
        filterLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
        filterLabel.frame.size.height = carouselHeight * 0.25
        self.addSubview(filterLabel)
    }

    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        filterCarousel.frame = self.frame
        self.addSubview(filterCarousel)
        filterCarousel.fillSuperview()
        
        filterCarousel.dataSource = self
        filterCarousel.delegate = self
        filterCarousel.type = .rotary
        
        self.groupAndFill(.vertical, views: [filterLabel, filterCarousel], padding: 4.0)
        
        //updateVisibleItems()
       
        // don't do anything until filter list has been assigned
    }

    
    //MARK: - iCarousel reequired functions

    // TODO: pre-load images for initial display
    
    // number of items in list
    func numberOfItems(in carousel: iCarousel) -> Int {
        log.verbose("\(filterNameList.count) items")
        return filterNameList.count
    }
    
    
    // returns view for item at specific index
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        
        if (cameraPreviewInput == nil){
            do {
                let documentsDir = try FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
                previewURL = URL(string:"FilterCamImage.png", relativeTo:documentsDir)
                let image = UIImage(contentsOfFile: (previewURL?.path)!)
                cameraPreviewInput = PictureInput(image:image!)
            } catch {
                log.error("Error rendering view: \(error)")
            }
        }

        if (index < filterNameList.count){
            if (camera != nil){
                do{
                    
                    currFilter = filterManager?.getFilterDescriptor(filterCategory, name:filterNameList[index])
                    //tempView.label.text = currFilter?.key
                    let filter = currFilter?.filter
                    if (filter != nil){
                        
                        camera! --> filter! --> filterViewList[index].renderView!
/***
                         let image = UIImage(contentsOfFile: (self.previewURL?.path)!)
                         self.cameraPreviewInput = PictureInput(image:image!)
                        if (cameraPreviewInput != nil){
                            cameraPreviewInput!  --> filter! --> self.filterViewList[index].renderView!
                            cameraPreviewInput?.processImage()
                        } else {
                            log.error("ERR: cameraPreviewInput not set up")
                        }
 ***/
                        
                    } else {
                        let filterGroup = currFilter?.filterGroup
                        if (filterGroup != nil){
                            camera! --> filterGroup! --> filterViewList[index].renderView!
                        }
                    }
                } catch {
                    log.error("Error rendering view: \(error)")
                }
            }
        }
        
//        return tempView
        return filterViewList[index]
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
        log.debug("Selected: \(filterNameList[index])")
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
    
    fileprivate func updateSelection(_ carousel: iCarousel, index: Int){
        if (index != currIndex){
            log.debug("Selected: \(filterNameList[index])")
            //filterLabel.text = filterNameList[index]
            currFilter = filterManager?.getFilterDescriptor(.quickSelect, name:filterNameList[index])
            filterLabel.text = currFilter?.title
            
            // updates label colors of selected item, reset old selection
            if ((currIndex != index) && (currIndex>=0)){
                let oldView = filterViewList[currIndex]
                oldView.label.textColor = UIColor.white
            }
            
            let newView = filterViewList[index]
            if (newView != nil){
                newView.label.textColor = UIColor.flatLime()
            }
            
            // call delegate function to act on selection
            delegate?.filterSelected(filterNameList[index])
            
            // update current index
            currIndex = index
            /***
             //TODO: instead of live filter, just get current image from the camera and apply filters to that?
             do{
             if (previewURL != nil){
             camera?.saveNextFrameToURL(previewURL!, format:.png)
             /***
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
             let image = UIImage(contentsOfFile: (self.previewURL?.path)!)
             self.cameraPreviewInput = PictureInput(image:image!)}
             ***/
             } else {
             log.error("ERR: cameraPreviewInput not set up")
             }
             } catch {
             log.error("Error saving image: \(error)")
             }
             ***/
        }
    }
    
    private func updateVisibleItems(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            var index:Int
            var descriptor:FilterDescriptorInterface
            log.verbose("Updating...")
            for i in self.filterCarousel.indexesForVisibleItems {
                if (self.camera != nil){
                    do{
                        index = i as! Int
                        descriptor = (self.filterManager?.getFilterDescriptor(self.filterCategory, name:self.filterNameList[index]))!
                        //tempView.label.text = currFilter?.key
                        let filter = descriptor.filter
                        if (filter != nil){
                            //log.verbose("updating index:\(index) (\(descriptor.key))")
                            //TODO: apply rotation filter
                            self.camera! --> filter! --> self.filterViewList[index].renderView!
                            
                        } else {
                            let filterGroup = self.currFilter?.filterGroup
                            if (filterGroup != nil){
                                //TODO: apply rotation filter
                                self.camera! --> filterGroup! --> self.filterViewList[index].renderView!
                            }
                        }
                    } catch {
                        log.error("Error rendering view: \(error)")
                    }
                }
            }
            self.filterCarousel.setNeedsLayout()
        }
        
    }

}


