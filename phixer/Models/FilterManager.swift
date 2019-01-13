//
//  FilterManager
//  phixer
//
//  Created by Philip Price on 10/5/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import CoreImage
import SwiftyJSON

// class that manages the list of available filters and groups them into categories



// SIngleton class that provides access to the categories/filters
// use FilterManager.sharedInstance to get a reference

class FilterManager{
    
    static let sharedInstance = FilterManager() // the actual instance shared by everyone
    
    public static let favouriteCategory = "favorites"
    public static let defaultCategory = favouriteCategory

    fileprivate static var initDone:Bool = false
    fileprivate static var currCategory: String = defaultCategory
    fileprivate static var currFilterDescriptor: FilterDescriptor? = nil
    fileprivate static var currFilterKey: String = ""
    //fileprivate static var currIndex:Int = -1
    

    static let sortClosure = { (value1: String, value2: String) -> Bool in return value1 < value2 }
   
    
    //////////////////////////////////////////////
    //MARK: - Category/Filter "Database"
    //////////////////////////////////////////////

    // typealias for dictionaries of FilterDescriptors
    
    fileprivate static var _renderViewDictionary:[String:MetalImageView?] = [:]
    fileprivate static var _lockList:[String:Int] = [:]

    // list of callbacks for change notification
    fileprivate static var _categoryChangeCallbackList:[()] = []
    fileprivate static var _filterChangeCallbackList:[()] = []
    
    //////////////////////////////////////////////
    //MARK: - Setup/Teardown
    //////////////////////////////////////////////
    
    fileprivate static func checkSetup(){
        if (!FilterManager.initDone) {
            FilterManager.initDone = true
            
            _renderViewDictionary = [:]
            _lockList = [:]
            _categoryChangeCallbackList = []
            _filterChangeCallbackList = []
            
            FilterLibrary.checkSetup()
            
            // TEMP DEBUG
            //print("FilterLibrary contents:...")
            //print ("FilterLibrary.categoryDictionary: \(FilterLibrary.categoryDictionary)")
            //print ("FilterLibrary.categoryList: \(FilterLibrary.categoryList)")
            //print ("FilterLibrary.filterDictionary: \(FilterLibrary.filterDictionary)")
            //print ("FilterLibrary.categoryFilters: \(FilterLibrary.categoryFilters)")
            
            /////////
            
            // Need to start somewhere...
            FilterManager.currCategory = defaultCategory
            //FilterManager.currIndex = FilterLibrary.categoryList.index(of: defaultCategory)
            log.verbose("category: \(defaultCategory)")
            let list = FilterLibrary.categoryFilters[defaultCategory]
            if (list != nil){
                if (list!.count > 0){
                    FilterManager.currFilterKey = list![0]
                    log.verbose("Current filter: \(FilterManager.currFilterKey)")
                } else {
                    log.error("No filters for category: \(defaultCategory)")
                    FilterManager.currFilterKey = "NoFilter"
                }
                if (FilterLibrary.filterDictionary[FilterManager.currFilterKey] == nil){
                    FilterLibrary.filterDictionary[FilterManager.currFilterKey] = FilterFactory.createFilter(key: FilterManager.currFilterKey)
                }
                FilterManager.currFilterDescriptor = (FilterLibrary.filterDictionary[FilterManager.currFilterKey])!
                //TODO: class-specific init?!
            } else {
                log.error("Invalid filter list for: \(defaultCategory)")
                FilterManager.currFilterDescriptor = nil
            }
        }
        
    }
    
    private static func reset(){
        FilterManager.initDone = false
        FilterManager.checkSetup()
    }
    
    fileprivate init(){
        FilterManager.checkSetup()
    }
    
    deinit{
        FilterManager._categoryChangeCallbackList = []
        FilterManager._filterChangeCallbackList = []
    }
    
    
    open func restoreDefaults(){
        FilterLibrary.restoreDefaults()
    }
    
