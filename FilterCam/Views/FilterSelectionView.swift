//
//  FilterSelectionView.swift
//  FilterCam
//
//  Created by Philip Price on 10/18/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage

// A view that implements an iCarousel scrolling list for showing filters



// Interface required of controlling View
protocol FilterSelectionViewDelegate: class {
    func filterSelected(_ key:String)
}


class FilterSelectionView: UIView, iCarouselDelegate, iCarouselDataSource{

    fileprivate var initDone:Bool = false
    fileprivate var filterCarousel:iCarousel? = iCarousel()
    fileprivate var filterManager: FilterManager? = FilterManager.sharedInstance
    fileprivate var filterNameList: [String] = []
    fileprivate var filterViewList: [RenderContainerView] = []
    fileprivate var filterCategory:String = FilterManager.defaultCategory
    fileprivate var filterLabel:UILabel = UILabel()
    fileprivate var carouselHeight:CGFloat = 80.0
    fileprivate var camera: Camera? = nil
    fileprivate var currFilter: FilterDescriptorInterface? = nil
    fileprivate var opacityFilter:OpacityAdjustment? = nil
    
    fileprivate var blendImageFull:UIImage? = nil
    fileprivate var blend:PictureInput? = nil

    fileprivate var sampleImageFull:UIImage? = nil
    fileprivate var sampleImageSmall:UIImage? = nil
    fileprivate var sampleInput:PictureInput? = nil

    fileprivate var previewInput: ImageSource? = nil
    
    fileprivate var currIndex:Int = -1
    //fileprivate var cameraPreviewInput: PictureInput? = nil
    //fileprivate var previewURL: URL? = nil
    
    // delegate for handling events
    weak var delegate: FilterSelectionViewDelegate?

    ///////////////////////////////////
    //MARK: - Public accessors
    ///////////////////////////////////
    
    func setFilterCategory(_ category:String){
        
        if ((category != filterCategory) || (currIndex<0)){
            
            log.debug("Filter category set to: \(category)")
            
            
            filterCategory = category
            //filterNameList = (filterManager?.getFilterList(category))!
            filterNameList = (filterManager?.getShownFilterList(category))!
            //filterNameList.sort(by: { (value1: String, value2: String) -> Bool in return value1 < value2 }) // sort ascending
            log.verbose("(\(category)) Found: \(filterNameList.count) filters")
            
            // need to clear everything from carousel, so just create a new one...
            filterCarousel?.removeFromSuperview()
            filterCarousel = iCarousel()
            filterCarousel?.frame = self.frame
            self.addSubview(filterCarousel!)
            
            filterCarousel?.dataSource = self
            filterCarousel?.delegate = self
            
            // Pre-allocate views for the filters, makes it much easier and we can update in the background if needed
            filterViewList = []
            
            var descriptor: FilterDescriptorInterface?
            if (filterNameList.count > 0){
                for i in (0...filterNameList.count-1) {
                    descriptor = filterManager?.getFilterDescriptor(key:filterNameList[i])
                    if (descriptor != nil){
                        if !((filterManager?.isHidden(key: filterNameList[i]))!){
                            filterViewList.append(createFilterContainerView((descriptor)!))
                        } else {
                            log.debug("Not showing filter: \(String(describing: descriptor?.key))")
                        }
                    } else {
                        log.error("NIL Descriptor for:\(filterNameList[i])")
                    }
                }
                
                updateVisibleItems()
                
                filterCarousel?.setNeedsLayout()
            } else {
                
                filterCarousel?.removeFromSuperview()
                
            }
        } else {
            //log.verbose("Ignored \(category)->\(filterCategory) change")
        }
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
        let view:RenderContainerView = RenderContainerView()
        view.frame.size = CGSize(width:carouselHeight, height:carouselHeight)
        view.label.text = descriptor.key
        
        //TODO: start rendering in an asynch queue
        
        return view
    }
    
