//
//  ImageManager.swift
//  FilterCam
//
// Manages the various types of internal images (blends, samples, image under edit etc.)
//
//  Created by Philip Price on 11/7/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import GPUImage
import AVFoundation
import Photos


protocol ImageManagerDelegate: class {
    func blendImageChanged(name: String)
    func sampleImageChanged(name: String)
    func userImageSaved()
}

class ImageManager {
    
    
    
    
    
    //////////////////////////////////
    // MARK: - Blend Image/Layer Management
    //////////////////////////////////
    
    private static let _blendNameList:[String] = [
        "067_by_candymax_stock.jpg",
        "15_by_grandeombre_stock.jpg",
        "30_by_grandeombre_stock.jpg",
        "8_by_grandeombre_stock.jpg",
        "MissEtikAte_texture_1.png",
        "MissEtikAte_texture_2.png",
        "MissEtikAte_texture_3.png",
        "MissEtikAte_texture_4.png",
        "NerveEndings-Parsley.jpg",
        "ScratchTheItch.jpg",
        "WatermelonSplash.jpg",
        "Whirlygig-2.jpg",
        "_film_grain_numba_1__by_su_y.jpg",
        "anger_by_pushelle.jpg",
        "brick_static_by_dazzle_textures.jpg",
        "burnt_newspaper_by_dazzle_textures.jpg",
        "crack_and_peel_by_dazzle_textures.jpg",
        "dear_hermine_grunge_texture_by_valerianastock-d3ai9zl.jpg",
        "grunge_background_v2_by_bcoolbyte.jpg",
        "grunge_texture_23_by_amptone_stock.jpg",
        "lightning_splits_by_dazzle_textures.jpg",
        "massacre_by_dazzle_textures.jpg",
        "metal_rust_texture_22_by_fantasystock.jpg",
        "monoprint_16_by_pendlestock.jpg",
        "monoprint_17_by_pendlestock.jpg",
        "monoprint_18_by_pendlestock.jpg",
        "neopan_texture___2_by_jakezdaniel-d1zp0ug.jpg",
        "nuit_lascive_by_dazzle_textures.jpg",
        "paper_curled_by_fotojenny.jpg",
        "rust_beam_by_logicalx.jpg",
        "rust_texture_by_visionafar.jpg",
        "sad_ending_by_ckdailyplanet-d30dame.jpg",
        "seamless_water_drop_texture_by_fantasystock.jpg",
        "shedyourskin_DirtyLights2.jpg",
        "shedyourskin_DirtyLights4.jpg",
        "shedyourskin_DirtyLights5.jpg",
        "shedyourskin_DirtyLights6.jpg",
        "shedyourskin_DirtyTextures7.jpg",
        "shedyourskin_Tex_108.jpg",
        "shedyourskin_Tex_119.jpg",
        "shedyourskin_Tex_124.jpg",
        "shedyourskin_Tex_132.jpg",
        "shedyourskin_Tex_133.jpg",
        "shedyourskin_Tex_26.jpg",
        "shedyourskin_Tex_61.jpg",
        "shedyourskin_Tex_87.jpg",
        "shedyourskin_Tex_89.jpg",
        "sheets_by_dazzle_textures.jpg",
        "snow_bokeh_ii_by_lostpuppy_stock.jpg",
        "texture_110_by_sirius_sdz.jpg",
        "texture_125_by_sirius_sdz.jpg",
        "texture_133_by_sirius_sdz.jpg",
        "texture_142_by_sirius_sdz.jpg",
        "texture_202_by_malleni_stock-d9uwyqo.jpg",
        "texture_this_04_by_kuschelirmel_stock-d9vsffe.jpg",
        "textures_100_by_inthename_stock.jpg",
        "textures_92_by_inthename_stock.jpg",
        "tile_by_dazzle_textures.jpg",
        "wake_by_photoshop_stock.jpg",
        "wet_cellophane_texture_by_fantasystock-d3gigxz.jpg"
    ]
    
