//
//  ImageManager.swift
//  phixer
//
// Manages the various types of internal images (blends, samples, image under edit etc.)
//
//  Created by Philip Price on 11/7/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import CoreImage
import AVFoundation
import Photos

import SwiftyJSON

// Delegate interface

protocol ImageManagerDelegate: class {
    func blendImageChanged(name: String)
    func sampleImageChanged(name: String)
    func userImageSaved()
}

class ImageManager {
    

    
    //////////////////////////////////
    // MARK: - Blend Image/Layer Management
    //////////////////////////////////
    
    private static var _blendNameList:[String] = []

    private static var _currBlendName:String = "_film_grain_numba_1__by_su_y.jpg"

    private static var _currBlendImage: UIImage? = nil
    
    private static var _currBlendImageScaled: UIImage? = nil
    private static var _currBlendSize: CGSize = CGSize(width: 0.0, height: 0.0)
    
    private static var _currBlendInput: CIImage? = nil
    
  
    
    public static func setBlendList(_ list:[String]){
        _blendNameList = list
    }
    
    public static func getBlendImageList()->[String]{
        return _blendNameList
    }
    
    
    
    public static func getCurrentBlendImageName()->String {
        return _currBlendName
    }
    
    
    
    public static func setCurrentBlendImageName(_ name:String) {
        
        guard !(name.isEmpty) else {
            log.error("Blend name is empty, ignoring")
            return
        }
        
        //_currBlendImage = getImageFromAssets(assetID:name, size:_currBlendSize)
        
        _currBlendImage = getImageFromAssets(assetID:name)
        if _currBlendImage != nil {
            _currBlendName = name
            _currBlendInput = CIImage(image:_currBlendImage!)
            _currBlendImageScaled = _currBlendImage
            _currBlendSize = _currBlendImage!.size
            log.verbose("Image set to:\(name)")
            updateStoredSettings()
        } else {
            log.error("Could not find image: \(name)")
        }

    }
    
    
    
    
    public static func getCurrentBlendImage()->CIImage? {
        checkBlendImage()
        return _currBlendInput
    }

    public static func getCurrentBlendImage(size:CGSize)->CIImage? {
        checkBlendImage()
        var scaledImage:UIImage? = nil
        scaledImage = resizeImage(_currBlendImage, targetSize: size, mode:.scaleAspectFill)
        return CIImage(image:scaledImage!)
    }
    
    
    public static func getCurrentBlendInput()->CIImage? {
        checkBlendImage()
        return _currBlendInput
    }
    
    
    public static func getBlendImage(name: String, size:CGSize)->UIImage?{
        return getImageFromAssets(assetID:name, size: size)
    }
    
    
    public static func setBlendInput(image: UIImage){
        _currBlendInput = CIImage(image: image)
    }
    
    // returns the w:h aspect ratio
    public static func getBlendImageAspectRatio() -> CGFloat{
        var ratio: CGFloat = 1.0
        
        checkBlendImage()
        
        // calculate the aspect ratio as a 1:N (w:h) floating point number
        if ((_currBlendImage?.size.height)!>CGFloat(0.0)){
            ratio = (_currBlendImage?.size.width)! / (_currBlendImage?.size.height)!
        }
        return ratio
    }
    