    ///////////////////////////////////
    //MARK: - UIView required functions
    ///////////////////////////////////
    convenience init(){
        self.init(frame: CGRect.zero)

        initDone = false

        carouselHeight = fmax((self.frame.size.height * 0.8), 80.0) // doesn't seem to work at less than 80 (empirical)
        //carouselHeight = self.frame.size.height * 0.82
        
        
        // register for change notifications (don't do this before the views are set up)
        //filterManager?.setCategoryChangeNotification(callback: categoryChanged())

    }

    
    
    deinit {
        suspend()
    }
    
    
    
    func layoutViews(){
        
        if (!self.initDone){
            initDone = true
            //DispatchQueue.main.async(execute: { () -> Void in
            self.camera = CameraManager.getCamera()
            
            // load the blend and sample images (assuming they cannot change while this view is displayed)
            self.blendImageFull  = ImageManager.getCurrentBlendImage()
            //self.blendImageFull  = ImageManager.getCurrentBlendImage(size:CGSize(width: (self.filterCarousel?.frame.size.width)!, height: (self.filterCarousel?.frame.size.height)!))
            if (self.blendImageFull != nil){
                self.blend = PictureInput(image:self.blendImageFull!)
            }
            
            self.sampleInput=nil
            self.sampleImageFull = ImageManager.getCurrentSampleImage()
            //self.sampleImageFull = ImageManager.getCurrentSampleImage(size:CGSize(width: (self.filterCarousel?.frame.size.width)!, height: (self.filterCarousel?.frame.size.height)!))
            //let size = (self.sampleImageFull?.size.applying(CGAffineTransform(scaleX: 0.2, y: 0.2)))!
            //self.sampleImageSmall = ImageManager.scaleImage(self.sampleImageFull, widthRatio: 0.2, heightRatio: 0.2)
            //self.sampleInput = PictureInput(image:self.sampleImageSmall!)
            if (self.sampleImageFull != nil){
                self.sampleInput = PictureInput(image:self.sampleImageFull!)
            }
            
            if (self.sampleInput==nil){
                log.error("ERR: Sample input not created")
            }
            
            // reduce opacity of blends by default
            if (self.opacityFilter == nil){
                self.opacityFilter = OpacityAdjustment()
                self.opacityFilter?.opacity = 0.8
            }
            //})
        }
     
        
        filterLabel.text = ""
        filterLabel.textAlignment = .center
        //filterLabel.textColor = UIColor.white
        filterLabel.textColor = UIColor.lightGray
        filterLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
        filterLabel.frame.size.height = carouselHeight * 0.18
        filterLabel.frame.size.width = self.frame.size.width
        self.addSubview(filterLabel)

        filterCarousel?.frame = self.frame
        self.addSubview(filterCarousel!)
        //filterCarousel?.fillSuperview()
        filterCarousel?.dataSource = self
        filterCarousel?.delegate = self
        
        //filterCarousel?.type = .rotary
        filterCarousel?.type = .linear
        
        //self.groupAndFill(.vertical, views: [filterLabel, filterCarousel], padding: 4.0)
        filterLabel.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: filterLabel.frame.size.height)
        filterCarousel?.align(.underCentered, relativeTo: filterLabel, padding: 0, width: (filterCarousel?.frame.size.width)!, height: (filterCarousel?.frame.size.height)!)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutViews()
        
        //updateVisibleItems()
       
