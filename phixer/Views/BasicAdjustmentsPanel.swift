//
//  BasicAdjustmentView.swift
//  Philter
//
//  Created by Philip Price on 9/19/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import UIKit
import Neon
import Photos
import iCarousel


// Interface required of controlling View
protocol BasicAdjustmentViewDelegate: class {
    func brightnessPressed()
    func exposurePressed()
    func contrastPressed()
    func shadowsPressed()
    func highlightsPressed()
}

// Class responsible for laying out the controls for the Edit Picture control strip



class BasicAdjustmentView: UIView, iCarouselDelegate, iCarouselDataSource{
    
    var theme = ThemeManager.currentTheme()
    

    fileprivate var initDone:Bool = false
    fileprivate var controlCarousel:iCarousel? = iCarousel()
    
    // the list of controls
    fileprivate var controlNameList: [String] = [ "brightness", "exposure", "contrast", "shadows", "highlights" ]
    
    // the assets for each control
    fileprivate var controlAssetList: [String] = [ "ic_brightness", "ic_exposure", "ic_contrast", "ic_shadow", "ic_highlights" ]
    
    // the display views for each control
    fileprivate var controlViewList: [ImageContainerView] = []
    
    fileprivate var controlLabel:UILabel = UILabel()
    //fileprivate var carouselHeight:CGFloat = 80.0
    fileprivate var carouselHeight:CGFloat = 80.0
    
    fileprivate var currIndex:Int = -1
    
    // delegate for handling events
    weak var delegate: BasicAdjustmentViewDelegate?
    
    ///////////////////////////////////
    //MARK: - Public accessors
    ///////////////////////////////////
    
    
    func update(){
        //TODO
    }
    
    func getCurrentSelection()->String{
        guard ((controlNameList.count>0) && (currIndex<controlNameList.count) && (currIndex>=0)) else {
            return "?"
        }
        
        return controlNameList[currIndex]
    }
    
    
    
    // build a view based on the label and icon
    private func createContainerView(icon:String, label:String) -> ImageContainerView{
        let view:ImageContainerView = ImageContainerView()
        view.frame.size = CGSize(width:carouselHeight, height:carouselHeight)
        view.imageView.frame.size = CGSize(width:carouselHeight*0.8, height:carouselHeight*0.8)
        
        view.label.frame.size = CGSize(width:carouselHeight, height:carouselHeight*0.2)
        
        view.label.font = UIFont.systemFont(ofSize: 8.0)
        view.label.text = label
        view.label.textColor = theme.tintColor
        
        view.imageView.contentMode = .scaleAspectFit
        var image = UIImage(named: icon)
        if (image == nil){
            log.warning("icon not found: \(icon)")
            image = UIImage(named:"ic_unknown")
        }
        let tintableImage = image!.withRenderingMode(.alwaysTemplate)
        view.imageView.image = tintableImage
        //view.imageView.tintColor =  UIColor(contrastingBlackOrWhiteColorOn:theme.backgroundColor, isFlat:true)
        view.imageView.tintColor =  theme.tintColor

        view.imageView.backgroundColor = theme.backgroundColor
        view.layer.borderColor = theme.tintColor.cgColor
        
        return view
    }
    
    ///////////////////////////////////
    //MARK: - UIView required functions
    ///////////////////////////////////
    convenience init(){
        self.init(frame: CGRect.zero)
        
        initDone = false
        
        //carouselHeight = fmax((self.frame.size.height * 0.8), 80.0) // doesn't seem to work at less than 80 (empirical)

        
    }
    
    
    
    deinit {
        //TODO
    }
    
    
    
