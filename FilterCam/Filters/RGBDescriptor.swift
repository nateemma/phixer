//
//  RGBDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/4/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage


class RGBDescriptor: FilterDescriptorInterface {
    
    
    let key = "RGB"
    let title = "RGB"
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 3
    let parameterConfiguration = [ParameterSettings(title:"red", minimumValue:0.0, maximumValue:1.0, initialValue:0.5, isRGB:false),
                                  ParameterSettings(title:"green", minimumValue:0.0, maximumValue:1.0, initialValue:0.5, isRGB:false),
                                  ParameterSettings(title:"blue", minimumValue:0.0, maximumValue:1.0, initialValue:0.5, isRGB:false)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    private var lclFilter:RGBAdjustment = RGBAdjustment() // the actual filter
    private var stash_red: Float
    private var stash_green: Float
    private var stash_blue: Float
    
    
    init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.red = parameterConfiguration[0].initialValue
        lclFilter.green = parameterConfiguration[1].initialValue
        lclFilter.blue = parameterConfiguration[2].initialValue
        stash_red = lclFilter.red
        stash_green = lclFilter.green
        stash_blue = lclFilter.blue
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    
    func getParameter(index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.red
        case 2:
            return lclFilter.green
        case 3:
            return lclFilter.blue
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.red = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        case 2:
            lclFilter.green = value
            log.debug("\(parameterConfiguration[1].title):\(value)")
            break
        case 3:
            lclFilter.blue = value
            log.debug("\(parameterConfiguration[2].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    func getColorParameter(index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(index:Int, color:UIColor) {}
    
    
    //func updateParameters(value1:Float, value2:Float,  value3:Float,  value4:Float){
    //    lclFilter.red = value1
    //}
    
    func stashParameters(){
        stash_red = lclFilter.red
        stash_green = lclFilter.green
        stash_blue = lclFilter.blue
    }
    
    func restoreParameters(){
        lclFilter.red = stash_red
        lclFilter.green = stash_green
        lclFilter.blue = stash_blue
    }
}