        // don't do anything until filter list has been assigned
    }

    
    ///////////////////////////////////
    //MARK: - iCarousel reequired functions
    ///////////////////////////////////

    // TODO: pre-load images for initial display
    
    // number of items in list
    func numberOfItems(in carousel: iCarousel) -> Int {
        log.verbose("\(filterNameList.count) items")
        return filterNameList.count
    }
    
    
    // returns view for item at specific index
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        
/***
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
 ***/

        if ((index < filterViewList.count) && (index>=0)){
            
            // set the input to be either the camera or the current sample image
            // We do this so that something is displayed when running on the simulator (no camera available)
            
            if (camera == nil){
                previewInput = sampleInput
                log.debug("Using Sample image instead of camera")
            } else {
                previewInput = camera
            }
            
            if (previewInput != nil){
                filterCategory = (filterManager?.getCurrentCategory())!
                currFilter = filterManager?.getFilterDescriptor(key:filterNameList[index])
                
                if (currFilter?.filter != nil){
                    
                    let filter = currFilter?.filter
                    let opType = currFilter?.filterOperationType // wierd Swift unwrapping problem, can't use filterOperationType directly in switch
                    switch (opType!){
                    case .singleInput:
                        log.debug("Using filter: \(String(describing: currFilter?.key))")
                        self.previewInput! --> filter! --> self.filterViewList[index].renderView!
                        if (camera == nil){ self.sampleInput?.processImage(synchronously: true) } // need extra call for static picture
                        break
                    case .blend:
                        log.debug("Using BLEND mode for filter: \(String(describing: currFilter?.key))")
                        self.previewInput!.addTarget(filter!)
                        self.blend! --> self.opacityFilter! --> filter!
                        self.previewInput! --> filter! --> self.filterViewList[index].renderView!
                        self.blend?.processImage()
                        if (camera == nil){ self.sampleInput?.processImage(synchronously: true) }
                        break
                    }
                    
                } else if (currFilter?.filterGroup != nil){
                    let filterGroup = currFilter?.filterGroup
                    
                    log.debug("Run filterGroup: \(String(describing: currFilter?.key)) address:\(Utilities.addressOf(filterGroup))")
                    
                    let opType:FilterOperationType = (currFilter?.filterOperationType)!
                    switch (opType){
                    case .singleInput:
                        log.debug("filterGroup: \(String(describing: currFilter?.key))")
                        self.previewInput! --> filterGroup! --> self.filterViewList[index].renderView!
                        if (camera == nil){ self.sampleInput?.processImage(synchronously: true) }
                        break
                    case .blend:
                        //log.debug("Using BLEND mode for group: \(currFilterDescriptor?.key)")
                        self.previewInput!.addTarget(filterGroup!)
                        self.blend! --> self.opacityFilter! --> filterGroup!
                        self.previewInput! --> filterGroup! --> self.filterViewList[index].renderView!
                        self.blend?.processImage()
                        if (camera == nil){ self.sampleInput?.processImage(synchronously: true) }
                        break
                    }
                } else {
                    log.error("!!! Filter (\(String(describing: currFilter?.key)) has no operation assigned !!!")
                }
  
                return filterViewList[index]
            } else {
                log.error("ERR: No input available")
            }
        }
        return UIView()