    //////////////////////////////////////////////
    // MARK: - Category-related Accessors
    //////////////////////////////////////////////
    
    open func getCategoryList()->[String]{
        FilterManager.checkSetup()
        return FilterLibrary.categoryList
    }
    
    func getFilterCount(_ category:String)->Int {
        FilterManager.checkSetup()
        return (FilterLibrary.categoryFilters[category]?.count)!
    }
    
    func getCategoryCount()->Int {
        FilterManager.checkSetup()
        return FilterLibrary.categoryList.count
    }
    
    func getCurrentCategory() -> String{
        FilterManager.checkSetup()
        return FilterManager.currCategory
        
    }
    
    func setCurrentCategory(_ category:String){
        FilterManager.checkSetup()
        if (FilterManager.currCategory != category){
            log.debug("Category set to: \(category)")
            FilterManager.currCategory = category
            
            // set current filter to the first filter (alphabetically) in the dictionary
            
            if FilterLibrary.categoryFilters[category] != nil {
                let count = (FilterLibrary.categoryFilters[category]?.count)!
                if (count>0){
                    log.verbose ("\(count) items found")
                    let key = (FilterLibrary.categoryFilters[category]?[0])!
                    log.verbose("Setting filter to: \(key)")
                    setCurrentFilterKey(key)
                } else {
                    log.debug("List empty: \(category)")
                    setCurrentFilterDescriptor(nil)
                }
            } else {
                log.error("NIL category: \(category)")
                setCurrentFilterDescriptor(nil)
            }
            
            // notify clients
            issueCategoryChangeNotification()
        }
    }
    
    
    
    private static var selectedCategory:String = FilterManager.defaultCategory
    
    func setSelectedCategory(_ category: String){
        FilterManager.checkSetup()
        FilterManager.selectedCategory = category
        log.verbose("Selected Category: \(FilterManager.selectedCategory)")
    }
    
    func getSelectedCategory()->String{
        FilterManager.checkSetup()
        return FilterManager.selectedCategory
    }
  
    
    // 'Index' methods are provided to support previous/next types of navigation
    
    // get the index of the category within the category list.
    open func getCategoryIndex(category:String)->Int {
        var index:Int = -1
        
        FilterManager.checkSetup()
        if (FilterLibrary.categoryList.count > 0){
            if (FilterLibrary.categoryList.contains(category)){
                index = FilterLibrary.categoryList.index(of: category)!
                //log.verbose("category:\(category) index:\(index)")
            } else {
                log.error("Category not found:\(category)")
            }
        } else {
            log.error("Empty Category List!!!")
        }
        return index
    }
    
    
    open func getCurrentCategoryIndex()->Int {
        
        return getCategoryIndex(category:FilterManager.currCategory)
    }
  
    
    open func getCategory(index: Int) -> String{
        FilterManager.checkSetup()
        var category:String = FilterManager.defaultCategory
        if ((index >= 0) && (index < FilterLibrary.categoryList.count)){
            category =  FilterLibrary.categoryList[index]
        }
        return category
    }
 
    
    
    //////////////////////////////////////////////
    // MARK: - Favourites-related Accessors
    //////////////////////////////////////////////
   
    // indicates whether a filter is in the "Favourites" category/list
    open func isFavourite(key: String) -> Bool {
        var result:Bool = false
        let index = getCategoryIndex(category: FilterManager.favouriteCategory)
        if (index>=0) {
            result = (FilterLibrary.categoryFilters[FilterManager.favouriteCategory]?.contains(key))!
/***
            if (result) {
                log.verbose("Key: \(key) in favourites")
            } else {
                log.verbose("Key: \(key) NOT in favourites (\(index)): \(FilterLibrary.categoryFilters[FilterManager.favouriteCategory])")
            }
 ***/
        } else {
            log.error("ERR: Favourites category not found")
        }
        return result
    }
    