    private static func checkBlendImage(){
        // make sure current blend image has been loaded
        if (_currBlendImage == nil){
            if _currBlendName.isEmpty { _currBlendName = getDefaultBlendImageName()! }
            _currBlendImage = getImageFromAssets(assetID:_currBlendName, size:_currBlendSize)
            _currBlendImageScaled = _currBlendImage
            setBlendInput(image: _currBlendImageScaled!)
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
    
 
    
    // returns the default name
    public static func getDefaultBlendImageName()->String?{
        //checkBlendImage()
        
        if (_currBlendName.isEmpty){
            if (_blendNameList.count>0) {
                _currBlendName = _blendNameList[0]
            } else {
                _currBlendName = "_film_grain_numba_1__by_su_y.jpg" // desperation, hard-code the name
            }
        }
        return _currBlendName
    }
    
    //////////////////////////////////
    // MARK: - Sample Image Management
    //////////////////////////////////
    
    private static var _sampleNameList:[String] = [ ]
    private static var _currSampleName:String = "sample_9989.png"

    private static var _currSampleImage: UIImage? = nil
    
    private static var _currSampleImageScaled: UIImage? = nil
    private static var _currSampleSize: CGSize = CGSize(width: 0.0, height: 0.0)
    
    private static var _currSampleInput: CIImage? = nil
    
    
    
    public static func setSampleList(_ list:[String]){
        _sampleNameList = list
    }

    public static func getSampleImageList()->[String]{
        return _sampleNameList
    }
    
    
    
    public static func getCurrentSampleImageName()->String {

        return _currSampleName
    }
    
    
    
    public static func setCurrentSampleImageName(_ name:String) {
        guard !(name.isEmpty) else {
            log.error("Sample name is empty, ignoring")
            return
        }
        
        _currSampleImage = getImageFromAssets(assetID:name)
        if _currSampleImage != nil {
            _currSampleName = name
            _currSampleInput = CIImage(image:_currSampleImage!)
            _currSampleImageScaled = _currSampleImage
            _currSampleSize = _currSampleImage!.size
            log.verbose("Image set to:\(name)")
            updateStoredSettings()
        } else {
            log.error("Could not find image: \(name)")
        }

        /***
        if (isAssetID(name)){ // Asset?
            log.debug("Current Sample image set to:\(name)")
            _currSampleName = name
            _currSampleImage = getImageFromAssets(assetID:name, size:_currSampleSize)
            setSampleInput(image: _currSampleImage!)
           //_currSampleImageScaled = resizeImage(_currSampleImage, targetSize: _currSampleSize, mode:.scaleAspectFill)
            //setSampleInput(image: _currSampleImageScaled!)
         } else { // allow anything as long as the image is created
            log.debug("Current Sample image set to:\(name)")
            _currSampleName = name
            _currSampleImage = UIImage(named: _currSampleName)
            if _currSampleImage != nil {
                //_currSampleImageScaled = resizeImage(UIImage(ciImage:getCurrentSampleImage()!), targetSize: _currSampleSize, mode:.scaleAspectFill)
                _currSampleImageScaled = resizeImage(_currSampleImage, targetSize: _currSampleSize, mode:.scaleAspectFill)
                if _currSampleImageScaled != nil {
                    setSampleInput(image: _currSampleImageScaled!)
                } else {
                    log.error("Could not resize image for: \(_currSampleName), size:\(_currSampleSize)")
                }
                
            } else {
                log.error("Could not create image for: \(_currSampleName)")
            }
        }
         ***/
        updateStoredSettings()
    }
    
    
    public static func getCurrentSampleImage()->CIImage? {
        checkSampleImage()
        return _currSampleInput
    }
    
    public static func getCurrentSampleImage(size:CGSize)->CIImage? {
        checkSampleImage()
        var scaledImage:UIImage? = nil
        scaledImage = resizeImage(_currSampleImage, targetSize: size, mode:.scaleAspectFill)
        return CIImage(image:scaledImage!)
    }

    
    public static func getCurrentSampleImageSize()->CGSize{
        checkSampleImage()
        return _currSampleSize
    }
    
    
    public static func getCurrentSampleInput()->CIImage? {
        checkSampleImage()
        return _currSampleInput
    }
    
    
    // returns the w:h aspect ratio
    public static func getSampleImageAspectRatio() -> CGFloat{
        var ratio: CGFloat = 1.0
        
        checkSampleImage()
        
        // calculate the aspect ratio as a 1:N (w:h) floating point number
        if ((_currSampleImage?.size.height)!>CGFloat(0.0)){
            ratio = (_currSampleImage?.size.width)! / (_currSampleImage?.size.height)!
        }
        return ratio
    }
  
    
    
    public static func getSampleImage(name: String, size:CGSize)->CIImage?{
        return CIImage(image:getImageFromAssets(assetID:name, size:size)!)
    }
    
    public static func setSampleInput(image: UIImage){
        _currSampleImage = image
        _currSampleInput = CIImage(image: image)
    }
    
    private static func checkSampleImage(){
        // make sure current sample image has been loaded
        if (_currSampleImage == nil){
            if _currSampleName.isEmpty { _currSampleName = getDefaultSampleImageName()! }
            _currSampleImage = getImageFromAssets(assetID:_currSampleName, size:_currSampleSize)
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

    
    
    
    
    // returns the default name
    public static func getDefaultSampleImageName()->String?{
        //checkSampleImage()
        
        if (_currSampleName.isEmpty){
            if (_sampleNameList.count>0) {
                _currSampleName = _sampleNameList[0]
            } else {
                _currSampleName = "sample_1149.png" // desperation, hard-code the name
            }
        }
        return _currSampleName
    }
    
  
    /////////////////////////////////////////////
    // MARK: - Management of Image being edited
    /////////////////////////////////////////////
    
    // NOTE: unlike other functions here, only photos from the library are edited
    
    private static var _currEditName:String = ""
    
    private static var _currEditImage: UIImage? = nil
    private static var _currEditInput: CIImage? = nil
    
    private static var _currEditImageScaled: UIImage? = nil
    private static var _currEditSize: CGSize = CGSize(width: 0.0, height: 0.0)

    
    public static func getCurrentEditImageName()->String {
        checkEditImage()
        return _currEditName
    }
    
    
    
    public static func setCurrentEditImageName(_ name:String) {
        var ename:String
        ename = name
        if (ename.isEmpty){
            checkEditImage()
            ename = _currEditName
        }
        
        //_currEditImage = getImageFromAssets(assetID:ename, size:_currEditSize)
        _currEditImage = getImageFromAssets(assetID:ename)
        if _currEditImage != nil {
            _currEditName = ename
            _currEditInput = CIImage(image:_currEditImage!)
            _currEditSize = _currEditImage!.size
            log.verbose("Image set to:\(ename)")
            updateStoredSettings()
        } else {
            log.error("Could not find image: \(ename)")
        }
    }
    
    
    public static func setCurrentEditImage(name: String, image:UIImage?) {
        guard image != nil else {
            log.warning("NIL Edit Image supplied")
            return
        }
        _currEditName = name
        _currEditImage = image
        _currEditInput = CIImage(image:_currEditImage!)
        _currEditSize = (image?.size)!
        //_currEditImageScaled = resizeImage(_currEditImage, targetSize: _currEditSize, mode:.scaleAspectFill) // don't know size
        log.verbose("Image set to:\(name)")
    }
    
    
    
    public static func getCurrentEditImage()->CIImage? {
        return getCurrentEditImage(size:_currEditSize)
    }
    
    
    
    public static func getCurrentEditImage(size:CGSize)->CIImage? {
        // make sure current blend image has been loaded
        if (_currEditImage == nil){
            _currEditImage = getImageFromAssets(assetID:_currEditName, size:size)
            _currEditInput = CIImage(image:_currEditImage!)
        }
        
        // check to see if we have already resized
        if (_currEditSize != size){
            _currEditSize = size
            _currEditImageScaled = resizeImage(UIImage(ciImage:getCurrentEditImage()!), targetSize: size, mode:.scaleAspectFill)
        }
        
        return CIImage(image:_currEditImageScaled!)
    }
    
    
    public static func getCurrentEditInput()->CIImage? {
        checkEditImage()
        return _currEditInput
    }
    
    
    
    public static func getCurrentEditImageSize()->CGSize{
        checkEditImage()
        return _currEditSize
    }

    

  
    
    // returns the w:h aspect ratio
    public static func getEditImageAspectRatio() -> CGFloat{
        var ratio: CGFloat = 1.0
        
        checkEditImage()
        
        // calculate the aspect ratio as a 1:N (w:h) floating point number
        if ((_currEditImage?.size.height)!>CGFloat(0.0)){
            ratio = (_currEditImage?.size.width)! / (_currEditImage?.size.height)!
        }
        return ratio
    }
    
    
    public static func setEditInput(image: UIImage){
        _currEditInput = CIImage(image: image)
        _currEditSize = image.size
    }

    
    private static func checkEditImage(){
        
        if _currEditName.isEmpty  {
            _currEditSize = _currSampleSize // just to set it to something reasonable
            _currEditName = _currSampleName
           log.debug("Edit image not set")
            getLatestPhotoName(completion: { (name: String?) in
                //TODO: handle case where there is no photo (e.g. on simulator)
                if name == nil {
                    _currEditName = _currSampleName
                } else {
                    _currEditName = name!
                }
            })

            //return
        }
        
        // make sure current sample image has been loaded
        if (_currEditImage == nil){
            _currEditImage = getImageFromAssets(assetID:_currEditName, size:_currEditSize)
            if _currEditImage != nil {
                setEditInput(image: _currEditImage!)
                
                // check to see if we have already resized
                if (_currEditImageScaled == nil){
                    if (_currEditSize == CGSize.zero){
                        _currEditSize = (_currEditImage?.size)!
                    }
                    _currEditImageScaled = resizeImage(_currEditImage, targetSize: _currEditSize, mode:.scaleAspectFit)
                    setEditInput(image: _currEditImageScaled!)
                }
            } else {
                log.error("Could not set edit image")
            }
        }
        if (_currEditSize == CGSize.zero){
            if _currEditImage != nil { _currEditSize = (_currEditImage?.size)! }
        }
    }
    
    
    // returns the default name
    public static func getDefaultEditImageName()->String?{
        checkEditImage()
        return _currEditName
    }
    
    
    
    //////////////////////////////////
    // MARK: - Persistent Storage Utilities
    //////////////////////////////////
    
    fileprivate static func updateStoredSettings(){
        print("updateStoredSettings()")
        let settings = SettingsRecord()
        
        settings.blendImage = getCurrentBlendImageName()
        settings.sampleImage = getCurrentSampleImageName()
        settings.editImage = getCurrentEditImageName()
        
        Database.saveSettings(settings)
    }

    
    
    
    //////////////////////////////////
    // MARK: - Image Utilities
    //////////////////////////////////
    
    // returns the name (Asset) of the latest photo in the Camera Roll. Useful as a default setting
    // NOTE: returns asynchronously via the 'completion(name)' callback

    public static func getLatestPhotoName(completion: (_ name: String?) -> Void){
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        //fetchOptions.fetchLimit = 1
        
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        let last = fetchResult.lastObject
        
        if let lastAsset = last {
            completion(lastAsset.localIdentifier)
        } else {
            completion(nil)
        }

    }
    
    // return the requested asset with the original asset size
    private static func getImageFromAssets(assetID: String)->UIImage? {
        var image:UIImage? = nil
        
        if isAssetID(assetID) { // Asset?
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options:nil)
            
            let asset = assets.firstObject
            if asset != nil {
                let options = PHImageRequestOptions()
                //        options.deliveryMode = PHImageRequestOptionsDeliveryMode.Opportunistic
                options.resizeMode = PHImageRequestOptionsResizeMode.exact
                options.isSynchronous = true // need to set this to get the full size image
                PHImageManager.default().requestImageData(for: asset!, options: options, resultHandler: { data, _, _, _ in
                    image = data.flatMap { UIImage(data: $0) }
                })
            } else {
                log.error("Invalid asset: \(assetID)")
            }
        } else {
            // not a managed asset, load via 'regular' method
            image = UIImage(named:assetID)
        }
        
        return image
    }
    
    
    // return the requested asset with the specified size
    private static func getImageFromAssets(assetID: String, size:CGSize)->UIImage? {
        var image:UIImage? = nil
        var tsize:CGSize
        
        tsize = size
        if (tsize.width < 0.01) || (tsize.height < 0.01) {
            tsize = UIScreen.main.bounds.size // don't know what other size to use
        }
        
        if isAssetID(assetID) { // Asset?
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options:nil)
            
            let asset = assets.firstObject
            if asset != nil {
                let options = PHImageRequestOptions()
                //        options.deliveryMode = PHImageRequestOptionsDeliveryMode.Opportunistic
                options.resizeMode = PHImageRequestOptionsResizeMode.exact
                options.isSynchronous = true // need to set this to get the full size image
                PHImageManager.default().requestImage(for: asset!, targetSize: tsize, contentMode: .aspectFill, options: options, resultHandler: { img, _ in
                    image = img
                })
            } else {
                log.error("Invalid asset: \(assetID)")
            }
        } else {
            // not a managed asset, load via 'regular' method
            let tmpimage2 = UIImage(named:assetID)
            image = resizeImage(tmpimage2, targetSize: tsize, mode:.scaleAspectFill)
        }

        return image
    }


    
    public static func resizeImage(_ image: UIImage?, targetSize: CGSize, mode:UIViewContentMode) -> UIImage? {
        guard (image != nil) else {
            log.error("NIL image provided for resizing")
            return nil
        }
        
        let size = (image?.size)!
        var tsize = targetSize
        if (targetSize.width<0.01) && (targetSize.height<0.01) { tsize = size }
        
        // figure out if we need to rotate the image to match the target
        let srcIsLandscape:Bool = (size.width > size.height)
        let tgtIsLandscape:Bool = (tsize.width > tsize.height)
        let tgtIsSquare:Bool =  (fabs(Float(tsize.width - tsize.height)) < 0.001)
        
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
        let rect = AVMakeRect(aspectRatio: tsize, insideRect: bounds)
        //let rect = fitIntoRect(srcSize: srcSize, targetRect: bounds, withContentMode: .scaleAspectFill)
        
        let cropSize = CGSize(width:rect.width, height:rect.height)
        let croppedImage = cropImage(srcImage, to:cropSize)
        
        // resize to match the target
        let newImage = scaleImage(croppedImage, targetSize:tsize)
        
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
    
    
    
    public static func scaleImage(_ image: UIImage?, targetSize:CGSize) -> UIImage? {
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
    
    
    
    public static func scaleImage(_ image: UIImage?, widthRatio:CGFloat, heightRatio:CGFloat) -> UIImage? {
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
    
    
    
    public static func rotateImage(_ image: UIImage?, degrees: Double) -> UIImage? {
        guard (image != nil) else {
            log.error("NIL image provided for rotation")
            return nil
        }
        
        let radians = CGFloat(degrees*Double.pi)/180.0 as CGFloat
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
    
    
    
    public static func cropImage(_ image:UIImage?, to:CGSize) -> UIImage? {
        guard (image != nil) else {
            log.error("NIL image provided for rotation")
            return nil
        }
        
        
        let contextSize: CGSize = (image?.size)!
        var resized:UIImage?
        
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
        let inCGImage = (image?.cgImage)
        if inCGImage != nil {

            let imageRef: CGImage = inCGImage!.cropping(to: rect)!
            
            // Create a new image based on the imageRef and rotate back to the original orientation
            let cropped: UIImage = UIImage(cgImage: imageRef, scale: (image?.scale)!, orientation: (image?.imageOrientation)!)
            
            UIGraphicsBeginImageContextWithOptions(to, true, (image?.scale)!)
            cropped.draw(in: CGRect(x:0, y:0, width:to.width, height:to.height))
            resized = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            // could not get CGImage from CIImage, so try to re-create
            
        } else {
            resized = image // what else?
            log.error("Could not extract CGImage from UIImage")
        }
        
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
    
    
    public static func fitIntoRect(srcSize:CGSize, targetRect: CGRect, withContentMode contentMode: UIViewContentMode)->CGRect {
        
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
    
    
    private static func isAssetID(_ str:String)->Bool{
        if (str.contains("-")) && (str.contains("/")) {
            return true
        } else {
            return false
        }
    }
}
