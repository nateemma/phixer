//
//  FilterManager
//  FilterCam
//
//  Created by Philip Price on 10/5/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage
import SwiftyJSON

// class that manages the list of available filters and groups them into categories



// SIngleton class that provides access to the categories/filters
// use FilterManager.sharedInstance to get a reference

class FilterManager{
    
    static let sharedInstance = FilterManager() // the actual instance shared by everyone
    
    open static let defaultCategory = "quickselect"

    fileprivate static var initDone:Bool = false
    fileprivate static var currCategory: String = defaultCategory
    fileprivate static var currFilterDescriptor: FilterDescriptorInterface? = nil
    fileprivate static var currFilterKey: String = ""
    //fileprivate static var currIndex:Int = -1
    

    static let sortClosure = { (value1: String, value2: String) -> Bool in return value1 < value2 }
   
    
    //////////////////////////////////////////////
    //MARK: - Category/Filter "Database"
    //////////////////////////////////////////////

    // typealias for dictionaries of FilterDescriptors
    
    fileprivate static var _renderViewDictionary:[String:RenderView?] = [:]
    
    // list of callbacks for change notification
    fileprivate static var _categoryChangeCallbackList:[()] = []
    fileprivate static var _filterChangeCallbackList:[()] = []
    
    //////////////////////////////////////////////
    //MARK: - Setup/Teardown
    //////////////////////////////////////////////
    
    fileprivate static func checkSetup(){
        if (!FilterManager.initDone) {
            FilterManager.initDone = true
            
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
                    FilterManager.currFilterKey = "Crosshatch"
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
                log.verbose("category:\(category) index:\(index)")
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
    // MARK: - Filter-related Accessors
    //////////////////////////////////////////////
    
    
    
    func getCurrentFilterDescriptor() -> FilterDescriptorInterface?{
        FilterManager.checkSetup()
        return FilterManager.currFilterDescriptor
    }
    
    func setCurrentFilterDescriptor(_ descriptor: FilterDescriptorInterface?){
        FilterManager.checkSetup()
        if (FilterManager.currFilterDescriptor?.key != descriptor?.key){
            FilterManager.currFilterDescriptor = descriptor
            if (descriptor != nil){
                FilterManager.currFilterKey = (descriptor?.key)!
            } else {
                FilterManager.currFilterKey = ""
            }
            
            log.debug("Filter changed to: \(descriptor?.key)")
            
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
    
    
    
    // get the filter descriptor for the supplied filter type
    open func getFilterDescriptor(key:String)->FilterDescriptorInterface? {
        
        var filterDescr: FilterDescriptorInterface? = nil
        
        FilterManager.checkSetup()
        
        if (FilterLibrary.filterDictionary[key] == nil){    // if not allocatd, try creating it, i.e. only created if requested
            
            // check to see if this is a lookup filter. If so, then use the key for the 'base' lokup filter
            // NOTE: make sure the base filter is in the list of filters at startup
            if (FilterLibrary.lookupDictionary[key] != nil){
                let lookupkey = "LookupFilter" // TODO: better way to mange string?!
                log.debug("Creating lookup filter object for key:\(key)")
                filterDescr = FilterFactory.createFilter(key: lookupkey)
            } else {
                log.debug("Creating filter object for key:\(key)")
                filterDescr = FilterFactory.createFilter(key: key)
            }
            
            if (filterDescr == nil){ // error somewhere
                log.error("NIL descriptor returned for key:\(key)")
            }
            
            FilterLibrary.filterDictionary[key] = filterDescr
            
            // class-specific processing:
            if (filterDescr is LookupFilterDescriptor){
                initLookupFilter(key: key)
            }

        } else {
            filterDescr = FilterLibrary.filterDictionary[key]!
        }
        //log.verbose("Found key:\((filterDescr?.key)!) addr:\(filterAddress(filterDescr))")
        
        // make sure RenderView has been allocated
        if (FilterManager._renderViewDictionary[key] == nil){
            FilterManager._renderViewDictionary[key] = RenderView()
        }

        return filterDescr
    }
  
    
    // 'Release' a filter descriptor. Should allow expensive OpenGL resources to be re-used
    open func releaseFilterDescriptor(key:String){
        
        // release the filter descriptor
        if (FilterLibrary.filterDictionary[key] != nil){
            let descr = (FilterLibrary.filterDictionary[key])!
            descr?.filter?.removeAllTargets()
            descr?.filterGroup?.removeAllTargets()
            FilterLibrary.filterDictionary[key] = nil
            log.debug("key:\(key)")
        }
        
        
        // make sure RenderView has been released
        if (FilterManager._renderViewDictionary[key] != nil){
            releaseRenderView(key: key)
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
    
  /***
    func addFilterDescriptor(category:String, key:String, descriptor:FilterDescriptorInterface?){
        // add to the filter list
        FilterLibrary.filterDictionary[key] = descriptor
        
        //add to category list
        var list = category.getFilterList()
        if (!(list.contains(key))){
            list.append(key)
            FilterManager.sortLists()
        }
    }
    
    func removeFilterDescriptor(category:String, key:String){
        var list = category.getFilterList()
        if let index = list.index(of: key) {
            list.remove(at: index)
            log.verbose ("Key (\(key)) removed from category (\(category))")
        }else {
            log.warning("Key (\(key)) not present for category (\(category))")
        }
    }
    ***/
    
    func filterAddress(_ descriptor:FilterDescriptorInterface?)->String{
        var addr:String
        guard (descriptor != nil) else {
            return "NIL"
        }
        
        if (descriptor?.filter != nil){
            addr = Utilities.addressOf(descriptor?.filter) + " (filter)"
        } else  if (descriptor?.filterGroup != nil){
            addr = Utilities.addressOf(descriptor?.filterGroup) + " (group)"
        } else {
            addr = "INVALID"
        }
        return addr
    }
    
    
    
    // returns the RenderView associated with the supplied filter key
    func getRenderView(key:String)->RenderView?{
        
        FilterManager.checkSetup()
        
        if (FilterManager._renderViewDictionary[key] != nil){
            log.debug("reuse key:\(key)")
            //renderView = (FilterManager._renderViewDictionary[key])!
        } else {
            // not an error, just lazy allocation. Create the RenderView and add it to the dictionary
            log.debug("create key:\(key)")
            FilterManager._renderViewDictionary[key] = RenderView()
        }
        
        return (FilterManager._renderViewDictionary[key])!
    }
    
    
    
    // releases the RenderView associated with the supplied filter key
    func releaseRenderView(key:String){
        
        FilterManager.checkSetup()
        
        if (FilterManager._renderViewDictionary[key] != nil){
            FilterManager._renderViewDictionary[key] = nil
            log.debug("key:\(key)")
        }
    }
    
    
    // class-specific init of LookupFilterDescriptor
    fileprivate func initLookupFilter(key: String){
        
        var lookup:LookupFilterDescriptor? = nil
        
        // set the image file for this key
        if (FilterLibrary.lookupDictionary[key] != nil){
            
            lookup = FilterLibrary.filterDictionary[key] as! LookupFilterDescriptor?
            let image:String = (FilterLibrary.lookupDictionary[key])!
            log.debug("key:\(key), image:\(image)")
            
            let l = image.components(separatedBy:".")
            let title = l[0]
            lookup?.key = key
            lookup?.title = title
            
            lookup?.setLookupFile(name:image)
            FilterLibrary.filterDictionary[key] = lookup
            
        } else {
            log.error("ERR: Entry not found for LookupFilter:\(key)")
        }
        
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
