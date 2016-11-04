//
//  FilterGalleryViewController.swift
//  FilterCam
//
//  ViewController that provides a gallery view with previews of each filter, organised into Categories
//
//  Created by Philip Price on 10/31/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import GPUImage
import Neon
import GoogleMobileAds


// delegate method to let the launcing ViewController know that this one has finished
protocol FilterGalleryViewControllerDelegate: class {
    func onCompletion()
}


class FilterGalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    
    // delegate for handling events
    weak var delegate: FilterGalleryViewControllerDelegate?
    
    
    private var bannerView: UIView! = UIView()
    fileprivate var galleryView: UICollectionView!
    fileprivate var galleryViewLayout = UICollectionViewFlowLayout()
    
    
    // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    var showAds : Bool = true
    
    // Category Selection View
    var categorySelectionView: CategorySelectionView!
    
    
    private var filterList: [String] = []
    fileprivate var renderList:[RenderView] = []
    
    private var isLandscape : Bool = false
    private var screenSize : CGRect = CGRect.zero
    private var displayWidth : CGFloat = 0.0
    private var displayHeight : CGFloat = 0.0
    
    private let bannerHeight : CGFloat = 64.0
    private let buttonSize : CGFloat = 48.0
    private let statusBarOffset : CGFloat = 12.0
    
    private var itemsPerRow: CGFloat = 3
    private var cellSpacing: CGFloat = 2
    private var indicatorWidth: CGFloat = 41
    private var indicatorHeight: CGFloat = 8
    
    private let leftOffset: CGFloat = 11
    private let rightOffset: CGFloat = 7
    private let height: CGFloat = 34
    
    fileprivate let sectionInsets = UIEdgeInsets(top: 11.0, left: 10.0, bottom: 11.0, right: 10.0)
    
    
    fileprivate var currCategory: FilterManager.CategoryType = FilterManager.CategoryType.quickSelect
    fileprivate var filterManager:FilterManager = FilterManager.sharedInstance
    
    //let layout = UICollectionViewFlowLayout()
    
    
    ////////////////////////////////////////////
    // MARK: - View Lifecycle
    ////////////////////////////////////////////
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currCategory = filterManager.getCurrentCategory()
        doInit()
    }
    
    func doInit(){
        isLandscape = UIDevice.current.orientation.isLandscape
        displayHeight = view.height
        displayWidth = view.width
        log.verbose("h:\(displayHeight) w:\(displayWidth) landscape:\(isLandscape)")
        
        
        initGalleryItems()
        
        layoutViews()
        
        // start Ads
        if (showAds){
            initAds()
        }
        
        initCategorySelector()
        
        galleryView.reloadData()
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if UIDevice.current.orientation.isLandscape{
            log.verbose("### Detected change to: Landscape")
            isLandscape = true
        } else {
            log.verbose("### Detected change to: Portrait")
            isLandscape = false
            
        }
        //TODO: animate and maybe handle before rotation finishes
        removeSubviews()
        layoutViews()
        
    }
    
    fileprivate func initGalleryItems() {
        galleryView = UICollectionView(frame: CGRect.zero, collectionViewLayout: galleryViewLayout)
        galleryView?.delegate   = self
        galleryView?.dataSource = self
        galleryView?.register(FilterGalleryViewCell2.self, forCellWithReuseIdentifier: FilterGalleryViewCell.reuseID)
        
        filterList = filterManager.getFilterList(currCategory)!
        log.debug("Filters: \(filterList)")
        
        // create list of RenderView objects to match filter list
        self.renderList = []
        for _ in 0...(filterList.count-1) {
            renderList.append(RenderView())
        }
        
    }
    
    fileprivate func initCategorySelector(){
        categorySelectionView.delegate = self
        categorySelectionView.setFilterCategory(currCategory)
    }
    
    
    // suspend all active processing. Need to do this before transitioning to another View Controller
    func suspend(){
        let indexPath = galleryView.indexPathsForVisibleItems
        var cell: FilterGalleryViewCell2?
        for index in indexPath{
            cell = galleryView.cellForItem(at: index) as! FilterGalleryViewCell2?
            cell?.suspend()
        }
        //filterList = []
    }
    
    
    
    ////////////////////////////////////////////
    // MARK: - View Layout
    ////////////////////////////////////////////
    
    fileprivate func layoutViews(){
        
        
        showAds = (isLandscape == true) ? false : true // don't show in landscape mode (too cluttered)
        
        if (isLandscape){
            itemsPerRow = 4
            showAds = false
        } else {
            itemsPerRow = 3
            showAds = true
        }
        
        view.backgroundColor = UIColor.black // default seems to be white
        
        layoutBanner()
        
        layoutGallery()
        
        // Note: need to add subviews before modifying constraints
        if (showAds){
            adView.frame.size.height = bannerHeight
            adView.frame.size.width = displayWidth
            adView.isHidden = false
            view.addSubview(adView)
        } else {
            log.debug("Not showing Ads in landscape mode")
            adView.frame.size.height = 0
            adView.isHidden = true
            //adView.removeFromSuperview()
        }
        
        
        categorySelectionView = CategorySelectionView()
        
        categorySelectionView.frame.size.height = 1.5 * bannerHeight
        categorySelectionView.frame.size.width = displayWidth
        categorySelectionView.backgroundColor = UIColor.black
        view.addSubview(categorySelectionView)
        
        
        // Assign layout constraints
        bannerView.anchorAndFillEdge(.top, xPad: 0, yPad: 8.0, otherSize: bannerView.frame.size.height)
        if (showAds){
            adView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: adView.frame.size.height)
        }
        categorySelectionView.align(.aboveCentered, relativeTo: galleryView, padding: 0, width: displayWidth, height: categorySelectionView.frame.size.height)
        
    }
    
    
    // Banner View (title)
    private var backButton:UIButton! = UIButton()
    private var titleLabel:UILabel! = UILabel()
    
    fileprivate func layoutBanner(){
        
        bannerView.frame.size.height = bannerHeight * 0.75
        bannerView.frame.size.width = displayWidth
        bannerView.backgroundColor = UIColor.black
        
        bannerView.addSubview(backButton)
        bannerView.addSubview(titleLabel)
        
        backButton.frame.size.height = bannerView.frame.size.height - 8
        backButton.frame.size.width = 2.0 * backButton.frame.size.height
        backButton.setTitle("< Back", for: .normal)
        backButton.backgroundColor = UIColor.flatMint()
        backButton.setTitleColor(UIColor.white, for: .normal)
        backButton.titleLabel!.font = UIFont.boldSystemFont(ofSize: 20.0)
        backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
        
        titleLabel.frame.size.height = backButton.frame.size.height
        titleLabel.frame.size.width = view.width - backButton.frame.size.width
        titleLabel.text = "Filter Gallery"
        titleLabel.backgroundColor = UIColor.black
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
        titleLabel.textAlignment = .center
        
        
        backButton.anchorInCorner(.bottomLeft, xPad: 4, yPad: 4, width: backButton.frame.size.width, height: backButton.frame.size.height)
        titleLabel.align(.toTheRightCentered, relativeTo: backButton, padding: 0, width: titleLabel.frame.size.width, height: titleLabel.frame.size.height)
        
        backButton.addTarget(self, action: #selector(self.backDidPress), for: .touchUpInside)
        
        view.addSubview(bannerView)
    }
    
    
    
    func layoutGallery(){
        galleryView.frame.size.width = view.frame.size.width
        if (showAds){
            galleryView.frame.size.height = view.frame.size.height - 3.25 * bannerHeight
        } else {
            galleryView.frame.size.height = view.frame.size.height - 2.25 * bannerHeight
        }
        view.addSubview(galleryView)
        galleryView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: galleryView.frame.size.height)
    }
    
    fileprivate func removeSubviews(){
        for view in self.view.subviews {
            view.removeFromSuperview()
        }
    }
    
    
    
    /////////////////////////////
    // MARK: - Ad Framework
    /////////////////////////////
    
    fileprivate func initAds(){
        log.debug("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        adView.adUnitID = admobID
        adView.rootViewController = self
        adView.load(GADRequest())
        adView.backgroundColor = UIColor.darkGray
    }
    
    
    
    /////////////////////////////
    // MARK: - Touch Handler(s)
    /////////////////////////////
    
    func backDidPress(){
        log.verbose("Back pressed")
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            suspend()
            //log.debug("Not a navigation Controller")
            suspend()
            dismiss(animated: true, completion: { self.delegate?.onCompletion() })
            return
        }
    }
    
    
    
    
    ////////////////////////////////////////////
    // MARK: - Rendering stuff
    ////////////////////////////////////////////
    
    fileprivate var sampleImageFull:UIImage!
    fileprivate var blendImageFull:UIImage!
    fileprivate var sampleImageSmall:UIImage? = nil
    fileprivate var blendImageSmall:UIImage? = nil
    fileprivate var sample:PictureInput? = nil
    fileprivate var blend:PictureInput? = nil
    
    
    
    fileprivate func loadInputs(){
        /***/
        //log.debug("creating scaled sample and blend images...")
        sampleImageFull = UIImage(named:"sample_emma_01.png")!
        blendImageFull = UIImage(named:"bl_topaz_warm.png")!
        
        // create scaled down versions of the sample and blend images
        //TODO: let user choose image
        let size = sampleImageFull.size.applying(CGAffineTransform(scaleX: 0.2, y: 0.2))
        
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        // downsize input images since we really only need thumbnails
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        sampleImageFull.draw(in: CGRect(origin: CGPoint.zero, size: size))
        sampleImageSmall = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        blendImageFull.draw(in: CGRect(origin: CGPoint.zero, size: size))
        blendImageSmall = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        sample = PictureInput(image:sampleImageSmall!)
        blend  = PictureInput(image:blendImageSmall!)
        /***/
    }
    
    
    
    
    // update the supplied RenderView with the supplied filter
    func updateRenderView(index:Int, key: String, renderView:RenderView){
        
        var descriptor: FilterDescriptorInterface?
        var filter:BasicOperation? = nil
        var filterGroup:OperationGroup? = nil
        
        descriptor = self.filterManager.getFilterDescriptor(key: key)
        
        log.debug("index:\(index), key:\(key), view:\(Utilities.addressOf(renderView))")
        
        /***
         var sample:PictureInput? = nil // for some reason, need to use local variables
         var blend:PictureInput? = nil
         let sampleImageFull:UIImage = UIImage(named:"sample_emma_01.png")!
         let blendImageFull:UIImage = UIImage(named:"bl_topaz_warm.png")!
         sample = PictureInput(image:sampleImageFull)
         blend  = PictureInput(image:blendImageFull)
         //sample = PictureInput(image:sampleImage)
         //blend  = PictureInput(image:blendImage!)
         var filter:BasicOperation? = nil
         var filterGroup:OperationGroup? = nil
         ***/
        
        if (sample == nil){
            loadInputs()
        } else {
            sample?.removeAllTargets()
            blend?.removeAllTargets()
        }
        
        
        //TODO: start rendering in an asynch queue
        //TODO: render to UIImage, no need for RenderView since image is static
        
        guard (sample != nil) else {
            log.error("Could not load sample image")
            return
        }
        
        guard ((descriptor?.filter != nil) || (descriptor?.filterGroup != nil)) else {
            log.error("Both filter and filterGroup are NIL for filter:\(descriptor?.key)")
            return
        }
        
        
        
        // annoyingly, we have to treat single and multiple filters differently
        if (descriptor?.filter != nil){ // single filter
            filter = descriptor?.filter
            
            log.debug("Run filter: \((descriptor?.key)!) address:\(Utilities.addressOf(filter))")
            
            let opType:FilterOperationType = (descriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                //log.debug("filter: \(descriptor?.key) address:\(Utilities.addressOf(filter))")
                sample! --> filter! --> renderView
                sample?.processImage(synchronously: true)
                break
            case .blend:
                //log.debug("Using BLEND mode for filter: \(descriptor?.key)")
                //TOFIX: blend image needs to be resized to fit the render view
                sample!.addTarget(filter!)
                blend! --> filter!
                sample! --> filter! --> renderView
                blend?.processImage(synchronously: true)
                sample?.processImage(synchronously: true)
                break
            }
            
            filter?.removeAllTargets()
            
        } else if (descriptor?.filterGroup != nil){ // group of filters
            filterGroup = descriptor?.filterGroup
            log.debug("Run filterGroup: \(descriptor?.key) address:\(Utilities.addressOf(filterGroup))")
            
            let opType:FilterOperationType = (descriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                //log.debug("filterGroup: \(descriptor?.key)")
                sample! --> filterGroup! --> renderView
                sample?.processImage(synchronously: true)
                break
            case .blend:
                //log.debug("Using BLEND mode for group: \(descriptor?.key)")
                //TOFIX: blend image needs to be resized to fit the render view
                sample!.addTarget(filterGroup!)
                blend! --> filterGroup!
                sample! --> filterGroup! --> renderView
                blend?.processImage(synchronously: true)
                sample?.processImage(synchronously: true)
                break
            }
            
            filterGroup?.removeAllTargets()
            
        } else {
            log.error("ERR!!! shouldn't be here!!!")
        }
        
        
        //renderView?.isHidden = false
        
        
    }
    
    
    
    ////////////////////////////////////////////
    // MARK: - UICollectionViewDataSource
    ////////////////////////////////////////////
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filterList.count
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // dequeue the cell
        let cell = galleryView.dequeueReusableCell(withReuseIdentifier: FilterGalleryViewCell.reuseID, for: indexPath) as! FilterGalleryViewCell2
        
        // configure based on the index
        
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        //log.verbose("Index: \(index) (\(self.filterList[index]))")
        if ((index>=0) && (index<filterList.count)){
            let key = self.filterList[index]
            //cell.updateRenderView(key: key, renderView: self.renderList[index])
            self.updateRenderView(index:index, key: key, renderView: self.renderList[index])
            cell.configureCell(frame: cell.frame, index:index, key:key, renderView: self.renderList[index])
            
        } else {
            log.warning("Index out of range (\(index)/\(filterList.count))")
        }
        //cell.layoutIfNeeded()
        return cell
    }
    
    
    
    
    ////////////////////////////////////////////
    // MARK: - UICollectionViewDelegate
    ////////////////////////////////////////////
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard (galleryView.cellForItem(at: indexPath) as? FilterGalleryViewCell2) != nil else {
            log.error("NIL cell")
            return
        }
        
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        let descr:FilterDescriptorInterface? = (self.filterManager.getFilterDescriptor(key:self.filterList[index]))
        log.verbose("Selected filter: \((descr?.key)!)")
        
        // suspend all active rendering and launch viewer for this filter
        filterManager.setSelectedFilter(key: (descr?.key)!)
        suspend()
        self.present(FilterDetailsViewController(), animated: true, completion: nil)
    }
    
    
    
    ////////////////////////////////////////////
    // MARK: - UICollectionViewFlowLayout
    ////////////////////////////////////////////
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
}




//////////////////////////////////////////
// MARK: - Delegate methods for sub-views
//////////////////////////////////////////

extension FilterGalleryViewController: CategorySelectionViewDelegate {
    func categorySelected(_ category:FilterManager.CategoryType){
        if (currCategory != category){
            log.debug("Category Selected: \(category)")
            suspend()
            //removeSubviews()
            currCategory = category
            initGalleryItems()
            layoutGallery()
            galleryView.reloadData()
        }
    }
    
}





extension FilterGalleryViewController: FilterGalleryViewDelegate {
    internal func requestUpdate(category: FilterManager.CategoryType) {
        log.debug("Update requested for Category: \(category.rawValue)")
    }
    
    func filterSelected(_ descriptor:FilterDescriptorInterface?){
        suspend()
        filterManager.setSelectedFilter(key: (descriptor?.key)!)
        self.present(FilterDetailsViewController(), animated: false, completion: nil)
    }
}

