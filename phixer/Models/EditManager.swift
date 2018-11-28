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
    private static var previewFilter:FilterDescriptor? = nil

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
        log.debug("Added filter:\(String(describing: filter?.title))")
    }
    
    // removes the last filter in the list
    public static func popFilter() {
        if filterList.count > 0 {
            let filter = filterList[filterList.count-1]
            filterList.remove(at: filterList.count-1)
            log.debug("Removed filter:\(String(describing: filter?.title))")
        }
    }
    
    // add a Preview Filter, which is displayed in the output, but not saved to the filter list
    // NIL is OK, it just removes the preview filter
    public static func addPreviewFilter(_ filter:FilterDescriptor?){
        EditManager.previewFilter = filter
        log.debug("Added Preview filter:\(String(describing: filter?.title))")
    }

    // add the previewed filter to the list (i.e. make it permanent)
    public static func savePreviewFilter(){
        EditManager.addFilter(previewFilter)
        log.debug("Saved Preview filter:\(String(describing: previewFilter?.title))")
       previewFilter = nil
    }

    
    // apply all filters to the supplied image
    // Done this way so that you can call using any image, not just the static (shared) input image
    public static func applyAllFilters(_ image:CIImage?) -> CIImage?{
        
        guard image != nil else {
            log.warning("NIL image supplied")
            return nil
        }
        
        var outImage:CIImage? = image
        var tmpImage:CIImage? = image
        
        // apply the list of filters
        if filterList.count > 0 {
            for f in filterList {
                outImage = f?.apply(image: tmpImage)
                tmpImage = outImage
            }
        }
        
        // apply the preview filter, if specified
        if previewFilter != nil {
            outImage = previewFilter?.apply(image: tmpImage)
        }

        return outImage
    }
}
