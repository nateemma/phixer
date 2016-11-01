//
//  LevelsAdjustmentDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage



//NOTE: this is a strange implementation. It uses Color parameters, but it is really a set of adjustments for each color individually
// This implementation just applies the same adjustment to all components equally

class LevelsAdjustmentDescriptor: FilterDescriptorInterface {
    
    
    
    let key = "LevelsAdjustment"
    let title = "LevelsAdjustment"
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 5
    let parameterConfiguration = [ParameterSettings(title:"minOutput", minimumValue:0.0, maximumValue:1.0, initialValue:0.00, isRGB:false),
                                  ParameterSettings(title:"minimum", minimumValue:0.0, maximumValue:1.0, initialValue:0.10, isRGB:false),
                                  ParameterSettings(title:"middle", minimumValue:0.0, maximumValue:1.0, initialValue:0.50, isRGB:false),
                                  ParameterSettings(title:"maximum", minimumValue:0.0, maximumValue:1.0, initialValue:0.90, isRGB:false),
                                  ParameterSettings(title:"maxOutput", minimumValue:0.0, maximumValue:1.0, initialValue:1.00, isRGB:false)]
    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:LevelsAdjustment = LevelsAdjustment() // the actual filter
    fileprivate var stash_minimum: Float
    fileprivate var stash_middle: Float
    fileprivate var stash_maximum: Float
    fileprivate var stash_minOutput: Float
    fileprivate var stash_maxOutput: Float
    
    
    init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type

        // a little different from other filters since we are storing a single value that is applied to all color components 
        // in the underlying LevelsAdjustment filter
        stash_minOutput = parameterConfiguration[0].initialValue
        stash_minimum = parameterConfiguration[1].initialValue
        stash_middle = parameterConfiguration[2].initialValue
        stash_maximum = parameterConfiguration[3].initialValue
        stash_maxOutput = parameterConfiguration[4].initialValue

        lclFilter.minOutput = getColorFromValue(stash_minOutput)
        lclFilter.minimum = getColorFromValue(stash_minimum)
        lclFilter.middle = getColorFromValue(stash_middle)
        lclFilter.maximum = getColorFromValue(stash_maximum)
        lclFilter.maxOutput = getColorFromValue(stash_maxOutput)

        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func reset(){
        lclFilter.removeAllTargets()
        lclFilter = LevelsAdjustment()
        restoreParameters()
    }
    
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(_ index: Int)->Float {
        switch (index){
        case 1:
            return getValueFromColor(lclFilter.minOutput)
        case 2:
            return getValueFromColor(lclFilter.minimum)
        case 3:
            return getValueFromColor(lclFilter.middle)
        case 4:
            return getValueFromColor(lclFilter.maximum)
        case 5:
            return getValueFromColor(lclFilter.maxOutput)
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(_ index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.minOutput = getColorFromValue(value)
            log.debug("\(parameterConfiguration[index-1].title):\(value)")
            break
        case 2:
            lclFilter.minimum = getColorFromValue(value)
            log.debug("\(parameterConfiguration[index-1].title):\(value)")
            break
        case 3:
            lclFilter.middle = getColorFromValue(value)
            log.debug("\(parameterConfiguration[index-1].title):\(value)")
            break
        case 4:
            lclFilter.maximum = getColorFromValue(value)
            log.debug("\(parameterConfiguration[index-1].title):\(value)")
            break
        case 5:
            lclFilter.maxOutput = getColorFromValue(value)
            log.debug("\(parameterConfiguration[index-1].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    func getColorParameter(_ index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(_ index:Int, color:UIColor) {}
    
    
    fileprivate func getColorFromValue(_ value: Float)->Color{
        let color:Color = Color(red: value, green: value, blue: value, alpha: 1.0)
        return color
    }
    
    
    fileprivate func getValueFromColor(_ color: Color)->Float{
        return Float(color.redComponent)
    }
    

    
    
    func stashParameters() {
        stash_minimum = getValueFromColor(lclFilter.minimum)
        stash_middle = getValueFromColor(lclFilter.middle)
        stash_maximum = getValueFromColor(lclFilter.maximum)
        stash_minOutput = getValueFromColor(lclFilter.minOutput)
        stash_maxOutput = getValueFromColor(lclFilter.maxOutput)
    }
    
    func restoreParameters(){
        lclFilter.minimum = getColorFromValue(stash_minimum)
        lclFilter.middle = getColorFromValue(stash_middle)
        lclFilter.maximum = getColorFromValue(stash_maximum)
        lclFilter.minOutput = getColorFromValue(stash_minOutput)
        lclFilter.maxOutput = getColorFromValue(stash_maxOutput)
    }
}
