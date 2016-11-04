//
//  FilterGalleryViewCell.swift
//  FilterCam
//
//  Created by Philip Price on 10/25/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import GPUImage

class FilterGalleryViewCell: UICollectionViewCell {
    
    open static let reuseID: String = "FilterGalleryViewCell"

    fileprivate var renderContainer:RenderContainerView = RenderContainerView()
    fileprivate var imageContainer:ImageContainerView = ImageContainerView()
    
    fileprivate var cachedImage: UIImage? = nil
    
    //var selectedImageView = UIImageView()
    
    
    fileprivate var initDone:Bool = false
    
    fileprivate var sampleImageFull:UIImage!
    fileprivate var blendImageFull:UIImage!
    fileprivate var sampleImage:UIImage? = nil
    fileprivate var blendImage:UIImage? = nil
    
    fileprivate var filteredImage:UIImage? = nil
    
    fileprivate var sample:PictureInput? = nil
    fileprivate var blend:PictureInput? = nil
    fileprivate var filter:BasicOperation? = nil
    fileprivate var filterGroup:OperationGroup? = nil

    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    func doInit(){
        if (!initDone){
            initDone = true

            log.debug("creating scaled sample and blend images...")
            sampleImageFull = UIImage(named:"sample_emma_01.png")!
            blendImageFull = UIImage(named:"bl_topaz_warm.png")!

            // create scaled down versions of the sample and blend images
            //TODO: let user choose image
            let size = sampleImageFull.size.applying(CGAffineTransform(scaleX: 0.2, y: 0.2))
            
            let hasAlpha = false
            let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
            
            // downsize input images since we really only need thumbnails
            
            UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
            sampleImageFull.draw(in: CGRect(origin: CGPoint.zero, size: size))
            sampleImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
            blendImageFull.draw(in: CGRect(origin: CGPoint.zero, size: size))
            blendImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            //sample = PictureInput(image:sampleImage!)
            //blend  = PictureInput(image:blendImage!)
            
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.renderContainer = RenderContainerView()
    }
    
    
    // MARK: - Configuration
    
    public func configureCell(frame: CGRect, descriptor:FilterDescriptorInterface?, render:Bool=false) {
        
        // re-size the contents to match the cell
        renderContainer.frame = frame
        imageContainer.frame = frame

        doInit()
        
        
       //DispatchQueue.main.async(execute: { () -> Void in

            // check to see if we want to render the image or use the cache
            if (render){
                
                // render filtered image via GPU
                self.imageContainer.isHidden = true
                self.renderContainer.isHidden = false
                //self.renderContainer.label.text = descriptor?.key
                self.updateRenderCell(descriptor)
                
                //self.renderContainer.addSubview(self.renderContainer.renderView!)
                self.addSubview(self.renderContainer)
                self.renderContainer.fillSuperview()
            } else {
                
                // use cached previews if possible
                self.imageContainer.isHidden = false
                self.renderContainer.isHidden = true
                self.imageContainer.label.text = descriptor?.key
                self.imageContainer.imageView.kf.indicatorType = .activity
                
                // look in cache first
                let key = (descriptor?.key)! + ".png"
                ImageCache.default.retrieveImage(forKey: key, options: nil) {
                    image, cacheType in
                    if let image = image {
                        //log.debug("Found image \(key), cacheType: \(cacheType).")
                        self.imageContainer.imageView.image = image
                        self.imageContainer.addSubview(self.imageContainer.imageView)
                        self.addSubview(self.imageContainer)
                        self.imageContainer.fillSuperview()
                    } else {
                        //log.debug("Image \(key) not in cache.")
                        self.imageContainer = self.createImageCell(descriptor)
                        let image = self.imageContainer.imageView.image
                        self.imageContainer.addSubview(self.imageContainer.imageView)
                        self.addSubview(self.imageContainer)
                        self.imageContainer.fillSuperview()
                        if (image != nil){
                            ImageCache.default.store(image!, forKey: key)
                            //log.verbose("Saved \(key) to cache")
                        } else {
                            log.error("!!! Invalid image returned for: \(key)!!!")
                        }
                    }
                }
            }
        //})
        

        
        //TODO: set overlay image based on whether filter is in Quick Select category or not and define touch handlers
    }
    
    
    
    // create RenedrView version of the cell
    fileprivate func updateRenderCell(_ descriptor: FilterDescriptorInterface?){
        
        //var sample:PictureInput? = nil // for some reason, need to use local variables
        //var blend:PictureInput? = nil
        //var filter:BasicOperation? = nil
        //var filterGroup:OperationGroup? = nil
        
        //var view:RenderContainerView = RenderContainerView()
        //view.frame.size = CGSize(width:height, height:height)
        //view.label.text = descriptor?.key
        
        self.renderContainer.label.text = descriptor?.key
       
        sample = PictureInput(image:sampleImage!)
        blend  = PictureInput(image:blendImage!)
        
        //TODO: start rendering in an asynch queue
        //TODO: render to UIImage, no need for RenderView since image is static
        
        guard (sample != nil) else {
            log.error("Could not load sample image")
            return
        }
        
        guard (self.renderContainer.renderView != nil) else {
            log.error("RenderView is NIL")
            return
        }
        
        guard ((descriptor?.filter != nil) || (descriptor?.filterGroup != nil)) else {
            log.error("Both filter and filterGroup are NIL for filter:\(descriptor?.key)")
            return
        }
        
        
        //if (descriptor?.filter != nil) { descriptor?.filter?.removeAllTargets() }
        //if (descriptor?.filterGroup != nil) { descriptor?.filterGroup?.removeAllTargets() }
        //sample?.removeAllTargets()
        //blend?.removeAllTargets()

        
        // annoyingly, we have to treat single and multiple filters differently
        if (descriptor?.filter != nil){ // single filter
            filter = descriptor?.filter
            log.debug("filter: \(descriptor?.key) address:\(Utilities.addressOf(filter))")
            
            let opType:FilterOperationType = (descriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                //log.debug("filter: \(descriptor?.key) address:\(Utilities.addressOf(filter))")
                sample! --> filter! --> self.renderContainer.renderView!
                break
            case .blend:
                //log.debug("Using BLEND mode for filter: \(descriptor?.key)")
                //TOFIX: blend image needs to be resized to fit the render view
                sample!.addTarget(filter!)
                blend! --> filter!
                sample! --> filter! --> self.renderContainer.renderView!
                blend?.processImage(synchronously: true)
                break
            }
            
        } else if (descriptor?.filterGroup != nil){ // group of filters
            filterGroup = descriptor?.filterGroup
            log.debug("filterGroup: \(descriptor?.key) address:\(Utilities.addressOf(filterGroup))")
            
            let opType:FilterOperationType = (descriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                //log.debug("filterGroup: \(descriptor?.key)")
                sample! --> filterGroup! --> self.renderContainer.renderView!
                break
            case .blend:
                //log.debug("Using BLEND mode for group: \(descriptor?.key)")
                //TOFIX: blend image needs to be resized to fit the render view
                sample!.addTarget(filterGroup!)
                blend! --> filterGroup!
                sample! --> filterGroup! --> self.renderContainer.renderView!
                blend?.processImage(synchronously: true)
                break
            }
        } else {
            log.error("ERR!!! shouldn't be here!!!")
        }
        
        
        sample?.processImage(synchronously: true) // synchronous because objects are freed next
        
        // clean up so that object don't get left hanging around
        //sample?.removeAllTargets()
        //blend?.removeAllTargets()
        //filter?.removeAllTargets()
        //filterGroup?.removeAllTargets()
        //sample = nil
        //blend = nil
        //filter = nil
        //filterGroup = nil

    }

    
    //  create a UIImage version of the cell
    fileprivate func createImageCell(_ descriptor: FilterDescriptorInterface?) -> ImageContainerView{
        
        // need to use local variables so that they deallocate resources when done
        var sample:PictureInput? = nil
        var blend:PictureInput? = nil
        var filteredOutput:PictureOutput? = nil
        var filter:BasicOperation? = nil
        var filterGroup:OperationGroup? = nil
        //let imageData: UIImage
        
        let view:ImageContainerView = ImageContainerView()
        view.frame.size = CGSize(width:height, height:height)
        view.label.text = descriptor?.key
        
        
        
        if (sample == nil){
            sample = PictureInput(image:sampleImage!)
            //sample = sampleInput
        }
        
        if (blend == nil){
            blend  = PictureInput(image:blendImage!) //TODO: choose image
            //blend = blendInput
        }
        
        
        //TODO: start rendering in an asynch queue
        //TODO: render to UIImage, no need for RenderView since image is static
        
        guard (sample != nil) else {
            log.error("Could not load sample image")
            return view
        }
                
        guard ((descriptor?.filter != nil) || (descriptor?.filterGroup != nil)) else {
            log.error("Both filter and filterGroup are NIL for filter:\(descriptor?.key)")
            return view
        }
        
        
        // set up the output variable
        filteredOutput = PictureOutput()
        filteredOutput?.encodedImageFormat = .png
        filteredOutput?.onlyCaptureNextFrame = true
        //filteredOutput?.onlyCaptureNextFrame = false

        
        // annoyingly, we have to treat single and multiple filters differently
        if (descriptor?.filter != nil){ // single filter
            //log.debug("filter: \(descriptor?.key)")
            filter = descriptor?.filter
            let opType:FilterOperationType = (descriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                //log.debug("filter: \(descriptor?.key)")
                sample! --> filter! --> filteredOutput!
                break
            case .blend:
                //log.debug("Using BLEND mode for filter: \(descriptor?.key)")
                //TOFIX: blend image needs to be resized to fit the render view
                sample!.addTarget(filter!)
                blend! --> filter!
                sample! --> filter! --> filteredOutput!
                blend?.processImage(synchronously: true)
                break
            }
            
        } else if (descriptor?.filterGroup != nil){ // group of filters
            //log.debug("filterGroup: \(descriptor?.key)")
            filterGroup = descriptor?.filterGroup
            let opType:FilterOperationType = (descriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                log.debug("filterGroup: \(descriptor?.key)")
                sample! --> filterGroup! --> filteredOutput!
                break
            case .blend:
                //log.debug("Using BLEND mode for group: \(descriptor?.key)")
                //TOFIX: blend image needs to be resized to fit the render view
                sample!.addTarget(filterGroup!)
                blend! --> filterGroup!
                sample! --> filterGroup! --> filteredOutput!
                blend?.processImage(synchronously: true)
                break
            }
        } else {
            log.error("ERR!!! shouldn't be here!!!")
            return view
        }
        
        filteredOutput?.imageAvailableCallback = { filteredImage in
            view.imageView.image = filteredImage
            log.verbose ("Image processed: \(descriptor?.key)")
        }
        sample?.processImage(synchronously: true) // synchronous because objects are freed next
        
        // clean up so that object don't get left hanging around
        //sample?.removeAllTargets()
        //blend?.removeAllTargets()
        //filter?.removeAllTargets()
        //filterGroup?.removeAllTargets()
        //sample = nil
        //blend = nil
        //filter = nil
        //filterGroup = nil
        
        return view
    }
}
