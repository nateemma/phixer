//
//  FilterGalleryView.swift
//  phixer
//
//  Created by Philip Price on 10/24/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import CoreImage
import Cosmos


// Interface required of controlling View
protocol FilterGalleryViewDelegate: class {
    func filterSelected(_ descriptor:FilterDescriptor?)
    func requestUpdate(category:String)
    func setHidden(key:String, hidden:Bool)
    func setFavourite(key:String, fav:Bool)
    func setRating(key:String, rating:Int)
}



// this class displays a CollectionView populated with the filters for the specified category
//class FilterGalleryView : UIView, UICollectionViewDataSource, UICollectionViewDelegate{
class FilterGalleryView : UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, FilterGalleryViewCellDelegate {
    
    var theme = ThemeManager.currentTheme()
    

    public static var showHidden:Bool = false // controls whether hidden filters are shown or not
    
    fileprivate var displayWidth : CGFloat = 0.0
    fileprivate var displayHeight : CGFloat = 0.0
    
    fileprivate var aspectRatio : CGFloat = 1.0
    
    fileprivate var itemsPerRow: CGFloat = 3
    fileprivate var cellSpacing: CGFloat = 2
    fileprivate var cellSize: CGSize = CGSize.zero
    fileprivate var indicatorWidth: CGFloat = 41
    fileprivate var indicatorHeight: CGFloat = 8
    fileprivate var imgSize: CGSize = CGSize.zero // size used for processed image (usually smaller than real size)
    fileprivate var imgViewSize: CGSize = CGSize.zero

    fileprivate let leftOffset: CGFloat = 11
    fileprivate let rightOffset: CGFloat = 7
    fileprivate let height: CGFloat = 34
    

    
    // struct for holding filter display info
    struct FilterInfo {
        var title: String = ""
        var rating:Int = 0
        var favourite:Bool = false
        var show:Bool = true
    }
    
    fileprivate var keyList:[String] = []
    fileprivate var infoList:[FilterInfo] = []
    //fileprivate var imageList:[CIImage?] = []

    
    //fileprivate var currCategory: String = FilterManager.defaultCategory
    fileprivate var currCategory: String = ""
    fileprivate var filterManager:FilterManager = FilterManager.sharedInstance
    fileprivate var selectedIndex:Int = -1
    
    fileprivate let layout = UICollectionViewFlowLayout()
    
    fileprivate var filterGallery:UICollectionView? = nil
    fileprivate var firstTime:Bool = true

    //fileprivate var opacityFilter:OpacityAdjustment? = nil
    
    // object to load filters asynchrobously into cache
    private let filterLoader = FilterLoader()

    
    // delegate for handling events
    weak var delegate: FilterGalleryViewDelegate?

    
    /////////////////////////////////////
    //MARK: - Initializers
    /////////////////////////////////////
    
    
    
    convenience init(){
        self.init(frame: CGRect(origin: CGPoint.zero, size: UISettings.screenSize))
       // self.init(frame: CGRect.zero)
        
        doInit()
    }
    
    
    deinit{
        //suspend()
        releaseResources()
        keyList = []
        infoList = []
        inputImage = nil
        blend = nil
        filterGallery = nil
   }
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layoutDone = false // force re-layout
        filterGallery = nil
        
        // set up the gallery/collection view
        
        layout.itemSize = self.frame.size
        if filterGallery == nil {
            log.debug("Adding Gallery, itemSize: \(layout.itemSize)")
            filterGallery = UICollectionView(frame: self.frame, collectionViewLayout: layout)
            filterGallery?.isHidden = false
            //filterGallery?.isPrefetchingEnabled = true
            filterGallery?.isPrefetchingEnabled = false // can't get this to work properly (using RenderView)
            filterGallery?.delegate   = self
            filterGallery?.dataSource = self
            filterGallery?.prefetchDataSource = self
            filterGallery?.register(FilterGalleryViewCell.self, forCellWithReuseIdentifier: FilterGalleryViewCell.reuseID)
            
            self.addSubview(filterGallery!)
            filterGallery?.fillSuperview()
        }

