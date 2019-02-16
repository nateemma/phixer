//
//  FilterChain.swift
//  phixer
//
//  Created by Philip Price on 2/13/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//


// This is a class that presents a chain of filters such that it looks like a single FilterDescriptor to other components
// This is intended for implementing an all-or-nothing group of filters

import Foundation


class FilterChain: FilterDescriptor {
    
    override var key: String { return "FilterChain" }
    override var title: String { return "[Group]" }
    override var filterOperationType: FilterOperationType { return FilterOperationType.singleInput }
    override var numParameters: Int { return 0 }
    override var parameterConfiguration: [String: ParameterSettings]  { return [:] }
    

    private var filterList: [FilterDescriptor] = []
    
    override init() {
        super.init()
        
        show = false
        filterList = []
    }
    
    
    // override the 'apply' method to run the chain of filters
    override func apply (image: CIImage?, image2: CIImage? = nil) -> CIImage? {
        
        guard image != nil else {
            log.error("NIL image supplied")
            return nil
        }
        
        var outImage:CIImage? = image
        var tmpImage:CIImage? = image
        
        // apply the list of filters
        if filterList.count > 0 {
            for f in filterList {
                tmpImage = f.apply(image: outImage)
                outImage = tmpImage
            }
        }
        
        return outImage
    }

    // sets the list of FilterDescriptors. raplaces anything already there
    public func setFilters(_ filters: [FilterDescriptor]) {
        self.filterList = []
        self.filterList = filters
    }
    
    // append a FilterDescriptor to the existing list
    public func appendFilter(_ filter: FilterDescriptor) {
        self.filterList.append(filter)
    }
    
    public func clear() {
        self.filterList = []
    }
}