    // add a filter to the "Favourites" list
    open func addToFavourites(key: String) {
        if (FilterLibrary.filterDictionary[key] != nil){ // filter exists
            if (!((FilterLibrary.categoryFilters[FilterManager.favouriteCategory]?.contains(key))!)){ // not already there
                FilterLibrary.categoryFilters[FilterManager.favouriteCategory]?.append(key)
                FilterLibrary.commitChanges() // HACK: should update single record
            }
        } else {
            log.error("ERR: Unknown filter: \(key)")
        }
    }
    
    // remove a filter from the "Favourites" list
    open func removeFromFavourites(key: String) {
        if (FilterLibrary.filterDictionary[key] != nil){ // filter exists
            if ((FilterLibrary.categoryFilters[FilterManager.favouriteCategory]?.contains(key))!){ // in list?
                if let index = FilterLibrary.categoryFilters[FilterManager.favouriteCategory]?.index(of: key) {
                    FilterLibrary.categoryFilters[FilterManager.favouriteCategory]?.remove(at: index)
                    FilterLibrary.commitChanges() // HACK: should update single record
                }
            }
        } else {
            log.error("ERR: Unknown filter: \(key)")
        }
    }
    
    
    //////////////////////////////////////////////
    // MARK: - Filter-related Accessors
    //////////////////////////////////////////////
    
    
    
    func getCurrentFilterDescriptor() -> FilterDescriptor?{
        FilterManager.checkSetup()
        return FilterManager.currFilterDescriptor
    }
    
    func setCurrentFilterDescriptor(_ descriptor: FilterDescriptor?){
        FilterManager.checkSetup()
        if (FilterManager.currFilterDescriptor?.key != descriptor?.key){
            FilterManager.currFilterDescriptor = descriptor
            if (descriptor != nil){
                FilterManager.currFilterKey = (descriptor?.key)!
            } else {
                FilterManager.currFilterKey = ""
            }
            
            //log.debug("Filter changed to: \(String(describing: descriptor?.key))")
            
            // Notify clients
            issueFilterChangeNotification()
        }
    }
    func getCurrentFilterKey() -> String{
        FilterManager.checkSetup()
        return FilterManager.currFilterKey
    }
    
    func setCurrentFilterKey(_ key:String) {
        FilterManager.checkSetup()
        log.verbose("Key: \(key)")
        FilterManager.currFilterKey = key
        setCurrentFilterDescriptor(getFilterDescriptor(key:FilterManager.currFilterKey))
    }
    
    
    private static var selectedFilter:String = ""
    
    func setSelectedFilter(key: String){
        FilterManager.checkSetup()
        FilterManager.selectedFilter = key
        log.verbose("Selected filter: \(FilterManager.selectedFilter)")
    }
    
    func getSelectedFilter()->String{
        FilterManager.checkSetup()
        return FilterManager.selectedFilter
    }
    
    
    
    open func getFilterList(_ category:String)->[String]?{
        FilterManager.checkSetup()
        if (FilterLibrary.categoryFilters[category] != nil){
            return FilterLibrary.categoryFilters[category]
        } else {
            log.error("Invalid category:\"\(category)\"")
            return []
        }
    }
    
    
    public static var shownFilterList:[String] = []
    
    open func getShownFilterList(_ category:String)->[String]?{
        //var key:String = ""
        
        FilterManager.checkSetup()
        if (FilterLibrary.categoryFilters[category] != nil){
            FilterManager.shownFilterList = []
            let count:Int = (FilterLibrary.categoryFilters[category]?.count)!
            if (count > 0){
                for key in FilterLibrary.categoryFilters[category]! {
                    if (!FilterFactory.isHidden(key: key)){
                        FilterManager.shownFilterList.append(key)
                    }
                }
            } else {
                log.warning("No filters found for category: \(category)")
            }
            FilterManager.shownFilterList.sort(by: { (value1: String, value2: String) -> Bool in return value1 < value2 }) // sort ascending
            //log.verbose("\(FilterManager.shownFilterList.count) filters found for category: \(category): \(FilterManager.shownFilterList)")
            return FilterManager.shownFilterList
        } else {
            log.error("Invalid category:\"\(category)\"")
            return []
        }
    }
    
    
    