        doLayout()
        doLoadData()
        
        setupGestures()
        
    }

    fileprivate func doInit(){
        if self.currCategory.isEmpty {
            self.currCategory = self.filterManager.getCurrentCategory()
            self.keyList = self.filterManager.getFilterList(self.currCategory)!
        }
        setDefaultSizes()
        loadInputs(size: self.imgSize)
    }
    
    
    fileprivate  var layoutDone:Bool = false
    
    
    fileprivate func doLayout(){
        
        if !self.layoutDone {
            self.layoutDone = true
            //resetCache()
            
            // get display dimensions
            displayHeight = self.frame.size.height
            displayWidth = self.frame.size.width
            
            log.verbose("w:\(displayWidth) h:\(displayHeight)")
            
            
            selectedIndex = -1
            
            // set up sizing based on default case (can be changed later)
            setDefaultSizes()
            
        }
        
    }
    
    fileprivate func doLoadData(){
        //log.verbose("activated")
        //ignore compiler warnings
        var filter:FilterDescriptor? = nil
        //var renderview:RenderView? = nil
        
        if (self.keyList.count > 0){
            self.keyList = []
            self.infoList = []
        }
        
        // (Re-)build the list of (visible) filters
        if FilterGalleryView.showHidden {
            self.keyList = self.filterManager.getFilterList(self.currCategory)!
        } else {
            // only add filters if they are not hidden

            //if let list = self.filterManager.getShownFilterList(self.currCategory) {
            if let list = (FilterGalleryView.showHidden==true) ? self.filterManager.getFilterList(self.currCategory) : self.filterManager.getShownFilterList(self.currCategory) {
                if list.count > 0 {

                    for k in list {
                        if let descr = filterManager.getFilterDescriptor(key: k) {
                            if (descr.show || FilterGalleryView.showHidden) {
                                keyList.append(k)
                            }
                        }
                    }
                }
            }
        }
        self.keyList.sort(by: { (value1: String, value2: String) -> Bool in return value1 < value2 }) // sort ascending
        
        // load filter information (must do this after sorting keylist)
        if keyList.count > 0 {
            for k in keyList {
                if let descr = filterManager.getFilterDescriptor(key: k) {
                    if (descr.show || FilterGalleryView.showHidden) {
                        var info = FilterInfo()
                        info.title = descr.title
                        info.rating = descr.rating
                        info.favourite = filterManager.isFavourite(key: k)
                        info.show = !filterManager.isHidden(key: k)
                        infoList.append(info)
                    }
                }
            }
        }
        
        log.debug ("Loading... \(self.keyList.count) filters for category: \(self.currCategory)")
        
        // load the input data
        loadInputs(size: imgSize)

/***/
        // pre-load filters. Inefficient, but it avoids multi-thread timing issues when rendering cells
        // ignore compiler warnings, the intent is to pre-load the filters
        if (self.keyList.count > 0){
            //for i in 0..<min(12,  self.keyList.count) {
                for i in 0..<self.keyList.count {
                let key = self.keyList[i]
                ImageCache.add(self.inputImage, key: key)
                filter = filterManager.getFilterDescriptor(key: key)
                //renderview = loadRenderView(key: key)
                //renderview?.setImageSize(imgSize)
           }
        }
/***/
        
        //self.filterGallery?.reloadData()
        //self.filterGallery?.setNeedsDisplay()
        
        
        // load the cache in the background
        loadCache()

        self.filterGallery?.reloadData()
    }
    
    ////////////////////////////////////////////
    // MARK: - Accessors
    ////////////////////////////////////////////

    open func update(){
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
    //DispatchQueue.main.async {
            //self.filterGallery?.setNeedsDisplay()
            log.debug("update requested")
            //self.doLayout()
            self.filterGallery?.reloadData()
            //doLoadData()
        }
    }
    
    // call when input image has changed
    open func updateInputs() {
        log.debug("updating inputs")
        //resetCache()
        setDefaultSizes()
        loadInputs(size: imgSize)
        loadCache()

//        let c = self.currCategory
//        currCategory = ""
//        setCategory(c)
//        update()
    }
    
    
    open func setCategory(_ category:String){
        if (currCategory != category) {
            // clear the previous cached items (if any)
            releaseResources()
            //unloadCache()
            
            log.debug("Category: \(category)")
            currCategory = category
            firstTime = false
            //EditManager.removePreviewFilter()
            doLayout()
            doLoadData()
        } else {
            log.warning("Warning: category was already set to: \(category). Check logic")
        }
    }
    
    // Suspend all MetalPetal-related operations
    open func suspend(){
        log.debug("suspending")
        releaseResources()
    }
    
    
    // get the next filter after the specified key
    func getFilterAfter(key: String)->String {
        var newkey:String = ""
        let kIndex = indexForKey(key)
        if (kIndex >= 0) && (kIndex < self.keyList.count){
            let index = (kIndex < (keyList.count-1)) ? (kIndex + 1) : 0
            newkey = self.keyList[index]
        } else {
            newkey = self.keyList[0]
        }
        return newkey
    }
    
    // get the filter before the specified key
    func getFilterBefore(key: String)->String {
        var newkey:String = ""
        let kIndex = indexForKey(key)
        if (kIndex >= 0) && (kIndex < self.keyList.count){
            let index = (kIndex > 0) ? (kIndex - 1) : (keyList.count - 1)
            newkey = self.keyList[index]
        } else {
            newkey = self.keyList[0]
        }
        return newkey
    }

    ////////////////////////////////////////////
    // MARK: - Image cache
    ////////////////////////////////////////////

    fileprivate  var cacheLoaded:Bool = false

    // asynchronusly loads filtered images into the image cache
    private func loadCache(){
        if inputImage == nil  {
            doInit()
        }
        
        if (!cacheLoaded)   { // not an error, just don't need to do anything

            if (self.keyList.count > 0){
                // add an entry for each filter to be displayed
                log.verbose("Loading cache (\(self.keyList.count) images)")
                
                // setting flag here to stop multiple loads
                cacheLoaded = true
                
//                for key in keyList {
//                    // add the input image for now. It will be replaced by the filtered version
//                    ImageCache.add(inputImage, key: key)
//                }
                
                self.blend = nil // big, so only allocate when needed
                
                // this is asynchronous
                loadFilterList()
                
            }
        } else {
            log.verbose("Cache already loaded")
        }
        
    }
    


    // loads the list of filters one at a time
    private func loadFilterList(){
        
        loadInputs(size: imgSize)
        //filterLoader.unload() // in case anything was previously loaded
        filterLoader.load(image: self.inputImage,
                          filters: keyList,
                          update: { key in
                            DispatchQueue.main.async(execute: { [weak self] in
                                //log.debug("...\(key)")
                                //self?.reloadView(key:key)
                                self?.updateCell(key)
                            })
                          },
                          completion: {
                            DispatchQueue.main.async(execute: { [weak self] in
                                self?.cacheLoaded = true
                                log.debug("Cache loaded")
                                self?.update()
                           })
                          }
                         )
    }

    
    
    // removes images from the cache
    private func unloadCache() {
        if self.cacheLoaded {
            if (self.keyList.count > 0){
                self.cacheLoaded = false
                filterLoader.unload(filters: keyList)
            }
        }
    }
    
    // resets the cache
    private func resetCache() {
        self.cacheLoaded = true
        unloadCache()
        loadCache()
    }
    
    // releaes the resources that we used for the gallery items
    
    private func releaseResources(){
        if (self.keyList.count > 0){
            log.verbose("Releasing \(self.keyList.count) filters")
            unloadCache()
             for key in keyList {
                filterManager.releaseFilterDescriptor(key: key)
                filterManager.releaseRenderView(key: key)
            }
           //RenderView.reset()
            filterLoader.clear()
            self.cacheLoaded = false

            //listCells() //debug
        }
    }

    
    private func loadRenderView(key: String) -> RenderView? {
        var renderview: RenderView? = nil
        
        if !key.isEmpty {
            renderview = filterManager.getRenderView(key: key)
            if renderview == nil {
                log.warning("NIL RenderView for key:\(key)")
               renderview = RenderView()
            }
            renderview?.image = ImageCache.get(key: key)
        } else {
            log.warning("Empty key")
            renderview = RenderView()
        }
        
        if renderview?.image == nil {
            renderview?.image = EditManager.getFilteredImage()
            renderview?.setImageSize(EditManager.getImageSize())
        }
        
        return renderview
    }

    ////////////////////////////////////////////
    // MARK: - Rating Alert (for showing rating and allowing change)
    ////////////////////////////////////////////

    fileprivate var ratingAlert:UIAlertController? = nil
    fileprivate var currRating: Int = 0
    fileprivate var currRatingKey: String = ""
    fileprivate static var starView: CosmosView? = nil
    
    fileprivate func displayRating(){
        
        
        // build the rating stars display based on the current rating
        // I'm using the 'Cosmos' class to do this
        if (FilterGalleryView.starView == nil){
            FilterGalleryView.starView = CosmosView()
            
            FilterGalleryView.starView?.settings.fillMode = .full // Show only fully filled stars
            //starView?.settings.starSize = 30
            FilterGalleryView.starView?.settings.starSize = Double(self.frame.size.width / 16.0) - 2.0
            //starView?.settings.starMargin = 5
            
            // Set the colours
            FilterGalleryView.starView?.settings.totalStars = 3
            FilterGalleryView.starView?.backgroundColor = UIColor.clear
            FilterGalleryView.starView?.settings.filledColor = UIColor.flatYellow
            FilterGalleryView.starView?.settings.emptyBorderColor = UIColor.flatGrayDark
            FilterGalleryView.starView?.settings.filledBorderColor = UIColor.flatBlack
            
            FilterGalleryView.starView?.didFinishTouchingCosmos = { rating in
                self.currRating = Int(rating)
                FilterGalleryView.starView?.anchorInCenter(width: self.frame.size.width / 4.0, height: self.frame.size.width / 16.0)
            }
        }
        FilterGalleryView.starView?.rating = Double(currRating)
        
        // igf not already done, build the alert
        if (ratingAlert == nil){
            // setup the basic info
            ratingAlert = UIAlertController(title: "Rating", message: " ", preferredStyle: .alert)
            
            // add the OK button
            let okAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                self.filterManager.setRating(key: self.currRatingKey, rating: self.currRating)
                log.debug("OK")
            }
            ratingAlert?.addAction(okAction)
            
            // add the Cancel Button
            let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action:UIAlertAction) in
                log.debug("Cancel")
            }
            ratingAlert?.addAction(cancelAction)
            
            
            // add the star rating view
            ratingAlert?.view.addSubview(FilterGalleryView.starView!)
        }
        
        FilterGalleryView.starView?.anchorInCenter(width: self.frame.size.width / 4.0, height: self.frame.size.width / 16.0)
        
        // launch the Alert. Need to get the Controller to do this though, since we are calling from a View
        DispatchQueue.main.async(execute: { () -> Void in
            let ctlr = self.getCurrentViewController()
            ctlr?.present(self.ratingAlert!, animated: true, completion:nil)
        })
    }
    
    func getCurrentViewController() -> UIViewController? {
        
        if let rootController = UIApplication.shared.keyWindow?.rootViewController {
            var currentController: UIViewController! = rootController
            while( currentController.presentedViewController != nil ) {
                currentController = currentController.presentedViewController
            }
            return currentController
        }
        return nil
        
    }
    
    
    ////////////////////////////////////////////
    // MARK: - Sizing
    ////////////////////////////////////////////
    
    // layout is *really* sensitive to left/right for some reason
    //fileprivate var sectionInsets = UIEdgeInsets(top: 2.0, left: 3.0, bottom: 2.0, right: 3.0)
    fileprivate var sectionInsets = UIEdgeInsets(top: 2.0, left: 4.0, bottom: 2.0, right: 4.0)

    private func setDefaultSizes(){
        // assuming portrait orientation, use default is 3 items per row if photo is also portrait, 2 otherwise
        
        // get aspect ratio of input (used for layout sizing)
        
        aspectRatio = EditManager.getAspectRatio() // w:h ratio (>1 means landscape)
        
        itemsPerRow = (aspectRatio > 1.0) ? 2 : 3

        updateGridSettings()
    }
    
    public func increaseGridSize() {
        if (itemsPerRow > 1) {
            itemsPerRow = itemsPerRow - 1
            updateGridSettings()
            //reloadRenderViews()
            filterGallery?.reloadData()
//            self.resetCache()
//            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { [weak self] in
//                self?.filterGallery?.reloadData()
//            }
        }
    }
    
    public func decreaseGridSize() {
        let maxItems: CGFloat = (aspectRatio > 1.0) ? 4 : 5
        if (itemsPerRow < maxItems) {
            itemsPerRow = itemsPerRow+1
            updateGridSettings()
            //reloadRenderViews()
            filterGallery?.reloadData()
            //            self.resetCache()
            //            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { [weak self] in
            //                self?.filterGallery?.reloadData()
            //            }
        }
    }

    private func updateGridSettings(){
        // calculate the sizes for the input image and displayed view
        
        //let paddingSpace = ((sectionInsets.left * (itemsPerRow+1)) + (sectionInsets.right * (itemsPerRow+1)) + 2.0).rounded()
        //let paddingSpace = ((sectionInsets.left * itemsPerRow) + (sectionInsets.right * itemsPerRow) + 2.0).rounded()
        //let paddingSpace = ((itemsPerRow+1) * 4.0).rounded()
        //let availableWidth = (self.frame.width - paddingSpace).rounded()
        //let widthPerItem = (availableWidth / itemsPerRow).rounded()
        let widthPerItem = ((self.frame.width / itemsPerRow) - (sectionInsets.left + sectionInsets.right + 2.0)).rounded()

        cellSize = CGSize(width: widthPerItem, height: (widthPerItem/aspectRatio).rounded()) // use same aspect ratio as inputImage image
        imgViewSize = cellSize
        sectionInsets.bottom = (cellSize.height * 0.5).rounded() // otherwise, only half of bottom row shows
        
        // calculate the sizes for processing the input image (typically a downscaled version of the input)
        // for now, we just use the cell size adjusted for the screen points per pixel
        imgSize = CGSize(width: imgViewSize.width * UISettings.screenScale, height: imgViewSize.height * UISettings.screenScale)

    }
    
    //////////////////////////////////////////
    // MARK: - Gesture management
    //////////////////////////////////////////

    fileprivate var pinchGesture  = UIPinchGestureRecognizer()
    
    private func setupGestures(){
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(sender:)))
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(pinchGesture)
        pinchGesture.delegate = self
    }
    
    
    @objc func handlePinch(sender:UIPinchGestureRecognizer){
        if sender.state == .ended { // only handle when gesture ends
            log.debug("scale: \(sender.scale)")
            if sender.scale > 1.0 {
                increaseGridSize()
            } else {
                decreaseGridSize()
            }
            sender.scale = 1.0
        }
    }
    
    
    ////////////////////////////////////////////
    // MARK: - Rendering stuff
    ////////////////////////////////////////////
    
    fileprivate var inputImage:CIImage? = nil
    fileprivate var blend:CIImage? = nil
    
    
    
    fileprivate func loadInputs(size:CGSize){
        
        //if self.inputImage == nil {
            // input image can change, so make sure it's current
            //EditManager.setInputImage(InputSource.getCurrentImage())
            
            // downsize the input image to something based on the requested size. Keep the aspect ratio though, otherwise redndering will be strange
            // resize so that longest is edge is a multiple of the desired size
            
            let lreq = max(size.width, size.height) // longest requested side
            let insize = EditManager.getImageSize()
            if insize.width < 0.01 {
                log.error("Invalid size for input image: \(insize)")
            }
            let lin = max(insize.width, insize.height) // longest side of the input image
            let ldes = 2 * lreq * UISettings.screenScale // desired size - account for screen scale (dots per pixel) and provide some margin
            var mysize:CGSize = insize
            
            // resize if the input image is bigger than desired (which it should be)
            if lin > ldes {
                let ratio = ldes / lin
                mysize = CGSize(width: (insize.width*ratio).rounded(), height: (insize.height*ratio).rounded())
            }
            inputImage = EditManager.getFilteredImage()?.resize(size: mysize)
            if inputImage == nil {
                log.error("ERR retrieveing input image")
            }
            
            // don't load until needed
            blend  = ImageManager.getCurrentBlendImage(size:mysize) // OK if nil
        //}
    }
    
    
    // updates the individual cell associated with 'key'
    func updateCell(_ key: String){
        guard !key.isEmpty else {
            log.error("Empty key")
            return
        }
        
        if let index = keyList.indexOf(item: key) {
            let indexPath = IndexPath(item: index, section: 0)
            filterGallery?.reloadItems(at: [indexPath])
        } else {
            log.error("No info found for key: \(key)")
        }
    }
    

    ////////////////////////////////////////////
    // MARK: - Debug
    ////////////////////////////////////////////

    // debug func to list all cells in this collection
    private func listCells(){
        for i in 0...self.keyList.count-1 {
            if let cell = filterGallery?.cellForItem(at: NSIndexPath(index: i) as IndexPath) {
                log.debug("Cell: \(i) cell: \(cell)")
            } else {
                log.debug("Cell: \(i) cell: NIL")
            }
        }
    }

}



