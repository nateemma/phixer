//
//  HazeDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/4/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage


class HazeDescriptor: FilterDescriptorInterface {
    
    
    let key = "Haze"
    let title = "Haze / UV"
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 2
    let parameterConfiguration = [ParameterSettings(title:"distance", minimumValue:-0.3, maximumValue:0.3, initialValue:0.1, isRGB:false),
                                  ParameterSettings(title:"slope", minimumValue:-0.3, maximumValue:0.3, initialValue:0.0, isRGB:false)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:Haze = Haze() // the actual filter
    fileprivate var stash_distance: Float
    fileprivate var stash_slope: Float
    
    
    init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.distance = parameterConfiguration[0].initialValue
        stash_distance = lclFilter.distance
        stash_slope = lclFilter.slope
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func reset(){
        lclFilter.removeAllTargets()
        lclFilter = Haze()
        restoreParameters()
    }
    
   
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    
    func getParameter(_ index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.distance
        case 2:
            return lclFilter.slope
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(_ index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.distance = value
            log.debug("\(parameterConfiguration[index-1].title):\(value)")
            break
        case 2:
            lclFilter.slope = value
            log.debug("\(parameterConfiguration[index-1].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    
    func getColorParameter(_ index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(_ index:Int, color:UIColor) {}
    
    
    func stashParameters(){
        stash_distance = lclFilter.distance
        stash_slope = lclFilter.slope
    }
    
    func restoreParameters(){
        lclFilter.distance = stash_distance
        lclFilter.slope = stash_slope
    }
}