//        return tempView
    }
    
    
    // set custom options
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        
        // spacing between items
        if (option == iCarouselOption.spacing){
            //return value * 1.1
            return value
        } else if (option == iCarouselOption.wrap){
            return 1.0
        }
        
        // default
        return value
    }


    /* // don't use this as it will cause too many updates
     // called whenever an item passes to/through the center spot
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
    
    // utility function to check that an index is (still) valid. 
    // Needed because the underlying filter list can can change asynchronously from the iCarousel background processing
    func isValidIndex(_ index:Int)->Bool{
        return ((index>=0) && (index < filterNameList.count) && (filterNameList.count>0))
        //return ((index>=0) && (index < filterViewList.count) && (filterViewList.count>0))
    }
    
    fileprivate func updateSelection(_ carousel: iCarousel, index: Int){
        
        // Note that the Filter Category can change in the middle of an update, so be careful with indexes
        
        /***
        guard (index != currIndex) else {
            //log.debug("Index did not change (\(currIndex)->\(index))")
            return
        }
        ***/
        
        guard (isValidIndex(index)) else {
            log.debug("Invalid index: \(index)")
            return
        }
        
        log.debug("Selected: \(filterNameList[index])")
        filterCategory = (filterManager?.getCurrentCategory())!
        currFilter = filterManager?.getFilterDescriptor(key:filterNameList[index])
        filterLabel.text = currFilter?.title
        
        // updates label colors of selected item, reset old selection
        if ((currIndex != index) && isValidIndex(index) && isValidIndex(currIndex)){
            let oldView = filterViewList[currIndex]
            oldView.label.textColor = UIColor.white
        }
        
        let newView = filterViewList[index]
        newView.label.textColor = UIColor.flatLime
        
        //filterManager?.setCurrentFilterKey(filterNameList[index])
        
        
        // call delegate function to act on selection
        if (index != currIndex) {
            delegate?.filterSelected(filterNameList[index])
        }
        
        
        // update current index
        currIndex = index
    }
 
    // suspend all GPUImage-related processing
    open func suspend(){
        var descriptor:FilterDescriptorInterface?
        for key in filterNameList {
            descriptor = (self.filterManager?.getFilterDescriptor(key: key))
            log.verbose("Suspending \(key)...")
            opacityFilter?.removeAllTargets()
            blend?.removeAllTargets()
            descriptor?.filter?.removeAllTargets()
            descriptor?.filterGroup?.removeAllTargets()
        }
        blend?.removeAllTargets()
        opacityFilter?.removeAllTargets()
        //filterNameList = []
        //currIndex = -1
    }
    
    
    private func updateVisibleItems(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            var index:Int
            var descriptor:FilterDescriptorInterface?
            


            log.verbose("Updating...")
            for i in (self.filterCarousel?.indexesForVisibleItems)! {
                if (self.camera != nil){
                    index = i as! Int
                    if (self.isValidIndex(index)){ // filterNameList can change asynchronously
                        descriptor = (self.filterManager?.getFilterDescriptor(key:self.filterNameList[index]))
                        
                        if (descriptor?.filter != nil){

                            let filter = descriptor?.filter
                            let opType = descriptor?.filterOperationType // wierd Swift unwrapping problem, can't use filterOperationType directly in switch
                            switch (opType!){
                            case .singleInput:
                                log.debug("Using filter: \(String(describing: descriptor?.key))")
                                self.camera! --> filter! --> self.filterViewList[index].renderView!
                                break
                            case .blend:
                                log.debug("Using BLEND mode for filter: \(String(describing: descriptor?.key))")
                                //TOFIX: blend image needs to be resized to fit the render view
                                self.camera!.addTarget(filter!)
                                self.blend! --> self.opacityFilter! --> filter!
                                self.camera! --> filter! --> self.filterViewList[index].renderView!
                                self.blend?.processImage()
                                break
                            }
                            
                        } else if (descriptor?.filterGroup != nil){
                            let filterGroup = descriptor?.filterGroup

                            log.debug("Run filterGroup: \(String(describing: descriptor?.key)) address:\(Utilities.addressOf(filterGroup))")
                            
                            let opType:FilterOperationType = (descriptor?.filterOperationType)!
                            switch (opType){
                            case .singleInput:
                                log.debug("filterGroup: \(String(describing: descriptor?.key))")
                                self.camera! --> filterGroup! --> self.filterViewList[index].renderView!
                                break
                            case .blend:
                                //log.debug("Using BLEND mode for group: \(currFilterDescriptor?.key)")
                                //TOFIX: blend image needs to be resized to fit the render view
                                self.camera!.addTarget(filterGroup!)
                                self.blend! --> self.opacityFilter! --> filterGroup!
                                self.camera! --> filterGroup! --> self.filterViewList[index].renderView!
                                self.blend?.processImage()
                                break
                            }
                        } else {
                            log.error("!!! Filter (\(String(describing: descriptor?.key)) has no operation assigned !!!")
                        }
                    }
                }
            }
            //self.filterCarousel?.setNeedsLayout()
        }
        
    }
    
    
    
    ///////////////////////////////////
    //MARK: - Callbacks
    ///////////////////////////////////
    
    
    func categoryChanged(){
        log.debug("category changed")
        setFilterCategory((filterManager?.getCurrentCategory())!)
    }

}


