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
    
    // predefine categories
    public static let favouriteCategory = "favorites"
    public static let defaultCollection = favouriteCategory
    public static let defaultCategory = favouriteCategory
    public static let styleTransferCategory = "styletransfer"

    fileprivate static var initDone:Bool = false
    fileprivate static var currCollection: String = "" // empty string means all categories (regardless of collection)
    fileprivate static var currCategory: String = defaultCategory
    fileprivate static var currFilterDescriptor: FilterDescriptor? = nil
    fileprivate static var currFilterKey: String = ""
    //fileprivate static var currIndex:Int = -1
    

    static let sortClosure = { (value1: String, value2: String) -> Bool in return value1 < value2 }
   
    
    //////////////////////////////////////////////
    //MARK: - Category/Filter "Database"
    //////////////////////////////////////////////

    // typealias for dictionaries of FilterDescriptors
    
    //fileprivate static var _renderViewDictionary:[String:RenderView?] = [:]
    fileprivate static var _lockList:[String:Int] = [:]

    // list of callbacks for change notification
    fileprivate static var _categoryChangeCallbackList:[()] = []
    fileprivate static var _filterChangeCallbackList:[()] = []
    
    //////////////////////////////////////////////
    //MARK: - Setup/Teardown
    //////////////////////////////////////////////
    
    public static func checkSetup(){
        if (!FilterManager.initDone) {
            FilterManager.initDone = true
            
            _lockList = [:]
            _categoryChangeCallbackList = []
            _filterChangeCallbackList = []
            
            FilterConfiguration.checkSetup()
            
            // TEMP DEBUG
            //print("FilterConfiguration contents:...")
            //print ("FilterConfiguration.categoryDictionary: \(FilterConfiguration.categoryDictionary)")
            //print ("FilterConfiguration.categoryList: \(FilterConfiguration.categoryList)")
            //print ("FilterConfiguration.filterDictionary: \(FilterConfiguration.filterDictionary)")
            //print ("FilterConfiguration.categoryFilters: \(FilterConfiguration.categoryFilters)")
            
            /////////
            
            // Need to start somewhere...
            FilterManager.currCategory = defaultCategory
            //FilterManager.currIndex = FilterConfiguration.categoryList.index(of: defaultCategory)
            log.verbose("category: \(defaultCategory)")
            let list = FilterConfiguration.categoryFilters[defaultCategory]
            if (list != nil){
                if (list!.count > 0){
                    FilterManager.currFilterKey = list![0]
                    log.verbose("Current filter: \(FilterManager.currFilterKey)")
                } else {
                    log.error("No filters for category: \(defaultCategory)")
                    FilterManager.currFilterKey = FilterDescriptor.nullFilter
                }
                if (FilterDescriptorCache.get(key:FilterManager.currFilterKey) == nil){
                    FilterDescriptorCache.add(FilterFactory.createFilter(key: FilterManager.currFilterKey), key:FilterManager.currFilterKey)
                }
                FilterManager.currFilterDescriptor = (FilterDescriptorCache.get(key:FilterManager.currFilterKey))!
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
        //FilterManager.checkSetup()
    }
    
    deinit{
        FilterManager._categoryChangeCallbackList = []
        FilterManager._filterChangeCallbackList = []
    }
    
    
    public func restoreDefaults(){
        FilterConfiguration.restoreDefaults()
    }
    
    //////////////////////////////////////////////
    // MARK: - Category-related Accessors
    //////////////////////////////////////////////
    
    public func getCategoryList()->[String]{
        FilterManager.checkSetup()
        return FilterConfiguration.categoryList
    }
    
    public func getCategoryTitle(key:String)->String{
        FilterManager.checkSetup()
        return (FilterConfiguration.categoryDictionary[key])!
    }
    
    func getFilterCount(_ category:String)->Int {
        FilterManager.checkSetup()
        return (FilterConfiguration.categoryFilters[category]?.count)!
    }
    
    func getCategoryCount()->Int {
        FilterManager.checkSetup()
        return FilterConfiguration.categoryList.count
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
            
            if FilterConfiguration.categoryFilters[category] != nil {
                let count = (FilterConfiguration.categoryFilters[category]?.count)!
                if (count>0){
                    log.verbose ("\(count) items found")
                    let key = (FilterConfiguration.categoryFilters[category]?[0])!
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
    
    
    
    
    // 'Index' methods are provided to support previous/next types of navigation
    
    // get the index of the category within the category list.
    public func getCategoryIndex(category:String)->Int {
        var index:Int = -1
        
        FilterManager.checkSetup()
        if (FilterConfiguration.categoryList.count > 0){
            if (FilterConfiguration.categoryList.contains(category)){
                index = FilterConfiguration.categoryList.firstIndex(of: category)!
                //log.verbose("category:\(category) index:\(index)")
            } else {
                log.error("Category not found:\(category)")
            }
        } else {
            log.error("Empty Category List!!!")
        }
        return index
    }
    
    
    public func getCurrentCategoryIndex()->Int {
        
        return getCategoryIndex(category:FilterManager.currCategory)
    }
    
    
    public func getCategory(index: Int) -> String{
        FilterManager.checkSetup()
        var category:String = FilterManager.defaultCategory
        if ((index >= 0) && (index < FilterConfiguration.categoryList.count)){
            category =  FilterConfiguration.categoryList[index]
        }
        return category
    }
    
    
    //////////////////////////////////////////////
    // MARK: - Collection-related Accessors
    //////////////////////////////////////////////
    
    public func isValidCollection(_ collection: String) -> Bool {
        FilterManager.checkSetup()

        if FilterConfiguration.collectionDictionary[collection] != nil {
            return true
        } else {
            return false
        }
    }
    
    public func getCollectionList()->[String]{
        FilterManager.checkSetup()
        return FilterConfiguration.collectionList
    }
    
    public func getCollectionTitle(key:String)->String{
        FilterManager.checkSetup()
        return (FilterConfiguration.collectionDictionary[key])!
    }
    
    func getCategoryCount(_ collection:String)->Int {
        FilterManager.checkSetup()
        return (FilterConfiguration.collectionCategories[collection]?.count)!
    }
    
    func getCategoryList(collection:String)->[String] {
        FilterManager.checkSetup()
        // if collection is empty then return the full list of categories
        if collection.isEmpty {
            return FilterConfiguration.categoryList
        } else {
            return (FilterConfiguration.collectionCategories[collection])!
        }
    }

    func getCollectionCount()->Int {
        FilterManager.checkSetup()
        return FilterConfiguration.collectionList.count
    }
    
    func getCurrentCollection() -> String{
        FilterManager.checkSetup()
        return FilterManager.currCollection
        
    }
    
    func setCurrentCollection(_ collection:String){
        FilterManager.checkSetup()
        if (FilterManager.currCollection != collection){
            log.debug("Collection set to: \(collection)")
            FilterManager.currCollection = collection
            
            // set current filter to the first filter (alphabetically) in the dictionary
            
            if FilterConfiguration.collectionCategories[collection] != nil {
                let count = (FilterConfiguration.collectionCategories[collection]?.count)!
                if (count>0){
                    log.verbose ("\(count) items found")
                    let key = (FilterConfiguration.collectionCategories[collection]?[0])!
                    log.verbose("Setting category to: \(key)")
                    //setCurrentFilterKey(key)
                    setCurrentCategory(key)
                } else {
                    log.debug("List empty: \(collection)")
                    setCurrentFilterDescriptor(nil)
                }
            } else {
                log.error("NIL collection: \(collection)")
                setCurrentFilterDescriptor(nil)
            }
        }
    }
    
    
    
    
    // 'Index' methods are provided to support previous/next types of navigation
    
    // get the index of the collection within the collection list.
    public func getCollectionIndex(collection:String)->Int {
        var index:Int = -1
        
        FilterManager.checkSetup()
        if (FilterConfiguration.collectionList.count > 0){
            if (FilterConfiguration.collectionList.contains(collection)){
                index = FilterConfiguration.collectionList.firstIndex(of: collection)!
                //log.verbose("collection:\(collection) index:\(index)")
            } else {
                log.error("Collection not found:\(collection)")
            }
        } else {
            log.error("Empty Collection List!!!")
        }
        return index
    }
    
    
    public func getCurrentCollectionIndex()->Int {
        
        return getCollectionIndex(collection:FilterManager.currCollection)
    }
    
    
    public func getCollection(index: Int) -> String{
        FilterManager.checkSetup()
        var collection:String = FilterManager.defaultCollection
        if ((index >= 0) && (index < FilterConfiguration.collectionList.count)){
            collection =  FilterConfiguration.collectionList[index]
        }
        return collection
    }
    
    // the following are variants of the category-based index functions, but with a collection parameter
    // needed because the order changes based on which collection is being used
    
    // get the index of the category within the category list.
    public func getCategoryIndex(collection:String, category:String)->Int {
        var index:Int = -1
        
        FilterManager.checkSetup()
        let list = getCategoryList(collection: collection)
        if (list.count > 0){
            if (list.contains(category)){
                index = list.firstIndex(of: category)!
                //log.verbose("category:\(category) index:\(index)")
            } else {
                log.error("Category not found:\(category)")
            }
        } else {
            log.error("Empty Category List!!!")
        }
        return index
    }
    
    
    public func getCurrentCategoryIndex(collection:String)->Int {
        
        return getCategoryIndex(collection: collection, category:FilterManager.currCategory)
    }
    
    
    public func getCategory(collection:String, index: Int) -> String{
        FilterManager.checkSetup()
        let list = getCategoryList(collection: collection)
        var category:String = FilterManager.defaultCategory
        if ((index >= 0) && (index < FilterConfiguration.categoryList.count)){
            category =  list[index]
        }
        return category
    }
    
    
    
    //////////////////////////////////////////////
    // MARK: - Favourites-related Accessors
    //////////////////////////////////////////////
   
    // indicates whether a filter is in the "Favourites" category/list
    public func isFavourite(key: String) -> Bool {
        var result:Bool = false
        let index = getCategoryIndex(category: FilterManager.favouriteCategory)
        if (index>=0) {
            result = (FilterConfiguration.categoryFilters[FilterManager.favouriteCategory]?.contains(key))!
/***
            if (result) {
                log.verbose("Key: \(key) in favourites")
            } else {
                log.verbose("Key: \(key) NOT in favourites (\(index)): \(FilterConfiguration.categoryFilters[FilterManager.favouriteCategory])")
            }
 ***/
        } else {
            log.error("ERR: Favourites category not found")
        }
        return result
    }
    
    // add a filter to the "Favourites" list
    public func addToFavourites(key: String) {
        if (FilterDescriptorCache.get(key:key) != nil){ // filter exists
            if (!((FilterConfiguration.categoryFilters[FilterManager.favouriteCategory]?.contains(key))!)){ // not already there
                FilterConfiguration.categoryFilters[FilterManager.favouriteCategory]?.append(key)
                FilterConfiguration.commitChanges() // HACK: should update single record
            }
        } else {
            log.error("ERR: Unknown filter: \(key)")
        }
    }
    
    // remove a filter from the "Favourites" list
    public func removeFromFavourites(key: String) {
        if (FilterDescriptorCache.get(key:key) != nil){ // filter exists
            if ((FilterConfiguration.categoryFilters[FilterManager.favouriteCategory]?.contains(key))!){ // in list?
                if let index = FilterConfiguration.categoryFilters[FilterManager.favouriteCategory]?.firstIndex(of: key) {
                    FilterConfiguration.categoryFilters[FilterManager.favouriteCategory]?.remove(at: index)
                    FilterConfiguration.commitChanges() // HACK: should update single record
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
    
    // returns the next (alphabetical) key in the current catgeory, or the current key if there isn't a 'next'
    public func getNextFilterKey() -> String {
        FilterManager.checkSetup()
        
        var key = FilterManager.currFilterKey
        let category = FilterManager.currCategory
        var oldIndex:Int = 0
        var newIndex:Int = 0
        if (FilterDescriptorCache.get(key:key) != nil){ // filter exists
            if let list = FilterConfiguration.categoryFilters[category]?.sorted() {
                if list.count > 1 { // 0 or 1, just return current key
                    if list.contains(key) {
                        if let index = list.firstIndex(of:key) {
                            oldIndex = index
                            newIndex = (oldIndex < (list.count-1)) ? (oldIndex + 1) : 0
                            key = list[newIndex]
                        }
                    }
                }
            } else {
                log.error("Could not retrieve list for category: \(category)")
            }
        } else {
            log.error("ERR: Unknown filter: \(key)")
        }
        
        log.debug("[\(oldIndex)]:\(FilterManager.currFilterKey) => [\(newIndex)]:\(key)  category: \(category)")
        return key
    }
    
    // returns the previous (alphabetical) key in the current catgeory, or the current key if there isn't a 'previous'
    public func getPreviousFilterKey() -> String {
        FilterManager.checkSetup()
        
        var key = FilterManager.currFilterKey
        let category = FilterManager.currCategory
        
        if (FilterDescriptorCache.get(key:key) != nil){ // filter exists
            if let list = FilterConfiguration.categoryFilters[category]?.sorted() {
                if list.count > 1 { // 0 or 1, just return current key
                    if list.contains(key) {
                        if var index = list.firstIndex(of:key) {
                            index = (index > 0) ? (index - 1) : (list.count - 1)
                          key = list[index]
                        }
                    }
                }
            } else {
                log.error("Could not retrieve list for category: \(category)")
            }
        } else {
            log.error("ERR: Unknown filter: \(key)")
        }
        

        return key
    }
    
    
    
    public func getFilterList(_ category:String)->[String]?{
        FilterManager.checkSetup()
        if (FilterConfiguration.categoryFilters[category] != nil){
            return FilterConfiguration.categoryFilters[category]
        } else {
            log.error("Invalid category:\"\(category)\"")
            return []
        }
    }
    
    
    public static var shownFilterList:[String] = []
    
    public func getShownFilterList(_ category:String)->[String]?{
        //var key:String = ""
        
        FilterManager.checkSetup()
        if (FilterConfiguration.categoryFilters[category] != nil){
            FilterManager.shownFilterList = []
            let count:Int = (FilterConfiguration.categoryFilters[category]?.count)!
            if (count > 0){
                for key in FilterConfiguration.categoryFilters[category]! {
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
    public func getFilterDescriptor(key:String)->FilterDescriptor? {
        
        var filterDescr: FilterDescriptor? = nil
        
        FilterManager.checkSetup()
        
        if (FilterDescriptorCache.get(key:key) == nil){    // if not allocatd, try creating it, i.e. only created if requested

            //log.debug("Creating filter object for key:\(key)")
            filterDescr = FilterFactory.createFilter(key: key)

            if (filterDescr == nil){ // error somewhere
                log.error("NIL descriptor returned for key:\(key)")
            }
            
            FilterDescriptorCache.add(filterDescr, key:key)
            
        } else {
            filterDescr = FilterDescriptorCache.get(key:key)!
        }
        //log.verbose("Found key:\((filterDescr?.key)!) addr:\(filterAddress(filterDescr))")
        
        // make sure RenderView has been allocated
        if (!RenderViewCache.contains(key:key)){
            RenderViewCache.add(RenderView(), key:key)
        }

        return filterDescr
    }
  
    
    // 'Release' a filter descriptor. Should allow expensive OpenGL resources to be re-used
    public func releaseFilterDescriptor(key:String){
        
        if (!isLocked(key)){
            
            // release the filter descriptor
            if (FilterDescriptorCache.get(key:key) != nil){
                //let descr = (FilterDescriptorCache.get(key:key))!
                FilterDescriptorCache.remove(key:key)
                //log.debug("key:\(key)")
            }
            
            // make sure RenderView has been released
            if (RenderViewCache.get(key:key) != nil){
                releaseRenderView(key: key)
            }
        }
    }
    
    
    // 'Index' methods are provided to support previous/next types of navigation
    
    // get the index of the filter within the category list. -1 if not found
    public func getFilterIndex(category:String, key:String)->Int {
        
        FilterManager.checkSetup()
        
        var index = -1
        
        //let list = category.getFilterList()
        if ((FilterConfiguration.categoryFilters[category]?.contains(key))!){
            index = (FilterConfiguration.categoryFilters[category]?.firstIndex(of: key))!
        }
        
        return index
    }
    
    
    public func getCurrentFilterIndex()->Int {
   
        return getFilterIndex(category:FilterManager.currCategory, key:FilterManager.currFilterKey)
    }
    
    
    // returns the key based on the index in the list
    public func getFilterKey(category:String, index:Int)->String {
        
        var key: String = ""
        
        FilterManager.checkSetup()
        
        let count = (FilterConfiguration.categoryFilters[category]?.count)!
        if ((index>=0) && (index<count)){
            key = (FilterConfiguration.categoryFilters[category]?[index])!
        }
        
        return key
    }
    
    
    // returns the RenderView associated with the supplied filter key
    func getRenderView(key:String)->RenderView?{
        
        FilterManager.checkSetup()
        
        if (!RenderViewCache.contains(key:key)) {
            // not an error, just lazy allocation. Create the RenderView and add it to the dictionary
            log.debug("create key:\(key)")
            RenderViewCache.add(RenderView(), key:key)
        }
        
        return (RenderViewCache.get(key:key))
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
        
        if (RenderViewCache.get(key:key) != nil){
            if (!isLocked(key)){
                RenderViewCache.remove(key:key)
                //log.debug("key:\(key)")
            }
        }
    }
    
    
    public func isHidden(key:String) -> Bool {
        return FilterFactory.isHidden(key:key)
    }
    
    // designate a filter as hidden or not
    public func setHidden(key:String, hidden:Bool){
        FilterFactory.setHidden(key: key, hidden: hidden)
        FilterConfiguration.commitChanges() // HACK: should update single record
    }
    
    // get the rating for a filter
    public func getRating(key:String) -> Int{
        return FilterFactory.getRating(key:key)
    }
    
    // set the rating for a filter
    public func setRating(key:String, rating:Int){
        FilterFactory.setRating(key:key, rating:rating)
        FilterConfiguration.commitChanges() // HACK: should update single record
    }
    
    
    public func isSlow(key:String) -> Bool {
        return FilterFactory.isSlow(key:key)
    }
    
    // designate a filter as hidden or not
    public func setSlow(key:String, slow:Bool){
        FilterFactory.setSlow(key: key, slow: slow)
        FilterConfiguration.commitChanges() // HACK: should update single record
    }
    

    //////////////////////////////////////////////
    // MARK: - Style Transfer-related Accessors
    //////////////////////////////////////////////
    
   
    
    public func getStyleTransferList()->[String]?{
        FilterManager.checkSetup()
        return FilterConfiguration.styleTransferList
    }
    
    
    public static var shownStyleTransferList:[String] = []
    
    public func getShownStyleTransferList()->[String]?{
        
        FilterManager.checkSetup()
        FilterManager.shownStyleTransferList = []
        
/***
        let count:Int = (FilterConfiguration.styleTransferList.count)
        if (count > 0){
            for key in FilterConfiguration.styleTransferList {
                if (!FilterFactory.isHidden(key: key)){
                    FilterManager.shownStyleTransferList.append(key)
                }
            }
            
            FilterManager.shownStyleTransferList.sort(by: { (value1: String, value2: String) -> Bool in return value1 < value2 }) // sort ascending
        }
 ***/
        
        // just use the well-known style transfer category. This approach has uses elsewhere (e.g. navigation through filter lists)
        FilterManager.shownStyleTransferList = getFilterList(FilterManager.styleTransferCategory) ?? []
        if FilterConfiguration.styleTransferList.count > 0 {
            FilterManager.shownStyleTransferList.sort(by: { (value1: String, value2: String) -> Bool in return value1 < value2 }) // sort ascending
        }
        return FilterManager.shownStyleTransferList
    }
    
    
    //////////////////////////////////////////////
    // MARK: - Callback/Notification methods
    //////////////////////////////////////////////
    
  /***
    public func setCategoryChangeNotification(callback: ()) {
        FilterManager._categoryChangeCallbackList.append(callback)
    }
    
    
    public func setFilterChangeNotification(callback: ()) {
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