    private static var _currBlendName:String = _blendNameList[0]
    
    private static var _currBlendImage: UIImage? = nil
    
    private static var _currBlendImageScaled: UIImage? = nil
    private static var _currBlendSize: CGSize = CGSize(width: 0.0, height: 0.0)
    
    private static var _currBlendInput: PictureInput? = nil
    
  
    
    
    
    open static func getBlendImageList()->[String]{
        return _blendNameList
    }
    
    
    
    open static func getCurrentBlendImageName()->String {
        return _currBlendName
    }
    
    
    
    open static func setCurrentBlendImageName(_ name:String) {
        if (name.contains(":")){ // URL?
            _currBlendName = name
            _currBlendImage = getBlendImageFromURL(name)
            _currBlendImageScaled = resizeImage(_currBlendImage, targetSize: _currBlendSize, mode:.scaleAspectFill)
            setBlendInput(image: _currBlendImageScaled!)
        } else if (_blendNameList.contains(name)){
            log.debug("Current Blend image set to:\(name)")
            _currBlendName = name
            _currBlendImage = UIImage(named: _currBlendName)
            _currBlendImageScaled = resizeImage(getCurrentBlendImage(), targetSize: _currBlendSize, mode:.scaleAspectFill)
            setBlendInput(image: _currBlendImageScaled!)
        } else {
            log.warning("Unknown Blend name:\(name)")
        }
    }
    
    
    
    open static func getCurrentBlendImage()->UIImage? {
        checkBlendImage()
        return _currBlendImage
    }
    
    
    
    open static func getCurrentBlendImage(size:CGSize)->UIImage? {
        checkBlendImage()
        var scaledImage:UIImage? = nil
        scaledImage = resizeImage(_currBlendImage, targetSize: size, mode:.scaleAspectFill)
        return scaledImage
    }
    
    
    open static func getCurrentBlendInput()->PictureInput? {
        checkBlendImage()
        return _currBlendInput
    }
    
    
    open static func getBlendImage(name: String, size:CGSize)->UIImage?{
        return resizeImage(getBlendImageFromURL(name), targetSize:size, mode:.scaleAspectFill)
    }
    
    
    open static func setBlendInput(image: UIImage){
        if (_currBlendInput != nil){
            _currBlendInput?.removeAllTargets()
        }
        _currBlendInput = PictureInput(image: image)
    }
    
   
    
    private static func checkBlendImage(){
        // make sure current blend image has been loaded
        if (_currBlendImage == nil){
            _currBlendImage = getBlendImageFromURL(_currBlendName)
            setBlendInput(image: _currBlendImage!)
        }
        
        // check to see if we have already resized
        if (_currBlendImageScaled == nil){
            if (_currBlendSize == CGSize.zero){
                _currBlendSize = (_currBlendImage?.size)!
            }
            _currBlendImageScaled = resizeImage(_currBlendImage, targetSize: _currBlendSize, mode:.scaleAspectFill)
            setBlendInput(image: _currBlendImageScaled!)
        }
    }
    
    
    // function to get a named image. Will check to see if a URL (provided by UIImagePicker) is provided
    private static func getBlendImageFromURL(_ urlString:String)->UIImage? {
        var image:UIImage? = nil
        if (urlString.contains(":")){ // URL?
            image = getImageFromAssets(assetUrl: urlString)
        } else if (_blendNameList.contains(urlString)){
            image = UIImage(named:urlString)
        } else {
            log.warning("Unknown Blend name:\(urlString)")
        }
        return image
    }
    
    
    //////////////////////////////////
    // MARK: - Sample Image Management
    //////////////////////////////////
    
    private static let _sampleNameList:[String] = ["sample_0846.png", "sample_1149.png", "sample_1151.png", "sample_1412.png", "sample_1504.png", "sample_1533.png", "sample_1629.png",
                                                   "sample_1687.png", "sample_1748.png", "sample_1902.png", "sample_2143.png", "sample_2216.png", "sample_9989.png"
                                                  ]
    private static var _currSampleName:String = "sample_9989.png"
    
