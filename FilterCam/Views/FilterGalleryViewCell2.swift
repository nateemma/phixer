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

class FilterGalleryViewCell2: UICollectionViewCell {
    
    open static let reuseID: String = "FilterGalleryViewCell"

    var renderView : RenderView? = RenderView()
    var label : UILabel = UILabel()
    
    let defaultWidth:CGFloat = 64.0
    let defaultHeight:CGFloat = 64.0

    
    //fileprivate var renderContainer:RenderContainerView = RenderContainerView()
    //fileprivate var imageContainer:ImageContainerView = ImageContainerView()
    
    //fileprivate var cachedImage: UIImage? = nil
    
    //var selectedImageView = UIImageView()
    
    
    fileprivate var initDone:Bool = false
    
    fileprivate var filterManager:FilterManager = FilterManager.sharedInstance

    fileprivate var sampleImageFull:UIImage!
    fileprivate var blendImageFull:UIImage!
    fileprivate var sampleImage:UIImage? = nil
    fileprivate var blendImage:UIImage? = nil
    fileprivate var sample:PictureInput? = nil
    fileprivate var blend:PictureInput? = nil
    
    /**/
    fileprivate var filteredImage:UIImage? = nil
    
    fileprivate var filter:BasicOperation? = nil
    fileprivate var filterGroup:OperationGroup? = nil
    
    fileprivate var filterDescriptor:FilterDescriptorInterface?
    fileprivate var testFilter:FilterDescriptorInterface? = CGAColorspaceDescriptor()
/**/
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        doInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    func doInit(){
        if (!initDone){
            initDone = true

            /***/
            log.debug("creating scaled sample and blend images...")
            sampleImageFull = UIImage(named:"sample_emma_01.png")!
            blendImageFull = UIImage(named:"bl_topaz_warm.png")!

            // create scaled down versions of the sample and blend images
            //TODO: let user choose image
            let size = sampleImageFull.size.applying(CGAffineTransform(scaleX: 0.5, y: 0.5))
            
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
            
            sample = PictureInput(image:sampleImage!)
            blend  = PictureInput(image:blendImage!)
            /***/

        }
    }

    private func doLayout(){
        
        self.backgroundColor = UIColor.flatBlack()
        self.layer.cornerRadius = 4.0
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor(white: 0.6, alpha: 1.0).cgColor
        self.clipsToBounds = true
        
        renderView?.contentMode = .scaleAspectFill
        renderView?.clipsToBounds = true
        renderView?.frame.size = CGSize(width:defaultWidth, height:defaultHeight)
        self.addSubview(renderView!)
        
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.font = UIFont.boldSystemFont(ofSize: 12.0)
        self.addSubview(label)
        
        //log.verbose("renderView h:\(self.height * 0.7)")
        renderView?.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: self.height * 0.7)
        label.alignAndFill(.underCentered, relativeTo: renderView!, padding: 0)

        self.bringSubview(toFront: renderView!)
    }
    
    // MARK: - Configuration
    
    public func configureCell(frame: CGRect, key:String, render:Bool=true) {
        
        // re-size the contents to match the cell
        renderView?.frame = frame

        doInit()
        doLayout()
        
       DispatchQueue.main.async(execute: { () -> Void in

            // check to see if we want to render the image or use the cache
            if (render){
                
                // render filtered image via GPU
                
                self.filterDescriptor = self.filterManager.getFilterDescriptor(key: key)!
                self.updateRenderCell(self.filterDescriptor)
                
            } else {
                log.warning("Non-rendered version not supported")
            }
        })
        

        
        //TODO: set overlay image based on whether filter is in Quick Select category or not and define touch handlers
    }
    
    
    
    // create RenedrView version of the cell
    fileprivate func updateRenderCell(_ descriptor: FilterDescriptorInterface?){
        
        /***
        var sample:PictureInput? = nil // for some reason, need to use local variables
        var blend:PictureInput? = nil
         let sampleImageFull:UIImage = UIImage(named:"sample_emma_01.png")!
         let blendImageFull:UIImage = UIImage(named:"bl_topaz_warm.png")!
         sample = PictureInput(image:sampleImageFull)
         blend  = PictureInput(image:blendImageFull)
         //sample = PictureInput(image:sampleImage)
         //blend  = PictureInput(image:blendImage!)
         var filter:BasicOperation? = nil
         var filterGroup:OperationGroup? = nil
         ***/
 
        //self.renderContainer.label.text = descriptor?.key
        self.label.text = descriptor?.key
       
        
        //TODO: start rendering in an asynch queue
        //TODO: render to UIImage, no need for RenderView since image is static
        
        guard (sample != nil) else {
            log.error("Could not load sample image")
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
            //filter = testFilter?.filter
            filter = descriptor?.filter
            
            log.debug("Run filter: \((descriptor?.key)!) address:\(Utilities.addressOf(filter))")
            
            let opType:FilterOperationType = (descriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                //log.debug("filter: \(descriptor?.key) address:\(Utilities.addressOf(filter))")
                //sample! --> filter! --> self.renderView!
                sample! --> filter! --> self.renderView!
                sample?.processImage()
                break
            case .blend:
                //log.debug("Using BLEND mode for filter: \(descriptor?.key)")
                //TOFIX: blend image needs to be resized to fit the render view
                sample!.addTarget(filter!)
                blend! --> filter!
                sample! --> filter! --> self.renderView!
                blend?.processImage(synchronously: true)
                sample?.processImage()
                break
            }
            
        } else if (descriptor?.filterGroup != nil){ // group of filters
            filterGroup = descriptor?.filterGroup
            log.debug("Run filterGroup: \(descriptor?.key) address:\(Utilities.addressOf(filterGroup))")
            
            let opType:FilterOperationType = (descriptor?.filterOperationType)!
            switch (opType){
            case .singleInput:
                //log.debug("filterGroup: \(descriptor?.key)")
                sample! --> filterGroup! --> self.renderView!
                sample?.processImage()
                break
            case .blend:
                //log.debug("Using BLEND mode for group: \(descriptor?.key)")
                //TOFIX: blend image needs to be resized to fit the render view
                sample!.addTarget(filterGroup!)
                blend! --> filterGroup!
                sample! --> filterGroup! --> self.renderView!
                blend?.processImage(synchronously: true)
                sample?.processImage()
                break
            }
        } else {
            log.error("ERR!!! shouldn't be here!!!")
        }
        
        
        //sample?.processImage(synchronously: true) // synchronous because objects are freed next
        
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

 
    open func suspend(){
        sample?.removeAllTargets()
        blend?.removeAllTargets()
        filter?.removeAllTargets()
        filterGroup?.removeAllTargets()
    }
}