////////////////////////////////////////////
// MARK: - Extensions
////////////////////////////////////////////



// MARK: - Private
private extension FilterGalleryView {
    func keyForIndexPath(_ indexPath: IndexPath) -> String {
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        if ((index>=0) && (index<keyList.count)){
            return keyList[index]
        } else {
            log.error("Index:\(index) out of range (0..\(keyList.count))")
            return ""
        }
    }
    
    func indexForKey(_ key:String) -> Int{
        if let index = keyList.firstIndex(of: key) {
            return index
        } else {
            return 0
        }
    }
}




////////////////////////////////////////////
// MARK: - UIAlertController
////////////////////////////////////////////

// why do we have to do this?! when AlertController is set up, re-position the stars
extension UIAlertController {
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // TODO: figure out sizes
        FilterGalleryView.starView?.anchorInCenter(width: 128, height: 32)
    }
}

////////////////////////////////////////////
// MARK: - UICollectionViewDataSource
////////////////////////////////////////////

extension FilterGalleryView {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return keyList.count
    }
    
    
    // return the cell for display at the provided index
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // dequeue the cell
        let cell = filterGallery?.dequeueReusableCell(withReuseIdentifier: FilterGalleryViewCell.reuseID, for: indexPath) as! FilterGalleryViewCell
        
        // configure based on the index
        
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        if ((index>=0) && (index<keyList.count)){
            //            DispatchQueue.main.async(execute: { () -> Void in
            //log.verbose("(cellForItemAt) Index: \(index) key:(\(self.keyList[index]))")
            let key = self.keyList[index]
            let info = infoList[index]
            cell.delegate = self
            cell.configureCell(frame: cell.frame, index: index, key: key, image: ImageCache.get(key: key),
                               label: info.title, rating: info.rating, favourite: info.favourite, show: info.show)
            //            })
            
        } else {
            log.warning("Index out of range (\(index)/\(keyList.count))")
        }
        return cell
    }
    
    
    // pre-load cell when it is about to be displayed
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: FilterGalleryViewCell, forItemAt indexPath: IndexPath) {
        let index:Int = (indexPath as NSIndexPath).item
        if ((index>=0) && (index<keyList.count)){
            //DispatchQueue.main.async(execute: { () -> Void in
            log.verbose("(willDisplay) Index: \(index) key:(\(self.keyList[index]))")
            let key = self.keyList[index]
            let info = infoList[index]
            cell.delegate = self
            cell.configureCell(frame: cell.frame, index: index, key: key, image: ImageCache.get(key: key),
                               label: info.title, rating: info.rating, favourite: info.favourite, show: info.show)
            //})
        } else {
            log.warning("Index out of range (\(index)/\(keyList.count))")
        }
    }

}



