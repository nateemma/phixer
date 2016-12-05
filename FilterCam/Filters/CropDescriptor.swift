//
//  CropDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/4/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage


class CropDescriptor: FilterDescriptorInterface {
    
    
    let key = "Crop"
    let title = "Crop"
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 1
    let parameterConfiguration = [ParameterSettings(title:"factor", minimumValue:0.0, maximumValue:1.0, initialValue:1.0, isRGB:false)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:Crop = Crop() // the actual filter
    fileprivate var stash_cropSizeInPixels: Size
    fileprivate var currFactor: Float
    fileprivate var screenSize: Size
    
    
    required init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        let res = CameraManager.getCaptureResolution()
        screenSize = Size(width: Float(res.width), height: Float(res.height))

        currFactor = parameterConfiguration[0].initialValue
        lclFilter.cropSizeInPixels = Size(width: currFactor*screenSize.width, height: currFactor*screenSize.height)
        stash_cropSizeInPixels = lclFilter.cropSizeInPixels!
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func reset(){
        lclFilter.removeAllTargets()
        lclFilter = Crop()
        restoreParameters()
    }
    
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    
    func getParameter(_ index: Int)->Float {
        switch (index){
        case 1:
            return currFactor
        default:
            return parameterNotSet
        }
    }
    
    
    //TODO: scale crop size based on parameter
    
    func setParameter(_ index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.cropSizeInPixels = Size(width: currFactor*screenSize.width, height: currFactor*screenSize.height)
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    
    func getColorParameter(_ index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(_ index:Int, color:UIColor) {}
    
    
    func stashParameters(){
        stash_cropSizeInPixels = lclFilter.cropSizeInPixels!
    }
    
    func restoreParameters(){
        lclFilter.cropSizeInPixels = stash_cropSizeInPixels
    }
}
