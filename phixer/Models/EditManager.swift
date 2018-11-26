//
//  EditManager.swift
//  phixer
//
//  Created by Philip Price on 11/21/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

// static class to handle the editing of an image with multiple filters
class EditManager {
    
    public static var inputImage:CIImage? { return EditManager._input }
    public static var outputImage:CIImage? { return applyAllFilters(EditManager._input) }
    
    private static var _input:CIImage? = nil

    private static var filterList:[FilterDescriptor?] = []

    // make initialiser private to prevent instantiation
    private init(){}
    
    // reset the filter list
    public static func reset(){
        EditManager.filterList = []
    }
    
    // set the input image to be processed
    public static func setInputImage(_ image:CIImage?){
        EditManager._input = image
    }
    
    // get the filtered version of the input image
    public static func getOutputImage() -> CIImage? {
        return EditManager.outputImage
    }
    
    // add a filter to the list
    public static func addFilter(_ filter:FilterDescriptor?){
        guard filter != nil else {
            log.warning("NIL filter supplied")
            return
        }
        EditManager.filterList.append(filter)
    }
    
    // apply all filters to the supplied image
    // Done this way so that you can call using any image, not just the static (shared) input image
    public static func applyAllFilters(_ image:CIImage?) -> CIImage?{
        
        guard image != nil else {
            log.warning("NIL image supplied")
            return nil
        }
        
        var outImage:CIImage? = nil
        var tmpImage:CIImage? = nil
        
        if filterList.count > 0 {
            tmpImage = image
            for f in filterList {
                outImage = f?.apply(image: tmpImage)
                tmpImage = outImage
            }
        } else {
            log.warning("No filters in list. returning original image")
            outImage = EditManager._input
        }
        return outImage
    }
}