    private static var _currSampleImage: UIImage? = nil
    
    private static var _currSampleImageScaled: UIImage? = nil
    private static var _currSampleSize: CGSize = CGSize(width: 0.0, height: 0.0)
    
    private static var _currSampleInput: PictureInput? = nil
    
    
    
    open static func getSampleImageList()->[String]{
        return _sampleNameList
    }
    
    
    
    open static func getCurrentSampleImageName()->String {
        return _currSampleName
    }
    
    
    
    open static func setCurrentSampleImageName(_ name:String) {
        if (name.contains(":")){ // URL?
            _currSampleName = name
            _currSampleImage = getSampleImageFromURL(name)
            _currSampleImageScaled = resizeImage(_currSampleImage, targetSize: _currSampleSize, mode:.scaleAspectFill)
            setSampleInput(image: _currSampleImageScaled!)
        } else if (_sampleNameList.contains(name)){
            log.debug("Current Sample image set to:\(name)")
            _currSampleName = name
            _currSampleImage = UIImage(named: _currSampleName)
            _currSampleImageScaled = resizeImage(getCurrentSampleImage(), targetSize: _currSampleSize, mode:.scaleAspectFill)
            setSampleInput(image: _currSampleImageScaled!)
        } else {
            log.warning("Unknown Sample name:\(name)")
        }
    }
    
    
    
    open static func getCurrentSampleImage()->UIImage? {

        checkSampleImage()

        return _currSampleImage
    }
    
    
    
    open static func getCurrentSampleImage(size:CGSize)->UIImage? {
        checkSampleImage()
        return _currSampleImageScaled
    }
    
    
    open static func getCurrentSampleImageSize()->CGSize{
        checkSampleImage()
        return _currSampleSize
    }
    
    
    open static func getCurrentSampleInput()->PictureInput? {
        checkSampleImage()
        return _currSampleInput
    }
    
    
    
    
    open static func getSampleImage(name: String, size:CGSize)->UIImage?{
        return resizeImage(getSampleImageFromURL(name), targetSize:size, mode:.scaleAspectFill)
    }
    
    open static func setSampleInput(image: UIImage){
        if (_currSampleInput != nil){
            _currSampleInput?.removeAllTargets()
        }
        _currSampleInput = PictureInput(image: image)
    }
    
    private static func checkSampleImage(){
        // make sure current sample image has been loaded
        if (_currSampleImage == nil){
            _currSampleImage = getSampleImageFromURL(_currSampleName)
            setSampleInput(image: _currSampleImage!)
        }
        
        // check to see if we have already resized
        if (_currSampleImageScaled == nil){
            if (_currSampleSize == CGSize.zero){
                _currSampleSize = (_currSampleImage?.size)!
            }
            _currSampleImageScaled = resizeImage(_currSampleImage, targetSize: _currSampleSize, mode:.scaleAspectFill)
            setSampleInput(image: _currSampleImageScaled!)
        }
    }

    
    // function to get a named image. Will check to see if a URL (provided by UIImagePicker) is provided
    private static func getSampleImageFromURL(_ urlString:String)->UIImage? {
        var image:UIImage? = nil
        if (urlString.contains(":")){ // URL?
            image = getImageFromAssets(assetUrl: urlString)
        } else if (_sampleNameList.contains(urlString)){
            image = UIImage(named:urlString)
        } else {
            log.warning("Unknown Sample name:\(urlString)")
        }
        return image
    }
    
    
    
    /////////////////////////////////////////////
    // MARK: - Management of Image being edited
    /////////////////////////////////////////////
    
    // NOTE: unlike other functions here, only photos from the library are edited
    
    private static var _currEditName:String = ""
    
    private static var _currEditImage: UIImage? = nil
    
    private static var _currEditImageScaled: UIImage? = nil
    private static var _currEditSize: CGSize = CGSize(width: 0.0, height: 0.0)

    
    open static func getCurrentEditImageName()->String {
        return _currEditName
    }
    
    
    
