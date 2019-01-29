//
//  FilterDefinition.swift
//  phixer
//
//  Created by Philip Price on 1/7/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//


// structs used for holding data retrived from config files, i.e. mostly string-based

import Foundation

// the type of the parameter
public enum ParameterType {
    case float
    case color
    case image
    case position
    case rectangle
    case vector
    case unknown
    
}

// set of parameters that are used to set up a filter
public struct ParameterSettings {
    var key:String
    var title:String
    var min:Float
    var max:Float
    var value:Float
    var type:ParameterType
    
    init(key:String, title:String, min:Float, max:Float, value:Float, type:ParameterType){
        self.key = key
        self.title = title
        self.min = min
        self.max = max
        self.value = value
        self.type = type
    }
}


// identifies the general type of filter, so that an app can configure it properly (e.g. with 2 images instead of 1)
// Note: declared as String so that you can convert a String (str) to an enum by ftype = FilterOperationType(rawValue:str)
public enum FilterOperationType: String {
    case singleInput
    case blend
    case lookup
    case custom
}


// struct defining a filter
public struct FilterDefinition{
    var key: String = ""
    var title: String = ""
    var ftype: String = ""
    var slow: Bool = false
    var hide: Bool = false
    var rating: Int = 0
    var parameters: [ParameterSettings] = []
    var lookup: String = ""
}
