//
//  CrosshatchDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/4/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage


class CrosshatchDescriptor: FilterDescriptorInterface {


    let key = "Crosshatch"
    let title = "Crosshatch"
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    
    let numParameters = 2
    let parameterConfiguration = [ParameterSettings(title:"spacing", minimumValue:0.01, maximumValue:0.06, initialValue:0.03, isRGB:false),
                                  ParameterSettings(title:"line width", minimumValue:0.001, maximumValue:0.006, initialValue:0.003, isRGB:false)]

    
    let filterOperationType = FilterOperationType.singleInput
    
    private var lclFilter:Crosshatch = Crosshatch() // the actual filter
    private var stash_crossHatchSpacing: Float
    private var stash_lineWidth: Float
    

    init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.crossHatchSpacing = parameterConfiguration[0].initialValue
        lclFilter.lineWidth = parameterConfiguration[1].initialValue
        stash_crossHatchSpacing = lclFilter.crossHatchSpacing
        stash_lineWidth = lclFilter.lineWidth
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    //func updateParameters(value1:Float, value2:Float,  value3:Float,  value4:Float){
    //    lclFilter.crossHatchSpacing = value1
    //    lclFilter.lineWidth = value2
    //}
    
    
    
    func getParameter(index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.crossHatchSpacing
        case 2:
            return lclFilter.lineWidth
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.crossHatchSpacing = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        case 2:
            lclFilter.lineWidth = value
            log.debug("\(parameterConfiguration[1].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }

    
    func getColorParameter(index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(index:Int, color:UIColor) {}
    
    
    func stashParameters() {
        stash_crossHatchSpacing = lclFilter.crossHatchSpacing
        stash_lineWidth = lclFilter.lineWidth

    }
    
    func restoreParameters(){
        lclFilter.crossHatchSpacing = stash_crossHatchSpacing
        lclFilter.lineWidth = stash_lineWidth
    }

}