    // get the filter descriptor for the supplied filter type
    open func getFilterDescriptor(key:String)->FilterDescriptor? {
        
        var filterDescr: FilterDescriptor? = nil
        
        FilterManager.checkSetup()
        
        if (FilterLibrary.filterDictionary[key] == nil){    // if not allocatd, try creating it, i.e. only created if requested

            //log.debug("Creating filter object for key:\(key)")
            filterDescr = FilterFactory.createFilter(key: key)

            if (filterDescr == nil){ // error somewhere
                log.error("NIL descriptor returned for key:\(key)")
            }
            
            FilterLibrary.filterDictionary[key] = filterDescr
            
        } else {
            filterDescr = FilterLibrary.filterDictionary[key]!
        }
        //log.verbose("Found key:\((filterDescr?.key)!) addr:\(filterAddress(filterDescr))")
        
        // make sure RenderView has been allocated
        if (FilterManager._renderViewDictionary[key] == nil){
            FilterManager._renderViewDictionary[key] = MetalImageView()
        }

        return filterDescr
    }
  
    
    // 'Release' a filter descriptor. Should allow expensive OpenGL resources to be re-used
    open func releaseFilterDescriptor(key:String){
        
        if (!isLocked(key)){
            
            // release the filter descriptor
            if (FilterLibrary.filterDictionary[key] != nil){
                //let descr = (FilterLibrary.filterDictionary[key])!
                FilterLibrary.filterDictionary[key] = nil
                //log.debug("key:\(key)")
            }
            
            // make sure RenderView has been released
            if (FilterManager._renderViewDictionary[key] != nil){
                releaseRenderView(key: key)
            }
        }
    }
    
    
    // 'Index' methods are provided to support previous/next types of navigation
    
    // get the index of the filter within the category list. -1 if not found
    open func getFilterIndex(category:String, key:String)->Int {
        
        FilterManager.checkSetup()
        
        var index = -1
        
        //let list = category.getFilterList()
        if ((FilterLibrary.categoryFilters[category]?.contains(key))!){
            index = (FilterLibrary.categoryFilters[category]?.index(of: key))!
        }
        
        return index
    }
    
    
    open func getCurrentFilterIndex()->Int {
   
        return getFilterIndex(category:FilterManager.currCategory, key:FilterManager.currFilterKey)
    }
    
    
    // returns the key based on the index in the list
    open func getFilterKey(category:String, index:Int)->String {
        
        var key: String = ""
        
        FilterManager.checkSetup()
        
        let count = (FilterLibrary.categoryFilters[category]?.count)!
        if ((index>=0) && (index<count)){
            key = (FilterLibrary.categoryFilters[category]?[index])!
        }
        
        return key
    }
    
    
    // returns the RenderView associated with the supplied filter key
    func getRenderView(key:String)->MetalImageView?{
        
        FilterManager.checkSetup()
        
        if (FilterManager._renderViewDictionary[key] == nil){
            // not an error, just lazy allocation. Create the RenderView and add it to the dictionary
            log.debug("create key:\(key)")
            FilterManager._renderViewDictionary[key] = MetalImageView()
        }
        
        return (FilterManager._renderViewDictionary[key])!
    }
    
    
    // 'locks' a filter/renderview so that it cannot be released
    public static func lockFilter(key:String){
        FilterManager.checkSetup()
        
        log.debug("key:\(key)")
        if (FilterManager._lockList[key] == nil){
            FilterManager._lockList[key] = 0
        }
        FilterManager._lockList[key] = FilterManager._lockList[key]! + 1
    }
    