    open static func setCurrentEditImageName(_ name:String) {
        if (name.contains(":")){ // URL?
            _currEditName = name
            _currEditImage = getEditImageFromURL(name)
            //_currEditImageScaled = resizeImage(_currEditImage, targetSize: _currEditSize, mode:.scaleAspectFill) // don't know size
            log.verbose("Image set to:\(name)")
        } else {
            log.warning("Unexpected Edit name:\(name)")
        }
    }
    
    
    open static func setCurrentEditImage(name: String, image:UIImage?) {
            _currEditName = name
            _currEditImage = image
            //_currEditImageScaled = resizeImage(_currEditImage, targetSize: _currEditSize, mode:.scaleAspectFill) // don't know size
            log.verbose("Image set to:\(name)")
    }
    
    
    
    open static func getCurrentEditImage()->UIImage? {
        if (_currEditImage == nil){
            _currEditImage = getEditImageFromURL(_currEditName)
        }
        
        return _currEditImage
    }
    
    
    
    open static func getCurrentEditImage(size:CGSize)->UIImage? {
        // make sure current blend image has been loaded
        if (_currEditImage == nil){
            _currEditImage = getEditImageFromURL(_currEditName)
        }
        
        // check to see if we have already resized
        if (_currEditSize != size){
            _currEditSize = size
            _currEditImageScaled = resizeImage(getCurrentEditImage(), targetSize: size, mode:.scaleAspectFill)
        }
        
        return _currEditImageScaled
    }
    
    
    
    // function to get a named image. Will check to see if a URL (provided by UIImagePicker) is provided
    private static func getEditImageFromURL(_ urlString:String)->UIImage? {
        var image:UIImage? = nil
        if (urlString.contains(":")){ // URL?
            image = getImageFromAssets(assetUrl: urlString)
        } else {
            log.warning("Unexpected Edit name:\(urlString). Checking App-specific Assets..")
            image = UIImage(named:urlString)
        }
        
        if (image == nil){
            log.warning("No image found for:\(urlString)")
        }
        
        return image
    }
    
  
    
    //////////////////////////////////
    // MARK: - Image Utilities
    //////////////////////////////////
    
    
    
