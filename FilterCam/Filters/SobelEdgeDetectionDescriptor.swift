//
//  SobelEdgeDetectionDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/4/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage


class SobelEdgeDetectionDescriptor: FilterDescriptorInterface {



    let key = "SobelEdgeDetection"
    let title = "Sobel Edge Detection"
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 1
    let parameterConfiguration = [ParameterSettings(title:"edge strength", minimumValue:0.0, maximumValue:1.0, initialValue:0.4, isRGB:false)]

    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:SobelEdgeDetection = SobelEdgeDetection() // the actual filter
    fileprivate var stash_edgeStrength: Float
    

    init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.edgeStrength = parameterConfiguration[0].initialValue
        stash_edgeStrength = lclFilter.edgeStrength
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    
    func reset(){
        lclFilter.removeAllTargets()
        lclFilter = SobelEdgeDetection()
        restoreParameters()
    }
    
  func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(_ index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.edgeStrength
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(_ index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.edgeStrength = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    
    func getColorParameter(_ index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(_ index:Int, color:UIColor) {}
    
    
    func stashParameters() {
        stash_edgeStrength = lclFilter.edgeStrength
    }
    
    func restoreParameters(){
        lclFilter.edgeStrength = stash_edgeStrength
    }
}
