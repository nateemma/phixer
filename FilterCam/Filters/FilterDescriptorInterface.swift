//
//  FilterDescriptorInterface.swift
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


// settings for each filter parameter. isRGB indicates to use an RGB/HSB color gradient slider (i.e. to choose a color)
typealias ParameterSettings = (title:String, minimumValue:Float, maximumValue:Float, initialValue:Float, isRGB:Bool)


enum FilterOperationType {
    case singleInput
    case blend
    //TODO: user-defined and custom types (see GPUImage FilterShowcase example)
}


let parameterNotSet:Float = -1000.00

protocol FilterDescriptorInterface{
    var key: String { get }
    var title: String { get }

    var filter: BasicOperation? { get }
    var filterGroup: OperationGroup? { get }
    
    var filterOperationType: FilterOperationType { get }
    
    var numParameters: Int { get } // 5 sliders max
    var parameterConfiguration: [ParameterSettings] { get }
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?))
    
    // Parameter access for Float parameters (most of them)
    func getParameter(_ index:Int)->Float
    func setParameter(_ index:Int, value:Float)
    
    // Parameter access for Color parameters
    func getColorParameter(_ index: Int)->UIColor
    func setColorParameter(_ index:Int, color:UIColor)
    
    //func updateParameters(value1:Float, value2:Float,  value3:Float,  value4:Float)
    func stashParameters()
    func restoreParameters()
    
    
    func reset()
}