    private static func getImageFromAssets(assetUrl: String)->UIImage? {
        var image:UIImage? = nil
        if let imageUrl = NSURL(string: assetUrl) {
            let assets = PHAsset.fetchAssets(withALAssetURLs: [imageUrl as URL], options: nil)
            let asset = assets.firstObject
            let targetSize:CGSize = UIScreen.main.bounds.size // don't know what other size to use
            let options = PHImageRequestOptions()
            //        options.deliveryMode = PHImageRequestOptionsDeliveryMode.Opportunistic
            options.resizeMode = PHImageRequestOptionsResizeMode.exact
            options.isSynchronous = true // need to set this to get the full size image
            PHImageManager.default().requestImage(for: asset!, targetSize: targetSize, contentMode: .aspectFill, options: options, resultHandler: { img, _ in
                image = img
            })
        } else {
            log.error("Invalid URL: \(assetUrl)")
        }
        return image
    }
    

    
    open static func resizeImage(_ image: UIImage?, targetSize: CGSize, mode:UIViewContentMode) -> UIImage? {
        guard (image != nil) else {
            log.error("NIL image provided for resizing")
            return nil
        }
        
        let size = (image?.size)!
        
        // figure out if we need to rotate the image to match the target
        let srcIsLandscape:Bool = (size.width > size.height)
        let tgtIsLandscape:Bool = (targetSize.width > targetSize.height)
        let tgtIsSquare:Bool =  (fabs(Float(targetSize.width - targetSize.height)) < 0.001)
        
        var srcImage:UIImage? = image
        var srcSize:CGSize = CGSize.zero
        
        // rotate if the target is not square (why rotate?) and the aspect ratios are not the same
        if (!tgtIsSquare && (srcIsLandscape != tgtIsLandscape)){
            //log.warning("Need to rotate src image")
            if (srcIsLandscape) {
                srcImage = rotateImage(image, degrees: -90.0)
            } else {
                srcImage = rotateImage(image, degrees: 90.0)
            }
            srcSize.width = (image?.size.height)!
            srcSize.height = (image?.size.width)!
        } else {
            srcImage = image
            srcSize = size
        }
        
        
        // crop the image to match the aspect ratio of the target size (resize doesn't seem to work)
        let bounds = CGRect(x:0, y:0, width:srcSize.width, height:srcSize.height)
        let rect = AVMakeRect(aspectRatio: targetSize, insideRect: bounds)
        //let rect = fitIntoRect(srcSize: srcSize, targetRect: bounds, withContentMode: .scaleAspectFill)
        
        let cropSize = CGSize(width:rect.width, height:rect.height)
        let croppedImage = cropImage(srcImage, to:cropSize)
        
        // resize to match the target
        let newImage = scaleImage(croppedImage, targetSize:targetSize)
        
        /***
         // debug
         var nsize:CGSize = CGSize.zero
         if (newImage != nil){
         nsize = (newImage?.size)!
         }
         
         log.debug("SIZES: image:\(size), targetSize:\(targetSize), srcImage:\(srcSize), cropSize:\(cropSize), nsize:\(nsize)")
         let (r1n, r1d) = ClosestFraction.find(Float(size.width/size.height), maxDenominator:Int(size.height))
         let (r2n, r2d) = ClosestFraction.find(Float(targetSize.width/targetSize.height), maxDenominator:Int(targetSize.height))
         let (r3n, r3d) = ClosestFraction.find(Float(srcSize.width/srcSize.height), maxDenominator:Int(srcSize.height))
         let (r4n, r4d) = ClosestFraction.find(Float(cropSize.width/cropSize.height), maxDenominator:Int(cropSize.height))
         let (r5n, r5d) = ClosestFraction.find(Float(nsize.width/nsize.height), maxDenominator:Int(nsize.height))
         log.debug("RATIOS: image:\(r1n)/\(r1d), targetSize:\(r2n)/\(r2d), srcImage:\(r3n)/\(r3d), cropSize:\(r4n)/\(r4d), nsize:\(r5n)/\(r5d)")
         ***/
        
        return newImage
    }
    
    
    
