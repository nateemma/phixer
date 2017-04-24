//
//  RotateDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/4/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage
import CoreGraphics


class RotateDescriptor: FilterDescriptorInterface {

    
    let key = "Rotate"
    let title = "Rotate"
    
    var show: Bool = true
    var rating: Int = 0

    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 1
    let parameterConfiguration = [ParameterSettings(title:"rotation", minimumValue:0.0, maximumValue:6.28, initialValue:0.75, isRGB:false)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:TransformOperation = TransformOperation() // the actual filter
    
    fileprivate var currRotation: Float
    fileprivate var stash_rotation: Float
    fileprivate var stash_transform: Matrix4x4
    

    
    required init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        stash_rotation = parameterConfiguration[0].initialValue
        currRotation = stash_rotation
        lclFilter.transform = Matrix4x4(CGAffineTransform(rotationAngle: CGFloat(currRotation)))
        stash_transform = lclFilter.transform
        
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func reset(){
        lclFilter.removeAllTargets()
        lclFilter = TransformOperation()
        restoreParameters()
    }
    
   
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    
    func getParameter(_ index: Int)->Float {
        switch (index){
        case 1:
            return currRotation
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(_ index: Int, value: Float) {
        switch (index){
        case 1:
            currRotation = value
            lclFilter.transform = Matrix4x4(CGAffineTransform(rotationAngle: CGFloat(currRotation)))
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    
    func getColorParameter(_ index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(_ index:Int, color:UIColor) {}
    
    
    func stashParameters(){
        stash_rotation = currRotation
    }
    
    func restoreParameters(){
        currRotation = stash_rotation
        lclFilter.transform = Matrix4x4(CGAffineTransform(rotationAngle: CGFloat(currRotation)))
    }
}
