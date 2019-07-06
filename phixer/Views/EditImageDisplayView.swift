//
//  EditImageDisplayView.swift
//  phixer
//
//  Created by Philip Price on 9/16/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import CoreImage
import AVFoundation


// Class responsible for displaying the edited image, with the full stack of filters applied
// Note that filters are not saved to the edit stack, that is the responsibility of the ViewController
class EditImageDisplayView: UIView {
    
    var theme = ThemeManager.currentTheme()
    

    // enum that controls the display mode
    public enum displayMode {
        case full
        case split
    }
    
    // enum that controls the filtered mode
    public enum filterMode {
        case preview
        case saved
        case original
    }
    
    fileprivate var currDisplayMode: displayMode = .full
    fileprivate var currFilterMode: filterMode = .preview
    
    fileprivate var currSplitOffset:CGFloat = 0.0
    fileprivate var currSplitPoint:CGPoint = CGPoint.zero

    //fileprivate var renderView: RenderView? = RenderView()
    fileprivate var renderView: ScrollableRenderView? = ScrollableRenderView()
    fileprivate var imageView: UIImageView! = UIImageView()
    
    fileprivate var initDone: Bool = false
    fileprivate var layoutDone: Bool = false
    fileprivate var filterManager = FilterManager.sharedInstance
    
    
    //fileprivate var currInput:CIImage? = nil
    fileprivate var currBlendInput:CIImage? = nil
    
    fileprivate var currFilterKey:String = ""
    //fileprivate var currFilterDescriptor: FilterDescriptor? = nil

    
    
    ///////////////////////////////////
    // MARK: - Setup/teardown
    ///////////////////////////////////
    convenience init(){
        self.init(frame: CGRect.zero)
        doInit()
    }
    
    
    deinit {
        //suspend()
    }

   
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //log.debug("layout")
       doInit()

        //log.debug("layout")
        //self.currInput = InputSource.getCurrentImage() // this can change
        //self.currInput = EditManager.getPreviewImage() // this can change
        renderView?.frame = self.frame
        renderView?.backgroundColor = theme.backgroundColor
        
        self.addSubview(renderView!)
        renderView?.fillSuperview()
        // self.bringSubview(toFront: renderView!)
        
        // this must come after sizing
        //renderView?.image = self.currInput
        // TODO: resize image based on view size (save memory)
        //renderView?.image = InputSource.getCurrentImage()
        //let imgSize = InputSource.getSize()
        
        renderView?.image = EditManager.getPreviewImage()
        let imgSize = EditManager.getImageSize()
        renderView?.setImageSize(imgSize)
        