    func layoutViews(){
  
        //carouselHeight = fmax((self.frame.size.height * 0.8), 48.0) // doesn't seem to work at less than 80 (empirical)
        carouselHeight = self.frame.size.height * 0.7
        
        controlLabel.text = ""
        controlLabel.textAlignment = .center
        //controlLabel.textColor = theme.titleTextColor
        controlLabel.textColor = theme.textColor
        //controlLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
        controlLabel.font = UIFont.boldSystemFont(ofSize: 12.0)
        controlLabel.frame.size.height = carouselHeight * 0.3
        controlLabel.frame.size.width = self.frame.size.width
        self.addSubview(controlLabel)
        
        //controlCarousel?.frame = self.frame
        controlCarousel?.frame.size.height = carouselHeight
        controlCarousel?.frame.size.width = self.frame.size.width

        self.addSubview(controlCarousel!)
        //controlCarousel?.fillSuperview()
        controlCarousel?.dataSource = self
        controlCarousel?.delegate = self
        
        //controlCarousel?.type = .rotary
        controlCarousel?.type = .linear
        
        //self.groupAndFill(.vertical, views: [controlLabel, controlCarousel], padding: 4.0)
        controlLabel.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: controlLabel.frame.size.height)
        controlCarousel?.align(.underCentered, relativeTo: controlLabel, padding: 0, width: (controlCarousel?.frame.size.width)!, height: (controlCarousel?.frame.size.height)!)

        
        // populate the views. Only do this after views have been set up
        setupViews()

        

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutViews()
        
        //updateVisibleItems()
        
        // don't do anything until control list has been assigned
    }
    
    fileprivate func setupViews(){
        if (!self.initDone){
            self.initDone = true
            
            // create the views for each control
            for i in 0...(controlNameList.count-1){
                controlViewList.append(createContainerView(icon: controlAssetList[i], label: controlNameList[i]))
            }
        }
    }

    ///////////////////////////////////
    //MARK: - iCarousel reequired functions
    ///////////////////////////////////
    
    // TODO: pre-load images for initial display
    
    // number of items in list
    func numberOfItems(in carousel: iCarousel) -> Int {
        log.verbose("\(controlNameList.count) items")
        return controlNameList.count
    }
    
    
    // returns view for item at specific index
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        
        
        setupViews() // just in case
        
        if (isValidIndex(index)){
            return controlViewList[index]
        } else {
            return UIView()
        }
        
        
    }
    
    
    // set custom options
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        
        // spacing between items
        if (option == iCarouselOption.spacing){
            //return value * 1.1
            return value
        } else if (option == iCarouselOption.wrap){
            return 1.0
            //return 0.0
        }
        
        // default
        return value
    }
    
    
    /* // don't use this as it will cause too many updates
     // called whenever an item passes to/through the center spot
     func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
     let index = carousel.currentItemIndex
     log.debug("Selected: \(controlNameList[index])")
     }
     */
    
    // called when an item is selected manually (i.e. touched).
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        updateSelection(carousel, index: index)
    }
   
    
    /***
    // called when user stops scrolling through list
    func carouselDidEndScrollingAnimation(_ carousel: iCarousel) {
        let index = carousel.currentItemIndex
        
        updateSelection(carousel, index: index)
    }
    ***/
    
    
    // utility function to check that an index is (still) valid.
    // Needed because the underlying control list can can change asynchronously from the iCarousel background processing
    func isValidIndex(_ index:Int)->Bool{
        return ((index>=0) && (index < controlNameList.count) && (controlNameList.count>0))
    }
    
    fileprivate func updateSelection(_ carousel: iCarousel, index: Int){
        
        
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
        
        log.debug("Selected: \(controlNameList[index])")
        controlLabel.text = controlNameList[index]
        
        // updates label colors of selected item, reset old selection
        if ((currIndex != index) && isValidIndex(index) && isValidIndex(currIndex)){
            let oldView = controlViewList[currIndex]
            oldView.label.textColor = theme.textColor
            oldView.layer.borderColor = theme.secondaryColor.cgColor

        }
        
        let newView = controlViewList[index]
        newView.label.textColor = theme.highlightColor
        newView.layer.borderColor = theme.highlightColor.cgColor
        
        //controlManager?.setCurrentFilterKey(controlNameList[index])
        
        
        // call delegate function to act on selection
        //if (index != currIndex) {
            handlePress(index: index)
        //}
        
        
        // update current index
        currIndex = index
    }
    
    
    /////////////////////////////////
    //MARK: - touch handlers
    /////////////////////////////////
    
    
    func handlePress(index:Int) {

        guard (isValidIndex(index)) else {
            log.error("Invalid index: \(index)")
            return
        }
        
        log.verbose("Pressed: \(controlNameList[index])")
        
        switch (index){
        case 0:
            log.verbose("brightness selected")
        case 2:
            log.verbose("exposure selected")
        case 3:
            log.verbose("contrast selected")
        case 4:
            log.verbose("shadows selected")
        case 5:
            log.verbose("highlights selected")
        default:
            log.error("Invalid index:\(index)")
            break
            
        }
    }


}