////////////////////////////////////////////
// MARK: UICollectionViewDataSourcePrefetching
////////////////////////////////////////////

extension FilterGalleryView: UICollectionViewDataSourcePrefetching {
    // preload cells that are predicted to be displayed soon
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        log.debug("indexes: \(indexPaths)")
        for indexPath in indexPaths {
            let index:Int = (indexPath as NSIndexPath).item
            if ((index>=0) && (index<keyList.count)){
                // dequeue the cell
                let cell = filterGallery?.dequeueReusableCell(withReuseIdentifier: FilterGalleryViewCell.reuseID, for: indexPath) as! FilterGalleryViewCell
                //DispatchQueue.main.async(execute: { () -> Void in
                    log.verbose("(prefetchItemsAt) Index: \(index) key:(\(self.keyList[index]))")
                    let key = self.keyList[index]
                let info = infoList[index]
                cell.delegate = self
                cell.configureCell(frame: cell.frame, index: index, key: key, image: ImageCache.get(key: key),
                                   label: info.title, rating: info.rating, favourite: info.favourite, show: info.show)
                //})
            } else {
                log.warning("Index out of range (\(index)/\(keyList.count))")
            }
       }
    }

}



////////////////////////////////////////////
// MARK: - UICollectionViewDelegate
////////////////////////////////////////////

