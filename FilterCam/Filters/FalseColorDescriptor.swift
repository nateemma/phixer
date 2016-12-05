//
//  FalseColorDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/4/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage


class FalseColorDescriptor: FilterDescriptorInterface {
    
    
    let key = "FalseColor"
    let title = "FalseColor"
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 2
    let parameterConfiguration = [ParameterSettings(title:"dark color", minimumValue:0.0, maximumValue:1.0, initialValue:0.5, isRGB:true),ParameterSettings(title:"light color", minimumValue:0.0, maximumValue:1.0, initialValue:0.5, isRGB:true)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:FalseColor = FalseColor() // the actual filter
    
    
    fileprivate var stash_firstColor: Color
    fileprivate var stash_secondColor: Color
    
    
    required init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        stash_firstColor = lclFilter.firstColor
        stash_secondColor = lclFilter.secondColor
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func reset(){
        lclFilter.removeAllTargets()
        lclFilter = FalseColor()
        restoreParameters()
    }
    
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    
    func getParameter(_ index: Int)->Float {
        log.warning("Ignoring call, not valid for this filter")
        return parameterNotSet
    }
    
    
    func setParameter(_ index: Int, value: Float) {
        log.warning("Ignoring call, not valid for this filter")
    }
    
    
    // This filter uses Color parameters, so add those here
    
    
    func setColorParameter(_ index: Int, color:UIColor){
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        switch(index){
        case 1:
            //log.debug("\(parameterConfiguration[0].title): Color:\(color)")
            log.debug("\(parameterConfiguration[0].title): (R:\(r), B:\(b), G:\(g))")
            lclFilter.firstColor = Color(red: Float(r), green: Float(g), blue: Float(b), alpha: Float(a))
            break
        case 2:
            //log.debug("\(parameterConfiguration[1].title): Color:\(color)")
            log.debug("\(parameterConfiguration[1].title): (R:\(r), B:\(b), G:\(g))")
            lclFilter.secondColor = Color(red: Float(r), green: Float(g), blue: Float(b), alpha: Float(a))
            break
        default:
            log.error("Invalid index: \(index)")
        }
    }

    
    func getColorParameter(_ index: Int)->UIColor{
        switch(index){
        case 1:
            return UIColor(red: CGFloat(lclFilter.firstColor.redComponent),
                           green: CGFloat(lclFilter.firstColor.greenComponent),
                           blue: CGFloat(lclFilter.firstColor.blueComponent),
                           alpha: CGFloat(lclFilter.firstColor.alphaComponent))
        case 2:
            return UIColor(red: CGFloat(lclFilter.secondColor.redComponent),
                           green: CGFloat(lclFilter.secondColor.greenComponent),
                           blue: CGFloat(lclFilter.secondColor.blueComponent),
                           alpha: CGFloat(lclFilter.secondColor.alphaComponent))
        default:
            log.error("Invalid index: \(index)")
            return UIColor.blue
        }
    }
    
    
    //func updateParameters(value1:Float, value2:Float,  value3:Float,  value4:Float){
    //    lclFilter.firstColor = value1
    //}
    
    func stashParameters(){
        stash_firstColor = lclFilter.firstColor
        stash_secondColor = lclFilter.secondColor
    }
    
    func restoreParameters(){
        lclFilter.firstColor = stash_firstColor
        lclFilter.secondColor = stash_secondColor
    }
}
