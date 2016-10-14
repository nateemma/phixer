//
//  XXX2Descriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


class XXX2Descriptor: FilterDescriptorInterface {
    
    
    
    let key = "XXX2"
    let title = "XXX2"
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 2
    let parameterConfiguration = [ParameterSettings(title:"xxx", minimumValue:0.0, maximumValue:1.0, initialValue:0.5, isRGB:false),
                                  ParameterSettings(title:"yyy", minimumValue:0.0, maximumValue:1.0, initialValue:0.25, isRGB:false)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    private var lclFilter:XXX2 = XXX2() // the actual filter
    private var stash_xxx: Float
    private var stash_yyy: Float
    
    
    init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.xxx = parameterConfiguration[0].initialValue
        lclFilter.yyy = parameterConfiguration[1].initialValue
        stash_xxx = lclFilter.xxx
        stash_yyy = lclFilter.yyy
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.xxx
        case 2:
            return lclFilter.yyy
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.xxx = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        case 2:
            lclFilter.yyy = value
            log.debug("\(parameterConfiguration[1].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    
    func getColorParameter(index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(index:Int, color:UIColor) {}
    
    
    func stashParameters() {
        stash_xxx = lclFilter.xxx
        stash_yyy = lclFilter.yyy
    }
    
    func restoreParameters(){
        lclFilter.xxx = stash_xxx
        lclFilter.yyy = stash_yyy
    }
}
