//
//  PolarPixellateDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/4/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage


class PolarPixellateDescriptor: FilterDescriptorInterface {


    let key = "PolarPixellate"
    let title = "Polar Pixellate"
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 1
    let parameterConfiguration = [ParameterSettings(title:"pixel size", minimumValue:-0.1, maximumValue:0.1, initialValue:0.05, isRGB:false)]

    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:PolarPixellate = PolarPixellate() // the actual filter
    fileprivate var stash_pixelSize: Size
    fileprivate var stash_pixelEdge: Float
    fileprivate var pixelEdge: Float
    

    init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        pixelEdge = parameterConfiguration[0].initialValue
        stash_pixelEdge = pixelEdge
        lclFilter.pixelSize = Size(width:pixelEdge, height:pixelEdge)
        stash_pixelSize = Size(width:pixelEdge, height:pixelEdge)
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(_ index: Int)->Float {
        switch (index){
        case 1:
            return pixelEdge
        default:
            return parameterNotSet
        }
    }

    
    func setParameter(_ index: Int, value: Float) {
        switch (index){
        case 1:
            pixelEdge = value
            lclFilter.pixelSize = Size(width:value, height:value)
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    func getColorParameter(_ index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(_ index:Int, color:UIColor) {}
    
    
    func stashParameters(){
        stash_pixelSize = lclFilter.pixelSize
        stash_pixelEdge = pixelEdge
    }
    
    func restoreParameters(){
        lclFilter.pixelSize = stash_pixelSize
        pixelEdge = stash_pixelEdge
    }
}