    open static func scaleImage(_ image: UIImage?, targetSize:CGSize) -> UIImage? {
        guard (image != nil) else {
            log.error("NIL image provided for scaling")
            return nil
        }
        
        let size = (image?.size)!
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image?.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    
    
    open static func scaleImage(_ image: UIImage?, widthRatio:CGFloat, heightRatio:CGFloat) -> UIImage? {
        guard (image != nil) else {
            log.error("NIL image provided for scaling")
            return nil
        }
        
        let size = (image?.size.applying(CGAffineTransform(scaleX: widthRatio, y: heightRatio)))!
        
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        image?.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    
    
    open static func rotateImage(_ image: UIImage?, degrees: Double) -> UIImage? {
        guard (image != nil) else {
            log.error("NIL image provided for rotation")
            return nil
        }
        
        let radians = CGFloat(degrees*M_PI)/180.0 as CGFloat
        let size = (image?.size)!
        
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        let bitmap = UIGraphicsGetCurrentContext()
        bitmap!.translateBy(x: size.width / 2, y: size.height / 2)
        bitmap!.rotate(by: radians)
        bitmap!.scaleBy(x: 1.0, y: -1.0)
        let rect = CGRect(x:-size.width / 2, y:-size.height / 2, width:size.width, height:size.height)
        bitmap!.draw((image?.cgImage)!, in: rect, byTiling: false)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        return newImage
    }
    
    
    
    open static func cropImage(_ image:UIImage?, to:CGSize) -> UIImage? {
        guard (image != nil) else {
            log.error("NIL image provided for rotation")
            return nil
        }
        
        
        let contextSize: CGSize = (image?.size)!
        
        //Set to square
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        let cropAspect: CGFloat = to.width / to.height
        
        var cropWidth: CGFloat = to.width
        var cropHeight: CGFloat = to.height
        
        if to.width > to.height { //Landscape
            cropWidth = contextSize.width
            cropHeight = contextSize.width / cropAspect
            posY = (contextSize.height - cropHeight) / 2
        } else if to.width < to.height { //Portrait
            cropHeight = contextSize.height
            cropWidth = contextSize.height * cropAspect
            posX = (contextSize.width - cropWidth) / 2
        } else { //Square
            if contextSize.width >= contextSize.height { //Square on landscape (or square)
                cropHeight = contextSize.height
                cropWidth = contextSize.height * cropAspect
                posX = (contextSize.width - cropWidth) / 2
            }else{ //Square on portrait
                cropWidth = contextSize.width
                cropHeight = contextSize.width / cropAspect
                posY = (contextSize.height - cropHeight) / 2
            }
        }
        
        let rect: CGRect = CGRect(x:posX, y:posY, width:cropWidth, height:cropHeight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImage = (image?.cgImage)!.cropping(to: rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let cropped: UIImage = UIImage(cgImage: imageRef, scale: (image?.scale)!, orientation: (image?.imageOrientation)!)
        
        UIGraphicsBeginImageContextWithOptions(to, true, (image?.scale)!)
        cropped.draw(in: CGRect(x:0, y:0, width:to.width, height:to.height))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resized
    }
    
    
    
    static func aspectFit(aspectRatio : CGSize, boundingSize: CGSize) -> CGSize {
        let mW = boundingSize.width / aspectRatio.width;
        let mH = boundingSize.height / aspectRatio.height;
        var fitSize: CGSize = boundingSize
        
        if( mH < mW ) {
            fitSize.width = boundingSize.height / aspectRatio.height * aspectRatio.width;
        }
        else if( mW < mH ) {
            fitSize.height = boundingSize.width / aspectRatio.width * aspectRatio.height;
        }
        
        return fitSize;
    }
    
    
    
    static func aspectFill(aspectRatio :CGSize, minimumSize: CGSize) -> CGSize {
        let mW = minimumSize.width / aspectRatio.width;
        let mH = minimumSize.height / aspectRatio.height;
        var fillSize: CGSize = minimumSize
        
        if( mH > mW ) {
            fillSize.width = minimumSize.height / aspectRatio.height * aspectRatio.width;
        }
        else if( mW > mH ) {
            fillSize.height = minimumSize.width / aspectRatio.width * aspectRatio.height;
        }
        
        return fillSize;
    }
    
    
    open static func fitIntoRect(srcSize:CGSize, targetRect: CGRect, withContentMode contentMode: UIViewContentMode)->CGRect {
        
        var rect:CGRect = CGRect.zero
        
        if !(contentMode == .scaleAspectFit || contentMode == .scaleAspectFill) {
            // Not implemented
            rect.origin.x = 0
            rect.origin.y = 0
            rect.size.width = srcSize.width
            rect.size.height = srcSize.height
            return rect
        }
        
        var scale = targetRect.width / srcSize.width
        
        if contentMode == .scaleAspectFit {
            if srcSize.height * scale > targetRect.height {
                scale = targetRect.height / srcSize.height
            }
        } else if contentMode == .scaleAspectFill {
            if srcSize.height * scale < targetRect.height {
                scale = targetRect.height / srcSize.height
            }
        }
        
        let scaledWidth = srcSize.width * scale
        let scaledHeight = srcSize.height * scale
        let scaledX = targetRect.width / 2 - scaledWidth / 2
        let scaledY = targetRect.height / 2 - scaledHeight / 2
        
        rect.origin.x = scaledX
        rect.origin.y = scaledY
        rect.size.width = scaledWidth
        rect.size.height = scaledHeight
        
        return rect
    }
}
