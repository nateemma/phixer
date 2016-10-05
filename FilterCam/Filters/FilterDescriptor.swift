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



enum FilterSliderSetting {
    case disabled
    case enabled(minimumValue:Float, maximumValue:Float, initialValue:Float)
}


enum FilterOperationType {
    case singleInput
    case blend
    //TODO: user-defined and custom types (see GPUImage)
}



protocol FilterDescriptorInterface{
    var listName: String { get }
    var titleName: String { get }
    var category: String { get }
    var filter: BasicOperation? { get }
    var filterGroup: OperationGroup? { get }
    var slider1Configuration: FilterSliderSetting { get } // 3 sliders max
    var slider2Configuration: FilterSliderSetting { get }
    var slider3Configuration: FilterSliderSetting { get }
    var filterOperationType: FilterOperationType { get }
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?))
    func updateBasedOnSliderValues(_ slider1Value:Float, slider2Value:Float,  slider3Value:Float)
    
}

