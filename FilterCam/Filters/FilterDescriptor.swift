//
//  FilterDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/4/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage

// Types/protocol that defines data needed to find, describe, modify and invoke a filter or FilterGroup
// Intended to form the 'bridge' between UI functionality and Filter Operations
// This is the equivalent of an Abstract/Base class, descriptors for each specific type of filter must implement this



typealias ParameterSettings = (title:String, minimumValue:Float, maximumValue:Float, initialValue:Float)


enum FilterOperationType {
    case singleInput
    case blend
    //TODO: user-defined and custom types (see GPUImage FilterShowcase example)
}


let parameterNotSet:Float = -1000.00

protocol FilterDescriptorInterface{
    var key: String { get }
    var title: String { get }
    var category: FilterCategoryType { get }
    var filter: BasicOperation? { get }
    var filterGroup: OperationGroup? { get }
    var numSliders: Int { get } // 4 sliders max
    var parameterConfiguration: [ParameterSettings] { get }
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?))
    
    func getParameter(index:Int)->Float
    func setParameter(index:Int, value:Float)
    //func updateParameters(value1:Float, value2:Float,  value3:Float,  value4:Float)
    func stashParameters()
    func restoreParameters()
    
}

