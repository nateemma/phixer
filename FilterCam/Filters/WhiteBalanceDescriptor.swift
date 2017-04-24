//
//  WhiteBalanceDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/4/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage


class WhiteBalanceDescriptor: FilterDescriptorInterface {
    
    
    let key = "WhiteBalance"
    let title = "White Balance"
    
    var show: Bool = true
    var rating: Int = 0

    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 2
    let parameterConfiguration = [ParameterSettings(title:"temperature", minimumValue:2500.0, maximumValue:7500.0, initialValue:5000.0, isRGB:false),
                                  ParameterSettings(title:"tint", minimumValue:-200.0, maximumValue:200.0, initialValue:0.0, isRGB:false)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:WhiteBalance = WhiteBalance() // the actual filter
    fileprivate var stash_temperature: Float
    fileprivate var stash_tint: Float
    
    
    required init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.temperature = parameterConfiguration[0].initialValue
        lclFilter.tint = parameterConfiguration[1].initialValue
        stash_temperature = lclFilter.temperature
        stash_tint = lclFilter.tint
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func reset(){
        lclFilter.removeAllTargets()
        lclFilter = WhiteBalance()
        restoreParameters()
    }
    
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    
    func getParameter(_ index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.temperature
        case 2:
            return lclFilter.tint
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(_ index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.temperature = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        case 2:
            lclFilter.tint = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    
    func getColorParameter(_ index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(_ index:Int, color:UIColor) {}
    
    
    func stashParameters(){
        stash_temperature = lclFilter.temperature
        stash_tint = lclFilter.tint
    }
    
    func restoreParameters(){
        lclFilter.temperature = stash_temperature
        lclFilter.tint = stash_tint
    }
}