        // must come after RenderView is initialised
        self.currSplitPoint = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2) // middle of view
        self.setSplitPosition(self.currSplitPoint)

        
        layoutDone = true
        
        // check to see if filter has already been set. If so update
        
        if !(currFilterKey.isEmpty) {
            update()
        }

        

    }
    
    fileprivate func doInit(){
        

        if (!initDone){
            //log.debug("init")
            self.backgroundColor = theme.backgroundColor
            
            //EditManager.reset()
            //self.currInput = ImageManager.getCurrentEditImage()
            //self.currInput = InputSource.getCurrentImage()
            EditManager.setInputImage(InputSource.getCurrentImage())

            self.layoutDone = false
            initDone = true
            
        }
    }
    


    
    
    
    ///////////////////////////////////
    // MARK: - Accessors
    ///////////////////////////////////
    
    public func setDisplayMode(_ mode:displayMode){
        self.currDisplayMode = mode
        log.verbose("Display Mode: \(mode)")
    }
    
    public func setFilterMode(_ mode:filterMode){
        self.currFilterMode = mode
        log.verbose("Filter Mode: \(mode)")
    }

    
    public func setSplitPosition(_ position:CGPoint){
        self.currSplitOffset = self.offsetFromPosition(position)
        //log.verbose("position: \(position) offset:\(self.currSplitOffset)")
    }

    public func setFilter(key:String){
        //currFilterKey = filterManager.getCurrentFilter()
        if (!key.isEmpty){
            let prevKey = currFilterKey
            currFilterKey = key
            EditManager.addPreviewFilter(filterManager.getFilterDescriptor(key: key))
            
            resetZoom()
            update()

            if (!prevKey.isEmpty) {
                filterManager.releaseRenderView(key: prevKey)
                filterManager.releaseFilterDescriptor(key: key)
            }

        } else {
            log.error("Empty key specified")
        }
    }
    
    // saves the filtered image to the camera roll
    public func saveImage(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            
            guard self != nil else {
                log.error("NIL self")
                return
            }
            
            // use the full sized input image
            EditManager.setInputImage(InputSource.getCurrentImage(), fullsize: true)
            let ciimage = EditManager.getPreviewImage()
            if (ciimage != nil){
                let cgimage = ciimage?.generateCGImage(size:(ciimage?.extent.size)!)
                let image = UIImage(cgImage: cgimage!)
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            } else {
                log.error("Error saving photo")
            }
        }
    }
    
    open func update(){
        if (layoutDone) {
            //log.verbose("update requested")
            DispatchQueue.main.async(execute: { () -> Void in
                self.runFilter()
            })
        }
    }
    
    public func getImagePosition(viewPos:CGPoint) -> CIVector?{
        if renderView != nil {
            return renderView?.getImagePosition(viewPos: viewPos)
        } else {
            return CIVector(cgPoint: CGPoint.zero)
        }
    }
    
    public func getViewPosition(imagePos:CGPoint) -> CGPoint {
        if renderView != nil {
            return (renderView?.getViewPosition(imagePos: imagePos))!
        } else {
            return CGPoint.zero
        }
    }

    open func updateImage(){
        DispatchQueue.main.async(execute: { [weak self] () -> Void in
            //log.verbose("Updating edit image")
            EditManager.setInputImage(InputSource.getCurrentImage())
            self?.resetZoom()
//            self.currInput = EditManager.getPreviewImage()
//            if self.currInput == nil {
//                log.warning("Edit image not set, using Sample")
//                self.currInput = ImageManager.getCurrentSampleInput() // no edit image set, so make sure there is something
//            }
            self?.update()
        })
    }
    
    public func resetZoom() {
        renderView?.isScrollEnabled = false
        renderView?.zoomScale = 1.0
        renderView?.centerImage()
        renderView?.setZoomScale(0.0, animated: false)
        renderView?.isScrollEnabled = true
    }

    public func isZoomed() -> Bool {
        log.verbose("zoomScale:\(self.renderView?.zoomScale)")
        return !((self.renderView?.zoomScale.approxEqual(1.0))!)
    }
    
    public func zoom(to: CGRect){
        self.renderView?.zoom(to: to, animated: true)
    }
   
    public func getShapeLayer() -> CAShapeLayer? {
        return self.renderView?.getShapeLayer()
    }
    
    
    ///////////////////////////////////
    // MARK: filter execution
    ///////////////////////////////////
    
    // Sets up the filter pipeline. Call when filter, orientation or camera changes
    open func runFilter(){
        
//        if !self.currFilterKey.isEmpty && layoutDone {
        /***
            DispatchQueue.main.async(execute: { () -> Void in
                if self.currDisplayMode == .full {
                    //log.verbose("Running filter: \(self.currFilterKey)")
                   switch self.currFilterMode {
                     case .preview:
                        self.renderView?.image = EditManager.getPreviewImage()
                    case .saved:
                        self.renderView?.image = EditManager.getFilteredImage()
                    case .original:
                        self.renderView?.image = EditManager.getOriginalImage()
                    default:
                        log.error("Uknown mode")
                    }
                } else {
                    self.renderView?.image = EditManager.getSplitPreviewImage(offset: self.currSplitOffset)
                }
            })
         ***/
        
        DispatchQueue.main.async(execute: { () -> Void in
            if self.currDisplayMode == .full {
                //log.verbose("Running filter: \(self.currFilterKey)")
                switch self.currFilterMode {
                case .preview:
                    EditManager.getPreviewImageAsync(completion: self.filterCompletion)
                case .saved:
                    EditManager.getFilteredImageAsync(completion: self.filterCompletion)
                case .original:
                    self.renderView?.image = EditManager.getOriginalImage()
                default:
                    log.error("Uknown mode")
                }
            } else {
                EditManager.getSplitPreviewImageAsync(offset: self.currSplitOffset, completion: self.filterCompletion)
            }
        })

//        } else {
//            if self.currFilterKey.isEmpty { // this can happen if no filters have been applied yet
//                log.warning("Filter not set")
//                DispatchQueue.main.async(execute: { () -> Void in
//                    self.renderView?.image = EditManager.getOriginalImage()
//                })
//            }
//            if !layoutDone { log.warning("Layout not yet done") }
//        }
    }
    
    
    // callback for async filter processing
    private func filterCompletion(_ image: CIImage?){
        DispatchQueue.main.async(execute: { [weak self] () -> Void in
            self?.renderView?.image = image
        })
    }
    
    func suspend(){

    }
    
    
    ///////////////////////////////////
    // MARK: - Utilities
    ///////////////////////////////////
    
    // convert the view-based position into an offset in image space, adjusted for rotation
    public func offsetFromPosition(_ position:CGPoint) -> CGFloat {
        var offset:CGFloat
        
        // get the position in image coordinates
        let imgOffset = renderView?.getImagePosition(viewPos: position).cgPointValue
        
        // adjust based on the image orientation. This assumes landscape images are rotated
        //let imgSize = InputSource.getSize()
        let imgSize = EditManager.getImageSize()

        if imgOffset != nil {
            if imgSize.height > imgSize.width { // portrait
                offset = (imgOffset?.x)!
            } else { // landscape
                offset = (imgOffset?.y)!
            }
        } else {
            // error, put offset in the middle of the image
            offset = min (imgSize.width, imgSize.height) / 2
        }

        return offset
    }
    
}