extension FilterGalleryView {
    
    // handle selection of a specific cell
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard (filterGallery?.cellForItem(at: indexPath) as? FilterGalleryViewCell) != nil else {
            log.error("NIL cell")
            return
        }
        
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        selectedIndex = index
        let descr:FilterDescriptor? = (self.filterManager.getFilterDescriptor(key:self.keyList[index]))
        log.verbose("Selected filter: \((descr?.key)!)")
        
        // suspend all active rendering and launch viewer for this filter
        filterManager.setCurrentCategory(currCategory)
        filterManager.setCurrentFilterKey((descr?.key)!)
        //suspend()
        //self.present(FilterDetailsViewController(), animated: true, completion: nil)
        delegate?.filterSelected(descr!)
    }
    
}


////////////////////////////////////////////
// MARK: - FilterGalleryViewCell
////////////////////////////////////////////

extension FilterGalleryView {
    
    // handle touch of show/hide icon in cell
    func hiddenTouched(key:String){
        log.verbose("key: \(key)")
        let hidden =  (self.filterManager.isHidden(key: key)) ? false : true
        self.filterManager.setHidden(key: key, hidden: hidden)
        self.update()
    }
    
    // handle touch of favourite icon in cell
    func favouriteTouched(key:String){
        log.verbose("key: \(key)")
        //TODO: confirmation dialog?
        if (self.filterManager.isFavourite(key: key)){
            log.verbose ("Removing from Favourites: \(key)")
            self.filterManager.removeFromFavourites(key: key)
        } else {
            log.verbose ("Adding to Favourites: \(key)")
            self.filterManager.addToFavourites(key: key)
        }
        self.update()
    }
    
    // handle touch of rating icon in cell
    func ratingTouched(key:String){
        log.verbose("key: \(key)")
        currRating = self.filterManager.getRating(key: key)
        currRatingKey = key
        displayRating()
    }

}

////////////////////////////////////////////
// MARK: - UICollectionViewFlowLayout
////////////////////////////////////////////

extension FilterGalleryView {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return imgViewSize
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}


////////////////////////////////////////////
// MARK: - Gesture detection extensions
////////////////////////////////////////////

extension FilterGalleryView: UIGestureRecognizerDelegate {
    

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        return true
    }

    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            
        // if this is a pinch type, then don't pass on
        if gestureRecognizer is UIPinchGestureRecognizer {
            return false
        } else {
            return true
        }
    }

}