    // 'locks' a filter/renderview so that it cannot be released
    public static func unlockFilter(key:String){
        FilterManager.checkSetup()
        
        log.debug("key:\(key)")
        if (FilterManager._lockList[key] != nil){
            FilterManager._lockList[key] = FilterManager._lockList[key]! - 1
            if (FilterManager._lockList[key]! <= 0) {
                FilterManager._lockList[key] = nil
            }
        }
    }

    // check to see if a filter is locked
    public func isLocked(_ key:String) -> Bool {
        return (FilterManager._lockList[key] != nil)
    }
    
    // releases the RenderView associated with the supplied filter key
    func releaseRenderView(key:String){
        
        FilterManager.checkSetup()
        
        if (FilterManager._renderViewDictionary[key] != nil){
            if (!isLocked(key)){
                FilterManager._renderViewDictionary[key] = nil
                //log.debug("key:\(key)")
            }
        }
    }
    
    
    open func isHidden(key:String) -> Bool {
        return FilterFactory.isHidden(key:key)
    }
    
    // designate a filter as hidden or not
    open func setHidden(key:String, hidden:Bool){
        FilterFactory.setHidden(key: key, hidden: hidden)
        FilterLibrary.commitChanges() // HACK: should update single record
    }
    
    // get the rating for a filter
    open func getRating(key:String) -> Int{
        return FilterFactory.getRating(key:key)
    }
    
    // set the rating for a filter
    open func setRating(key:String, rating:Int){
        FilterFactory.setRating(key:key, rating:rating)
        FilterLibrary.commitChanges() // HACK: should update single record
    }
    
    
    open func isSlow(key:String) -> Bool {
        return FilterFactory.isSlow(key:key)
    }
    
    // designate a filter as hidden or not
    open func setSlow(key:String, slow:Bool){
        FilterFactory.setSlow(key: key, slow: slow)
        FilterLibrary.commitChanges() // HACK: should update single record
    }
    

    //////////////////////////////////////////////
    // MARK: - Style Transfer-related Accessors
    //////////////////////////////////////////////
    
   
    
    open func getStyleTransferList()->[String]?{
        FilterManager.checkSetup()
        return FilterLibrary.styleTransferList
    }
    
    
    public static var shownStyleTransferList:[String] = []
    
    open func getShownStyleTransferList()->[String]?{
        
        FilterManager.checkSetup()
        FilterManager.shownStyleTransferList = []
        let count:Int = (FilterLibrary.styleTransferList.count)
        if (count > 0){
            for key in FilterLibrary.styleTransferList {
                if (!FilterFactory.isHidden(key: key)){
                    FilterManager.shownStyleTransferList.append(key)
                }
            }
            
            FilterManager.shownStyleTransferList.sort(by: { (value1: String, value2: String) -> Bool in return value1 < value2 }) // sort ascending
        }
        return FilterManager.shownStyleTransferList
    }
    
    
    //////////////////////////////////////////////
    // MARK: - Callback/Notification methods
    //////////////////////////////////////////////
    
  /***
    open func setCategoryChangeNotification(callback: ()) {
        FilterManager._categoryChangeCallbackList.append(callback)
    }
    
    
    open func setFilterChangeNotification(callback: ()) {
        FilterManager._filterChangeCallbackList.append(callback)
    }
***/
    
    func issueCategoryChangeNotification(){
        if (FilterManager._categoryChangeCallbackList.count>0){
            log.debug("Issuing \(FilterManager._categoryChangeCallbackList.count) CategoryChange callbacks (->\(FilterManager.currCategory))")
            for cb in FilterManager._categoryChangeCallbackList {
                cb
            }
        }
    }
    
    func issueFilterChangeNotification(){
        if (FilterManager._filterChangeCallbackList.count>0){
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                log.debug("Issuing \(FilterManager._categoryChangeCallbackList.count) FilterChange callbacks")
                for cb in FilterManager._filterChangeCallbackList {
                    cb
                }
            }
        }
    }

} // FilterManager
