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
    public static var previewImage:CIImage? { return applyAllFilters(EditManager._input) }
    public static var filteredImage:CIImage? { return applySavedFilters(EditManager._input) }

    private static var _input:CIImage? = nil

    private static var filterList:[FilterDescriptor?] = []
    private static var previewFilter:FilterDescriptor? = nil
    static var filterManager: FilterManager? = FilterManager.sharedInstance

    // make initialiser private to prevent instantiation
    private init(){}
    
    // reset the filter list
    public static func reset(){
        log.verbose("Resetting")
        EditManager.filterList = []
        previewFilter = filterManager?.getFilterDescriptor(key: FilterDescriptor.nullFilter)
        filterManager?.setCurrentFilterKey(FilterDescriptor.nullFilter)
    }
    
    // set the input image to be processed
    public static func setInputImage(_ image:CIImage?){
        EditManager._input = image
    }
    
    // get the filtered version of the input image, including the preview filter
    public static func getPreviewImage() -> CIImage? {
        return EditManager.previewImage
    }
    
    // get the filtered version of the input image, without the preview image
    public static func getFilteredImage() -> CIImage? {
        return EditManager.filteredImage
    }
    
    // get a subset of the filters applied
    public static func getFilteredImageAt(position:Int) -> CIImage? {
        return EditManager.applyFilterSubset(image: EditManager._input, count: position)
    }

    
    // get a 'split preview' image, with the preview filtered image on the left and the filtered image (sans preview) on the right
    // Note that x is specifed in image coordinates, not screen/view coordinates
    public static func getSplitPreviewImage(offset:CGFloat) -> CIImage? {
        let leftImage:CIImage? = getPreviewImage()
        let rightImage:CIImage? = getFilteredImage()
        let maskImage:CIImage? = createPreviewMask(size: EditManager._input!.extent.size, offset: offset)
        
        if (leftImage != nil) && (rightImage != nil) && (maskImage != nil) {
            return leftImage?.applyingFilter("CIBlendWithMask", parameters: [kCIInputBackgroundImageKey:rightImage!, "inputMaskImage":maskImage!])
        } else {
            log.error("Nil image")
            return nil
        }
    }

    
    // get the original (input) image
    public static func getOriginalImage() -> CIImage? {
        return EditManager._input
    }
    

    // add a filter to the list
    public static func addFilter(_ filter:FilterDescriptor?){
        guard filter != nil else {
            log.warning("NIL filter supplied")
            return
        }
        EditManager.filterList.append(filter)
        FilterManager.lockFilter(key:(filter?.key)!)
        log.debug("Added filter:\(String(describing: filter?.title))")
    }
    
    
    // get the number of applied filters
    public static func getAppliedCount() -> Int {
        return EditManager.filterList.count
    }
    
    
    // removes the last filter in the list
    public static func popFilter() {
        log.verbose("Removing filter...")
        // if preview set then remove that, otherwise remove last filter
        
        if (EditManager.previewFilter != nil) && (EditManager.previewFilter?.key != FilterDescriptor.nullFilter) {
            log.debug("Removed filter:\(String(describing: EditManager.previewFilter?.title))")
            addPreviewFilter(filterManager?.getFilterDescriptor(key: FilterDescriptor.nullFilter))
        } else {
            
            if filterList.count > 0 {
                let filter = filterList[filterList.count-1]
                filterList.remove(at: filterList.count-1)
                FilterManager.unlockFilter(key:(filter?.key)!)
                log.debug("Removed filter:\(String(describing: filter?.title))")
            } else {
                log.verbose("No filters to remove")
            }
        }
        
        // if nothing left, set the preview filter to the null filter so that at least the image can render
        if (filterList.count <= 0) && (EditManager.previewFilter != nil){
            filterManager?.setCurrentFilterKey(FilterDescriptor.nullFilter)
            EditManager.previewFilter = filterManager?.getFilterDescriptor(key: FilterDescriptor.nullFilter)
        }

    }
    
    
    
    // add a Preview Filter, which is displayed in the output, but not saved to the filter list
    // NIL is OK, it just removes the preview filter
    public static func addPreviewFilter(_ filter:FilterDescriptor?){
        if EditManager.previewFilter != nil {
            FilterManager.unlockFilter(key:(EditManager.previewFilter?.key)!)
        }

        EditManager.previewFilter = filter
        if filter != nil {
            FilterManager.lockFilter(key:(filter?.key)!)
        }
       log.debug("Added Preview filter:\(String(describing: filter?.title))")
    }

    
    
    // get the current preview filter
    public static func getPreviewFilter() -> FilterDescriptor? {
        return EditManager.previewFilter
    }
    
    // get the title associated with the preview filter
    public static func getPreviewTitle() -> String {
        return EditManager.previewFilter?.title ?? "(none)"
    }
    

    
    // add the previewed filter to the list (i.e. make it permanent)
    public static func savePreviewFilter(){
        EditManager.addFilter(previewFilter)
        log.debug("Saved Preview filter:\(String(describing: previewFilter?.title))")
        addPreviewFilter(filterManager?.getFilterDescriptor(key: FilterDescriptor.nullFilter))
    }

   
    
    // apply all filters in the list to the supplied image, excluding the preview image
    // Done this way so that you can call using any image, not just the static (shared) input image
    public static func applySavedFilters(_ image:CIImage?) -> CIImage?{
        
        guard image != nil else {
            log.warning("NIL image supplied")
            return nil
        }
        
        var outImage:CIImage? = image
        var tmpImage:CIImage? = image
        
        // apply the list of filters
        if filterList.count > 0 {
            for f in filterList {
                tmpImage = f?.apply(image: outImage)
                outImage = tmpImage
            }
        }
        
        return outImage
    }

    
    // apply all filters to the supplied image, including the preview image
    // Done this way so that you can call using any image, not just the static (shared) input image
    public static func applyAllFilters(_ image:CIImage?) -> CIImage?{
        
        guard image != nil else {
            log.warning("NIL image supplied")
            return nil
        }
        
        var outImage:CIImage? = applySavedFilters(image)
        
        
        // apply the preview filter, if specified
        if previewFilter != nil {
            let tmpImage:CIImage? = outImage
            outImage = previewFilter?.apply(image: tmpImage)
        }
        
        return outImage
    }
    
    
    // return the image at the requested 'layer', with all lower filters applied
    public static func applyFilterSubset(image:CIImage?, count:Int) -> CIImage? {
        
        guard image != nil else {
            log.warning("NIL image supplied")
            return nil
        }
        
        var outImage:CIImage? = image
        var tmpImage:CIImage? = image
        
        // apply the list of filters
        if filterList.count > 0 {
            let num = min(count, filterList.count - 1)
            for i in 0...num {
                let f = filterList[i]
                tmpImage = f?.apply(image: outImage)
                outImage = tmpImage
            }
        }
        
        return outImage

    }
    
    // return the title associated with the filter at the requested layer
    public static func getTitleAt(position:Int) -> String {
        if position < filterList.count{
            return filterList[position]?.title ?? "(unkown)"
        } else {
            return "(invalid)"
        }
    }
    
    
    

    // creates a preview mask based on the supplied size usingthe supplied offset
    private static func createPreviewMask(size: CGSize, offset: CGFloat) -> CIImage? {
        var img:CIImage? = nil
        
        // OK, so we want the split to oriented along the longest side
        // This is a bit of a hack since we are assuming that landscape photos are rotated
        
        var leftRect:CGRect
        var rightRect:CGRect
        
        if size.height > size.width { // portrait
            leftRect = CGRect(x: 0, y: 0, width: offset, height: size.height)
            rightRect = CGRect(x: offset+1, y: 0, width: (size.width - offset), height: size.height)
        } else { // landscape or square
            leftRect = CGRect(x: 0, y: 0, width: size.width, height: offset)
            rightRect = CGRect(x: 0, y: offset+1, width: size.width, height: (size.height-offset))
        }
        
        let colorspace = CGColorSpaceCreateDeviceRGB()
        let bitmapinfo =  CGImageAlphaInfo.premultipliedLast.rawValue
        
        //let bitmapInfo = CGImageAlphaInfo.last.rawValue
        //let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        let context = CGContext(data: nil,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: Int(8),
                                bytesPerRow: Int(0),
                                space: colorspace,
                                bitmapInfo:  bitmapinfo)

        guard context != nil else {
            log.error("Could not create CG context")
            return nil
        }
        
        // draw the left rectangle in black and the right in white
        context?.interpolationQuality = .low
        
        // left
        let black = CGColor(colorSpace: colorspace, components: [0, 0, 0, 1])
        guard (black != nil) else {
            log.error("Could not create black")
            return nil
        }
        context?.setFillColor(black!)
        //context?.addRect(leftRect)
        //context?.drawPath(using: CGPathDrawingMode.fill)
        context?.fill(leftRect)
        
        // right
        let white = CGColor(colorSpace: colorspace, components: [1, 1, 1, 1])
        guard (black != nil) else {
            log.error("Could not create white")
            return nil
        }
        context?.setFillColor(white!)
        //context?.addRect(rightRect)
        //context?.drawPath(using: CGPathDrawingMode.fill)
        context?.fill(rightRect)

        // create the CGImage
        let cgImage = context!.makeImage()
        
        guard cgImage != nil else {
            log.error("Could not create CGImage")
            return nil
        }
        
        //log.debug("left:\(leftRect) right:\(rightRect)")
        
        // create the CIImage
        img = CIImage(cgImage: cgImage!)
        return img
    }
}
