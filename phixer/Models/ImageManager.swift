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
//import UIKit
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
    

    private static let defaultSampleName:String = "sample_beach_1678.png"
    
    //////////////////////////////////
    // MARK: - Blend Image/Layer Management
    //////////////////////////////////
    
    private static var _blendNameList:[String] = []

    private static var _currBlendName:String = "_film_grain_numba_1__by_su_y.jpg"

    private static var _currBlendImage: CIImage? = nil
    
    private static var _currBlendImageScaled: CIImage? = nil
    private static var _currBlendSize: CGSize = CGSize(width: 0.0, height: 0.0)
    
    //private static var _currBlendInput: CIImage? = nil
    
  
    
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
        
        _currBlendName = name
        _currBlendImage = nil // forces re-load if something tries to access this
        log.verbose("Blend Image set to:\(name)")
        updateStoredSettings()

        /*** delay loading until requested
        var image = getImageFromAssets(assetID:name)
        if image != nil {
            let orientation = imageOrientationToExifOrientation(value: image!.imageOrientation)
            _currBlendImage = CIImage(image: image!)?.oriented(forExifOrientation: Int32(orientation.rawValue))
            //_currBlendName = name
            _currBlendImageScaled = _currBlendImage
            _currBlendSize = _currBlendImage!.extent.size
            //updateStoredSettings()
            image = nil
        } else {
            log.error("Could not find image: \(name)")
        }
        ***/

    }
    
    
    
    
    public static func getCurrentBlendImage()->CIImage? {
        checkBlendImage()
        return _currBlendImage
    }

    public static func getCurrentBlendImage(size:CGSize)->CIImage? {
        checkBlendImage()
        
        // if requested size is close to currently stored size, just return the stored image and save memory
        // the same sized image is often requested multiple times
        
        if (abs(size.width - _currBlendSize.width)>1.0) || (abs(size.height - _currBlendSize.height)>1.0) {
            //let scaledImage = resizeImage(UIImage(ciImage: _currBlendImage!), targetSize: size, mode:.scaleAspectFill)
            //_currBlendImageScaled = CIImage(image:scaledImage!)
            _currBlendImageScaled = _currBlendImage?.resize(size: size)
            _currBlendSize = size
        }
        return _currBlendImageScaled
    }
    
    /***
    public static func getCurrentBlendInput()->CIImage? {
        checkBlendImage()
        return _currBlendInput
    }
    ***/
    
    public static func getBlendImage(name: String, size:CGSize)->UIImage?{
        return getImageFromAssets(assetID:name, size: size)
    }
    
    /***
    public static func setBlendInput(image: UIImage){
        _currBlendInput = CIImage(image: image)
    }
    ***/
    
    // returns the w:h aspect ratio
    public static func getBlendImageAspectRatio() -> CGFloat{
        var ratio: CGFloat = 1.0
        
        checkBlendImage()
        
        // calculate the aspect ratio as a 1:N (w:h) floating point number
        if ((_currBlendImage?.extent.size.height)!>CGFloat(0.0)){
            ratio = (_currBlendImage?.extent.size.width)! / (_currBlendImage?.extent.size.height)!
        }
        return ratio
    }
    
    private static func checkBlendImage(){
        
        // make sure current blend image has been loaded
        if (_currBlendImage == nil){
            if _currBlendName.isEmpty { _currBlendName = getDefaultBlendImageName()! }
            //_currBlendImage = CIImage(image: getImageFromAssets(assetID:_currBlendName, size:_currBlendSize)!)
            //_currBlendImageScaled = _currBlendImage

            
            var image = getImageFromAssets(assetID:_currBlendName)
            if image != nil {
                let orientation = imageOrientationToExifOrientation(value: image!.imageOrientation)
                _currBlendImage = CIImage(image: image!)?.oriented(forExifOrientation: Int32(orientation.rawValue))
                _currBlendImageScaled = _currBlendImage
                _currBlendSize = _currBlendImage!.extent.size
                //updateStoredSettings()
                image = nil
            } else {
                log.error("Could not find image: \(_currBlendName)")
            }
        }
        
        // check to see if we have already resized
        if (_currBlendImageScaled == nil){
            if (_currBlendSize == CGSize.zero){
                _currBlendSize = (_currBlendImage?.extent.size)!
            }
            //let scaledImage = resizeImage(UIImage(ciImage: _currBlendImage!), targetSize: _currBlendSize, mode:.scaleAspectFill)
            //_currBlendImageScaled = CIImage(image:scaledImage!)
            _currBlendImageScaled = _currBlendImage?.resize(size: _currBlendSize)
            //setBlendInput(image: _currBlendImageScaled!)
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
    
    
    /*** Removing concept of sample image
 
    //////////////////////////////////
    // MARK: - Sample Image Management
    //////////////////////////////////
    
    private static var _sampleNameList:[String] = [ ]
    private static var _currSampleName:String = "sample_beach_1678.png"

    private static var _currSampleImage: CIImage? = nil
    
    private static var _currSampleImageScaled: CIImage? = nil
    private static var _currSampleSize: CGSize = CGSize(width: 0.0, height: 0.0)
    
    //private static var _currSampleInput: CIImage? = nil
    
    
    
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
/***
        guard !(name.isEmpty) else {
            log.error("Sample name is empty, ignoring")
            return
        }
 ***/
        var sname = name
        
        // if empty, set to edit image
        if name.isEmpty {
            sname = getCurrentEditImageName()
        }
        
/*** try 2: don't load image until it is requested
        var image = getImageFromAssets(assetID:sname)
        if image != nil {
            //_currSampleImage = CIImage(image: image!)
            let orientation = imageOrientationToExifOrientation(value: image!.imageOrientation)
            _currSampleImage = CIImage(image: image!)?.oriented(forExifOrientation: Int32(orientation.rawValue))

             _currSampleName = sname
            //_currSampleInput = CIImage(image:_currSampleImage!)
            _currSampleImageScaled = _currSampleImage
            _currSampleSize = (image?.size)!
            log.verbose("Image set to:\(sname)")
            updateStoredSettings()
            
            image = nil // free memory
            
        } else {
            log.error("Could not find image: \(sname)")
        }
 ***/
        let oldname = _currSampleName
        _currSampleName = sname
        updateStoredSettings()
        if !oldname.isEmpty {
            _currSampleImage = nil // force reload when accessed
        }
    }
    
    
    public static func getCurrentSampleImage()->CIImage? {
        checkSampleImage()
        return _currSampleImage
    }
    
    public static func getCurrentSampleImage(size:CGSize)->CIImage? {
        checkSampleImage()
        
        // if requested size is close to currently stored size, just return the stored image and save memory
        // the same sized image is often requested multiple times
        
        if (abs(size.width - _currSampleSize.width)>1.0) || (abs(size.height - _currSampleSize.height)>1.0) {
            //let scaledImage = resizeImage(UIImage(ciImage: _currSampleImage!), targetSize: size, mode:.scaleAspectFill)
            //_currSampleImageScaled = CIImage(image:scaledImage!)
            _currSampleImageScaled = _currSampleImage?.resize(size: size)
            _currSampleSize = size
        }
        return _currSampleImageScaled
    }

    
    public static func getCurrentSampleImageSize()->CGSize{
        checkSampleImage()
        return _currSampleSize
    }
    
    
    public static func getCurrentSampleInput()->CIImage? {
        checkSampleImage()
        return _currSampleImage
    }
    
    
    // returns the w:h aspect ratio
    public static func getSampleImageAspectRatio() -> CGFloat{
        var ratio: CGFloat = 1.0
        
        checkSampleImage()
        
        // calculate the aspect ratio as a 1:N (w:h) floating point number
        if ((_currSampleImage?.extent.size.height)!>CGFloat(0.0)){
            ratio = (_currSampleImage?.extent.size.width)! / (_currSampleImage?.extent.size.height)!
        }
        return ratio
    }
  
    
    
    public static func getSampleImage(name: String, size:CGSize)->CIImage?{
        return CIImage(image:getImageFromAssets(assetID:name, size:size)!)
    }
    
    /***
    public static func setSampleInput(image: UIImage){
        _currSampleImage = image
        _currSampleInput = CIImage(image: image)
    }
    ***/
    
    private static func checkSampleImage(){
        // make sure current sample image has been loaded
        if (_currSampleImage == nil){
            if _currSampleName.isEmpty { _currSampleName = getDefaultSampleImageName()! }
            //_currSampleImage = CIImage(image: getImageFromAssets(assetID:_currSampleName, size:_currSampleSize)!)
            //setSampleInput(image: _currSampleImage!)
            
            var image = getImageFromAssets(assetID:_currSampleName)
            if image != nil {
                let orientation = imageOrientationToExifOrientation(value: image!.imageOrientation)
                _currSampleImage = CIImage(image: image!)?.oriented(forExifOrientation: Int32(orientation.rawValue))
                
                _currSampleImageScaled = _currSampleImage
                _currSampleSize = (image?.size)!
                log.verbose("Retrieved image:\(_currSampleName)")
                
                image = nil // free memory
                
            } else {
                log.error("Could not find image: \(_currSampleName)")
            }
        }
        
        // check to see if we have already resized
        if (_currSampleImageScaled == nil){
            if (_currSampleSize == CGSize.zero){
                _currSampleSize = (_currSampleImage?.extent.size)!
            }
            //let scaledImage = resizeImage(UIImage(ciImage: _currSampleImage!), targetSize: _currSampleSize, mode:.scaleAspectFill)
            //_currSampleImageScaled = CIImage(image:scaledImage!)
            _currSampleImageScaled = _currSampleImage?.resize(size: _currSampleSize)
            //setSampleInput(image: _currSampleImageScaled!)
        }
    }

    
    
    
    
    // returns the default name
    public static func getDefaultSampleImageName()->String?{
        //checkSampleImage()
        
        if (_currSampleName.isEmpty){
            if !_currEditName.isEmpty {
                _currSampleName = _currEditName
            } else {
                if (_sampleNameList.count>0) {
                    _currSampleName = _sampleNameList[0]
                } else {
                    _currSampleName = defaultSampleName // desperation, hard-code the name
                }
            }
        }
        return _currSampleName
    }
    ***/
  
    /////////////////////////////////////////////
    // MARK: - Management of Image being edited
    /////////////////////////////////////////////
    
    // NOTE: unlike other functions here, only photos from the library are edited
    
    private static var _currEditName:String = ""
    
    private static var _currEditImage: CIImage? = nil
    //private static var _currEditInput: CIImage? = nil
    
    private static var _currEditImageScaled: CIImage? = nil
    private static var _currEditSize: CGSize = CGSize(width: 0.0, height: 0.0)
    
    private static var _currEditImageOrientation: CGImagePropertyOrientation = .up
    

    
    public static func getCurrentEditImageName()->String {
        checkEditImage()
        return _currEditName
    }
    
    
    
    public static func setCurrentEditImageName(_ name:String) {
        var ename:String
        
        log.debug("name: \(name)")
        ename = name
        if (ename.isEmpty){
            checkEditImage()
            ename = _currEditName
        }
        
        //_currEditImage = getImageFromAssets(assetID:ename, size:_currEditSize)
        let image = getImageFromAssets(assetID:ename)
        if image != nil {
            //_currEditImage = CIImage(image: image!)
            //_currEditImage = CIImage(image: image!, options: [kCIImageApplyOrientationProperty:true])?.oriented(.up)
            
            _currEditImageOrientation = imageOrientationToExifOrientation(value: image!.imageOrientation)
            log.debug("orientation: UI:\(image!.imageOrientation.rawValue) CG:\(_currEditImageOrientation)")
            _currEditImage = CIImage(image: image!)?.oriented(forExifOrientation: Int32(_currEditImageOrientation.rawValue))
            
            // TODO: resize to smaller image? (Use full size only on save ???)
        } else {
            log.error("NIL image returned for: \(ename)")
        }

        if _currEditImage != nil {
            _currEditName = ename
            //_currEditInput = CIImage(image:_currEditImage!)
            _currEditSize = (_currEditImage?.extent.size)!
            log.verbose("Image set to:\(name), frame:\(_currEditImage?.extent)")
           updateStoredSettings()
        } else {
            log.error("Could not find image: \(ename)")
        }
    }
    
    
    public static func setCurrentEditImage(name: String, image:CIImage?) {
        guard image != nil else {
            log.warning("NIL Edit Image supplied")
            return
        }
        _currEditName = name
        _currEditImage = image
        _currEditImageScaled = image
        _currEditSize = (image?.extent.size)!
        //_currEditImageScaled = resizeImage(_currEditImage, targetSize: _currEditSize, mode:.scaleAspectFill) // don't know size
        log.verbose("Image set to:\(name), frame:\(image?.extent)")
    }
    
    
    
    public static func getCurrentEditImage()->CIImage? {
        //return getCurrentEditImage(size:_currEditSize)
        return _currEditImage
    }
    
    
    
    public static func getCurrentEditImage(size:CGSize)->CIImage? {
        
        // if requested size is close to currently stored size, just return the stored image and save memory
        // the same sized image is often requested multiple times
        
        if (abs(size.width - _currEditSize.width)>1.0) || (abs(size.height - _currEditSize.height)>1.0) {
            _currEditImageScaled = _currEditImage?.resize(size: size)
            _currEditSize = size
        }
        
        return _currEditImageScaled
    }
    
    /***
    public static func getCurrentEditInput()->CIImage? {
        checkEditImage()
        return _currEditImage
    }
    ***/
    
    
    public static func getCurrentEditImageSize()->CGSize{
        checkEditImage()
        return _currEditSize
    }

    

  
    
    // returns the w:h aspect ratio
    public static func getEditImageAspectRatio() -> CGFloat{
        var ratio: CGFloat = 1.0
        
        checkEditImage()
        
        // calculate the aspect ratio as a 1:N (w:h) floating point number
        if ((_currEditImage?.extent.size.height)!>CGFloat(0.0)){
            ratio = (_currEditImage?.extent.size.width)! / (_currEditImage?.extent.size.height)!
        }
        return ratio
    }
    
    /***
    public static func setEditInput(image: UIImage){
        _currEditInput = CIImage(image: image)
        _currEditSize = image.size
    }
     ***/
    
    private static func checkEditImage(){
        
        // make sure current sample image has been loaded
        if _currEditName.isEmpty {
            _currEditName = getDefaultEditImageName()!
        }
        if (_currEditImage == nil){
            let asset = getImageFromAssets(assetID:_currEditName, size:_currEditSize)
            _currEditImage = (asset != nil) ? CIImage(image: asset!) : CIImage(image: UIImage(named: defaultSampleName)!)
        }
        
        // check to see if we have already resized
        if (_currEditImageScaled == nil){
            if (_currEditSize == CGSize.zero){
                _currEditSize = (_currEditImage?.extent.size)!
            }
            //let scaledImage = resizeImage(UIImage(ciImage: _currEditImage!), targetSize: _currEditSize, mode:.scaleAspectFill)
            //_currEditImageScaled = CIImage(image:scaledImage!)
            _currEditImageScaled = _currEditImage?.resize(size: _currEditSize)
            //setEditInput(image: _currEditImageScaled!)
        }
        
    }

    
    
    // returns the default name
    public static func getDefaultEditImageName()->String?{
        
        if (_currEditName.isEmpty){
            _currEditSize = CGSize.zero // just to set it to something reasonable
            log.debug("Edit image not set")
            
            // get the most recently used photo
            _currEditName = EditList.getLatest()
            
            if (_currEditName.isEmpty){
                
                // No photo selected, so look up name of latest photo in camera roll
                getLatestPhotoName(completion: { (name: String?) in
                    if name == nil { // case where there is no photo (e.g. on simulator)
                        _currEditName = defaultSampleName
                    } else {
                        _currEditName = name!
                    }
                })
            }
            
        }
        log.debug("curr edit name: \(_currEditName)")
        return _currEditName
        
    }
    
    
    public static func getEditImageOrientation() -> CGImagePropertyOrientation {
        return _currEditImageOrientation
    }
    

    
    //////////////////////////////////
    // MARK: - Persistent Storage Utilities
    //////////////////////////////////
    
    fileprivate static func updateStoredSettings(){
        print("updateStoredSettings()")
        let settings = SettingsRecord()
        
        settings.blendImage = getCurrentBlendImageName()
        //settings.sampleImage = getCurrentSampleImageName()
        settings.editImage = getCurrentEditImageName()
        
        if (settings.editImage != nil) {
            EditList.add(settings.editImage!)
        }
        Database.saveSettings(settings)
    }

    
    
    
    //////////////////////////////////
    // MARK: - Image Utilities
    //////////////////////////////////
 
    // lists the available top-level albums. Used mostly for debug
    public static func listPhotoAlbum(_ name:String = "All Photos"){
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", name)

        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: fetchOptions)
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        fetchOptions.includeHiddenAssets = false
        
        log.debug("Smart Albums:")
        smartAlbums.enumerateObjects { (assetCollection, index, stop) in
            log.debug("[\(index)]:\(assetCollection)")
            let assets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
            
            assets.enumerateObjects{(object: AnyObject!,
                count: Int,
                stop: UnsafeMutablePointer<ObjCBool>) in
                log.debug("asset[\(count)}:\n \(object)")
            }
            
            //            if let asset = assets.firstObject {
            //                log.debug("...\(asset) ")
            //            }
        }
 /***
        let topLevelUserCollections = PHCollectionList.fetchTopLevelUserCollections(with: fetchOptions)
        log.debug("Top Level User Albums:")
        topLevelUserCollections.enumerateObjects { (assetCollection, index, stop) in
            log.debug("[\(index)]:\(assetCollection)")
        }
        smartAlbums.enumerateObjects { (assetCollection, index, stop) in
            log.debug("[\(index)]:\(assetCollection)")
            let assets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
            if let asset = assets.firstObject {
                log.debug("...\(asset)")
            }
        }
 ***/
    }
    
    
    public static func listAllAlbums(){
        let fetchOptions = PHFetchOptions()
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: fetchOptions)
        
        ////fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        fetchOptions.includeHiddenAssets = true
        
        log.debug("Smart Albums:")
        smartAlbums.enumerateObjects { (assetCollection, index, stop) in
            log.debug("[\(index)]:\(assetCollection)")
        }
        
        let topLevelUserCollections = PHCollectionList.fetchTopLevelUserCollections(with: fetchOptions)
        log.debug("Top Level User Albums:")
        topLevelUserCollections.enumerateObjects { (assetCollection, index, stop) in
            log.debug("[\(index)]:\(assetCollection)")
        }
        
     }
    
    
    // returns the name (Asset ID) of the latest photo in the Camera Roll. Useful as a default setting
    // NOTE: returns asynchronously via the 'completion(name)' callback

    public static func getLatestPhotoName(completion: (_ name: String?) -> Void){
        
        
        // TMP DBG:
        //listPhotoAlbum()
        //listAllAlbums() // tmp
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        fetchOptions.includeHiddenAssets = false
        //fetchOptions.fetchLimit = 1
        
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        let last = fetchResult.lastObject
        
        if let lastAsset = last {
            log.debug("Latest photo AssetID:\(lastAsset)")
            completion(lastAsset.localIdentifier)
        } else {
            completion(nil)
        }
    }
    

    // finds the last 'count' photo IDs 
    public static func getLatestPhotoList(count:Int, completion: (_ list: [String?]) -> Void){
        
        var photoList:[String?] = []
        
        if (count > 0) {
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.includeHiddenAssets = false
            //fetchOptions.fetchLimit = 1
            
            
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            let numFound = fetchResult.count
            if numFound > 0 {
                for i in 0...min(numFound, count){
                    let asset = fetchResult.object(at: i) as PHAsset
                    photoList.append(asset.localIdentifier)
                }
            }
        }
        completion(photoList)

    }
    

    
    // return the requested asset with the original asset size
    public static func getImageFromAssets(assetID: String)->UIImage? {
        
        let result = autoreleasepool { () -> UIImage? in
            
            var image:UIImage? = nil
            
            if isAssetID(assetID) { // Asset?
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options:nil)
                
                let asset = assets.firstObject
                if asset != nil {
                    let options = PHImageRequestOptions()
                    //        options.deliveryMode = PHImageRequestOptionsDeliveryMode.Opportunistic
                    //options.resizeMode = PHImageRequestOptionsResizeMode.fast
                    options.resizeMode = PHImageRequestOptionsResizeMode.exact
                    options.isSynchronous = true // need to set this to get the full size image
                    //options.isNetworkAccessAllowed = false
                    options.isNetworkAccessAllowed = true // needed if save to iCloud is on (Add check somewhere?)
                    //options.version = .current
                    options.version = .original
                    
                    /***/
                    let semaphore = DispatchSemaphore(value: 1)
                    PHImageManager.default().requestImageData(for: asset!, options: options, resultHandler: { data, _, _, _ in
                        image = data.flatMap { UIImage(data: $0) }
                        //data?.removeAll()
                        semaphore.signal()
                    })
                    // because we turned on network access, we need to wait for the asset to be loaded
                    semaphore.wait() // wait for image data
                    /***/
                    
                    
                    /***
                     PHImageManager.default().requestImage(for: asset!, targetSize: UIScreen.main.bounds.size, contentMode: .aspectFit, options: options,
                     resultHandler: { img, _ in
                     image = img })
                     ***/
                } else {
                    log.error("Invalid asset: \(assetID)")
                }
            } else {
                // not a managed asset (e.g. could be an image in the app bundle), load via 'regular' method
                image = UIImage(named:assetID)
            }
            
            //return image
            // OK, don't know why, but the orientation is lost when retrieving, so force it to be always up. This is how everything is displayed anyway, but it's still a hack
            if image != nil {
                var tmp = image
                image = forceUpOrientation(img: tmp!)!
                tmp = nil
                return image
            } else {
                log.error("Error loading asset: \(assetID)")
                image = nil
                return nil
            }
        }
        return result
    }
    
    
    // return the requested asset with the specified size
    public static func getImageFromAssets(assetID: String, size:CGSize)->UIImage? {
        
        let result = autoreleasepool { () -> UIImage? in
            
            var image:UIImage? = nil
            var tsize:CGSize
            
            tsize = size
            if (tsize.width < 0.01) || (tsize.height < 0.01) {
                // set to screen resolution, don't know what other size to use
                tsize = UISettings.screenResolution
                //tsize.width = UIScreen.main.bounds.size.width * UIScreen.main.scale
                //tsize.height = UIScreen.main.bounds.size.height * UIScreen.main.scale
            }
            //log.debug("tsize: \(tsize)")
            
            if isAssetID(assetID) { // Asset?
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options:nil)
                
                if let asset = assets.firstObject {
                    do {
                        //log.debug("asset: \(asset)")
                        let options = PHImageRequestOptions()
                        //        options.deliveryMode = PHImageRequestOptionsDeliveryMode.Opportunistic
                        //options.resizeMode = PHImageRequestOptionsResizeMode.exact
                        options.resizeMode = PHImageRequestOptionsResizeMode.fast
                        //options.isNetworkAccessAllowed = false
                        options.isNetworkAccessAllowed = true // needed if save to iCloud is on (Add check somewhere?)
                        options.version = .current
                        options.isSynchronous = true // need to set this to get the full size image
                        let semaphore = DispatchSemaphore(value: 2)
                        try PHImageManager.default().requestImage(for: asset, targetSize: tsize, contentMode: .aspectFit, options: options, resultHandler: { img, info in
                            if img != nil {
                                image = img
                            } else {
                                log.error("NIL image. info: \(info)")
                            }
                            semaphore.signal()
                        })
                        // because we turned on network access, we need to wait for the asset to be loaded
                         semaphore.wait() // wait for image data
                    } catch {
                        log.error("ERROR retrieveing image: \(asset)")
                    }
                } else {
                    log.error("Invalid asset: \(assetID)")
                }
            } else {
                // not a managed asset, load via 'regular' method
                var tmpimage2 = UIImage(named:assetID)
                image = resizeImage(tmpimage2, targetSize: tsize, mode:.scaleAspectFill)
                tmpimage2 = nil
            }
            
            return image
        }
        return result
    }

    
    public static func resizeImage(_ image: UIImage?, targetSize: CGSize, mode:UIView.ContentMode) -> UIImage? {
        guard (image != nil) else {
            log.error("NIL image provided for resizing")
            return nil
        }
        
        let result = autoreleasepool { () -> UIImage? in
            
            let size = (image?.size)!
            var tsize = targetSize
            if (targetSize.width<0.01) && (targetSize.height<0.01) { tsize = size }
            
            // figure out if we need to rotate the image to match the target
            let srcIsLandscape:Bool = (size.width > size.height)
            let tgtIsLandscape:Bool = (tsize.width > tsize.height)
            let tgtIsSquare:Bool =  (abs(Float(tsize.width - tsize.height)) < 0.001)
            
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
            
            return newImage
        }
        return result
    }
    
    
    
    public static func scaleImage(_ image: UIImage?, targetSize:CGSize) -> UIImage? {
        guard (image != nil) else {
            log.error("NIL image provided for scaling")
            return nil
        }
     
        let result = autoreleasepool { () -> UIImage? in
            
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
        return result
    }
    
    
    
    public static func scaleImage(_ image: UIImage?, widthRatio:CGFloat, heightRatio:CGFloat) -> UIImage? {
        guard (image != nil) else {
            log.error("NIL image provided for scaling")
            return nil
        }
        
        let result = autoreleasepool { () -> UIImage? in
            
            let size = (image?.size.applying(CGAffineTransform(scaleX: widthRatio, y: heightRatio)))!
            
            let hasAlpha = false
            let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
            
            UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
            image?.draw(in: CGRect(origin: CGPoint.zero, size: size))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            return newImage
        }
        return result
    }
    
    
    
    public static func rotateImage(_ image: UIImage?, degrees: Double) -> UIImage? {
        guard (image != nil) else {
            log.error("NIL image provided for rotation")
            return nil
        }
        
        let result = autoreleasepool { () -> UIImage? in
            
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
        return result
    }
    
    
    
    public static func cropImage(_ image:UIImage?, to:CGSize) -> UIImage? {
        guard (image != nil) else {
            log.error("NIL image provided for rotation")
            return nil
        }
        
        let result = autoreleasepool { () -> UIImage? in
            
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
        return result
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
    
    
    public static func fitIntoRect(srcSize:CGSize, targetRect: CGRect, withContentMode contentMode: UIView.ContentMode)->CGRect {
        
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
    
    public static func forceUpOrientation(img: UIImage) -> UIImage? {
        
        let result: UIImage?
        if img.imageOrientation == .up {
            result = img
        } else {
            
            result = autoreleasepool { () -> UIImage? in
                UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale)
                let rect = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
                img.draw(in: rect)
                
                let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                return normalizedImage
            }
        }
        
        return result
    }
    
    // converts from UIImage.Orientation to EXIF/CG Orientation
    static func imageOrientationToExifOrientation(value: UIImage.Orientation) -> CGImagePropertyOrientation {
/***
        switch (value) {
        case .up:
            return 1
        case .down:
            return 3
        case .left:
            return 8
        case .right:
            return 6
        case .upMirrored:
            return 2
        case .downMirrored:
            return 4
        case .leftMirrored:
            return 5
        case .rightMirrored:
            return 7
        }
 ***/
        switch (value) {
        case .up: return CGImagePropertyOrientation.up
        case .down: return CGImagePropertyOrientation.down
        case .left: return CGImagePropertyOrientation.left
        case .right: return CGImagePropertyOrientation.right
        case .upMirrored: return CGImagePropertyOrientation.upMirrored
        case .downMirrored: return CGImagePropertyOrientation.downMirrored
        case .leftMirrored: return CGImagePropertyOrientation.leftMirrored
        case .rightMirrored: return CGImagePropertyOrientation.rightMirrored
        }
    }
}
