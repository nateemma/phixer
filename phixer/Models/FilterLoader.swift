//
//  FilterLoader.swift
//  phixer
//
//  Created by Philip Price on 7/31/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

// Utilities to load/unload filters to/from the FilterManager and Image caches.
// Each filter is loaded on a single thread. Useful when lists of filters need to displayed while still allowing the UI to run

import Foundation

class FilterLoader {
    
    
    private var workList:[String] = []
    
    private static var filterManager = FilterManager.sharedInstance
    private var inputImage:CIImage? = nil
    private var blend:CIImage? = nil
    private var imgSize:CGSize = CGSize.zero
    private var updateHandler: ((_ key:String)->())? = nil
    private var completionHandler: (()->())? = nil

    init() {
        workList = []
        inputImage = nil
        blend = nil
        imgSize = CGSize.zero
        updateHandler = nil
        completionHandler = nil
    }
    
    deinit {
        unload()
    }
    
    ///////////////////////////
    // Accessors
    ///////////////////////////
    
    // set the list of filters
    public func setFilters(_ list:[String]){
        workList = list
    }
    
    // loads the list of filters one at a time
    // update() is called after each filter is loaded. completion() is called when all filters have been loaded
    public func load(image: CIImage?, update: @escaping (_ key:String)->(), completion: @escaping ()->()){
        
        // this is a little tricky. We can't load all of the filters at once because it holds up the main thread too much.
        // However, we can't run all of the processing on the background thread because some image libraries are used
        // So,we break it up into pieces that we run on the main thread one at a time

        guard (image != nil) else {
            log.error("NIL input image")
            return
        }
        
        if (self.workList.count > 0){
            self.inputImage = image
            self.imgSize = (image?.extent.size)!
            updateHandler = update
            completionHandler = completion
            processWorkItem() // this is recursive
        }
    }
    
    
    // unload everything that was loaded
    public func unload() {
        if (self.workList.count > 0){
            for key in workList {
                FilterLoader.filterManager.releaseRenderView(key: key)
                FilterLoader.filterManager.releaseFilterDescriptor(key: key)
                ImageCache.remove(key: key)
            }
        }
        inputImage = nil
        blend = nil
    }

    ///////////////////////////
    // Internal
    ///////////////////////////
    

    // recursively process the work list until it is empty
    private func processWorkItem(){
        // Note that this must be done on the main thread since we are interacting with images
        DispatchQueue.main.async(execute: { [unowned self] in
            
            //if self != nil {
                if self.workList.count > 0 { // warning: can change e.g. fast scrolling through categories by user
                    // process the next filter and call the update handler
                    let key = self.workList[0]
                    if !key.isEmpty {
                        self.loadFilter(key)
                        if self.updateHandler != nil {
                            self.updateHandler!(key)
                        }
                    }
                    
                    // remove this entry
                    self.workList.remove(at: 0)
                    
                    // if we're done then call the completion handler, otherwise repeat
                    if self.workList.count <= 0 {
                        if self.completionHandler != nil {
                            self.completionHandler!()
                        }
                    } else {
                        // not done, recursively call to process next item
                        self.processWorkItem()
                    }
                }
            //} else {
            //    log.error("NIL self")
            //}
        })
    }
    
    // load an individual filter
    private func loadFilter(_ key: String){
        
        if self.inputImage != nil {
 
            // get the descriptor and renderview. This also leaves them cached for later use
            let descriptor = FilterLoader.filterManager.getFilterDescriptor(key: key)
            let renderview = FilterLoader.filterManager.getRenderView(key: key)
            renderview?.setImageSize(self.imgSize)

            // if this is a 'blend' filter then load blend image
            if descriptor?.filterOperationType == FilterOperationType.blend {
                if self.blend == nil { // lazy loading, most filters will not be blended
                    self.blend = ImageManager.getCurrentBlendImage(size: self.imgSize)
                }
            }
            // get image from cache
            var image = ImageCache.get(key: key)
            
            // apply the filter
            image = descriptor?.apply(image:self.inputImage, image2: self.blend)
            if image != nil {
                
                // replace the image in the cache
                ImageCache.add(image, key: key)
            } else {
                log.error("Filter returned NIL")
            }
        } else {
            log.error("Input is NIL")
        }
        
    }
    
    
}
