//
//  EditFacesController.swift
//  phixer
//
//  Created by Philip Price on 12/17/18
//  Copyright © 2018 Nateemma. All rights reserved.
//

import UIKit
import Neon
import iCarousel
import Vision



private var filterList: [String] = []
private var filterCount: Int = 0

// This is a Tool controller that handles Face-specific adjustments

class EditFacesToolController: EditBaseToolController {
    
    let menu: SimpleCarousel! = SimpleCarousel()
    var editView: EditImageDisplayView! = EditImageDisplayView()
    var inputImage: CIImage? = nil
    var inputSize: CGSize = CGSize.zero
    
    //var overlayView: UIView! = UIView()
    var shapeLayer:CAShapeLayer! = nil
    var maskView: UIImageView! = UIImageView() // this is for debugging the masking operations
    var maskShapeLayer:CAShapeLayer! = nil
    var pathView: PathMaskView! = PathMaskView()
    
    let maskBackground = UIColor.black
    let maskForeground = UIColor.white
    
    var faceList: [FacialFeatures] = []
    var currFaceIndex: Int = -1
    
    var filterChain: FilterChain! = FilterChain()
    
    //////////////////////////////////////////
    // MARK: - Init
    //////////////////////////////////////////
    
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
    }
    
    
    //////////////////////////////////////////
    // MARK: - Override funcs for specifying items
    //////////////////////////////////////////
    
    // Since we have a menu of options, next/previous make sense here
    override func nextItem() {
        DispatchQueue.main.async(execute: { () -> Void in
            log.debug("next...")
            self.menu.nextItem()
        })
    }
    
    override func previousItem() {
        DispatchQueue.main.async(execute: { () -> Void in
            log.debug("previous...")
            self.menu.previousItem()
        })
    }
    
    
    // returns the text to display at the top of the window
    override func getTitle() -> String {
        return "Facial Adjustments"
    }
    
    // specify full screen
    override func getToolType() -> ControllerType {
        return .fulltool
    }
    
    // this is called by the Controller base class to build the tool-speciifc display
    override func loadToolView(toolview: UIView){
        buildView(toolview)
    }
    
    
    override func filterReset(){
        log.verbose("Ignoring...")
        // should probably do something here
    }
    
    
    override func end() {
        log.verbose("Restoring navbar")
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        dismiss()
    }
    
    //////////////////////////////////////////
    // MARK: - Main View Layout
    //////////////////////////////////////////
    
    private func buildView(_ view: UIView){
        
        // hide the navbar
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        toolView.backgroundColor = theme.backgroundColor
        
        // Edit view automatically loads te current edit image
        editView.frame.size = toolView.frame.size
        toolView.addSubview(editView)
        editView.fillSuperview()
        
        toolView.addSubview(maskView)
        maskView.fillSuperview()
        
        maskView.backgroundColor = maskBackground // set explicitly for masking (i.e. don't use theme colour)
        maskView.isHidden = true
        
        maskShapeLayer = CAShapeLayer()
        maskShapeLayer.strokeColor = maskForeground.cgColor
        maskShapeLayer.fillColor = maskForeground.cgColor
        maskShapeLayer.fillRule = CAShapeLayerFillRule.nonZero // we want all paths to be filled, whether or not they overlap
        maskShapeLayer.lineWidth = 1.0
        maskShapeLayer.lineJoin = CAShapeLayerLineJoin.round
        maskShapeLayer.lineCap = CAShapeLayerLineCap.round
        
        //maskView.layer.addSublayer(maskShapeLayer)
        
        toolView.layer.addSublayer(maskShapeLayer)
        maskShapeLayer.fillSuperview()
        
        toolView.addSubview(pathView)
        pathView.fillSuperview()
        
        //        DispatchQueue.main.async {
        //            self.testMask()
        //            //self.test2()
        //        }
        
        
        setupMenu()
        
        inputImage = EditManager.getPreviewImage()
        inputSize = EditManager.getImageSize()
        let orientation = InputSource.getOrientation()
        
        editView.setNeedsDisplay()
        
        DispatchQueue.main.async {
            
            // set up shape layer within async block so that editView has some time to get set up
            self.shapeLayer = self.editView.getShapeLayer()
            //shapeLayer = nil
            if self.shapeLayer == nil {
                log.error("NIL Shape Layer")
                self.shapeLayer = CAShapeLayer()
                self.toolView.layer.addSublayer(self.shapeLayer)
                self.shapeLayer.fillSuperview()
            }
            self.shapeLayer.strokeColor = self.theme.highlightColor.cgColor
            self.shapeLayer.lineWidth = 1.0
            
            self.detectFaces(on: self.inputImage!, orientation: orientation)
        }
        
    }
    
    //////////////////////////////////////////
    // MARK: - Menu setup & handling
    //////////////////////////////////////////
    
    func setupMenu(){
        // set up the menu of option
        menu.frame.size.height = UISettings.menuHeight
        menu.frame.size.width = toolView.frame.size.width
        menu.backgroundColor = theme.backgroundColor
        menu.setItems(getItemList())
        menu.delegate = self
        
        toolView.addSubview(menu)
        menu.anchorToEdge(.bottom, padding: 0, width: menu.frame.size.width, height: menu.frame.size.height)
        //        log.verbose("menu: w:\(menu.frame.size.width) h:\(menu.frame.size.height)")
        
    }
    
    // Adornment list
    fileprivate var itemList: [Adornment] = [ Adornment(key: "lips",       text: "Lips",          icon: "ic_lips", view: nil, isHidden: false),
                                              Adornment(key: "skin",       text: "Skin",          icon: "ic_acne", view: nil, isHidden: false),
                                              Adornment(key: "teeth",      text: "Teeth",         icon: "ic_smile", view: nil, isHidden: false),
                                              Adornment(key: "eyes",       text: "Eyes",          icon: "ic_eye", view: nil, isHidden: false),
                                              Adornment(key: "eyebrows",   text: "Eyebrows",      icon: "ic_eyebrow", view: nil, isHidden: false),
                                              Adornment(key: "select",     text: "Select Face",   icon: "ic_face_select", view: nil, isHidden: false),
                                              Adornment(key: "auto",       text: "Auto Adjust",   icon: "ic_magic", view: nil, isHidden: false) ]
    
    // returns the list of titles for each item
    func getItemList() -> [Adornment] {
        return itemList
    }
    
    // handler for selected adornments:
    func handleSelection(key:String){
        if faceList.count > 0 {
            DispatchQueue.main.async {
                self.clearMask()
                self.hideMask()
                self.maskShapeLayer.fillRule = CAShapeLayerFillRule.nonZero // by default, we want all paths to be filled, whether or not they overlap
                switch (key){
                case "lips": self.lipsHandler()
                case "skin": self.skinHandler()
                case "teeth": self.teethHandler()
                case "eyes": self.eyesHandler()
                case "eyebrows": self.eyebrowsHandler()
                case "select": self.selectHandler()
                case "auto": self.autoHandler()
                default:
                    log.error("Unknown key: \(key)")
                }
                
                self.editView.updateImage()
            }
        } else {
            log.warning("No faces detected. Ignoring request: \(key)")
        }
    }
    
    func lipsHandler(){

        if faceList.count > 0 {
            // generate a mask
            var fullpath: UIBezierPath! = UIBezierPath()
            for face in faceList {
                fullpath.append(createCGPath(points: face.outerLips))
                fullpath.append(createCGPath(points: face.innerLips))
            }
            
            // increase saturation and sharpen
            let adjustedImg = inputImage?
                .applyingFilter("CIVibrance", parameters: ["inputAmount": 0.6])
                //.applyingFilter("SaturationFilter", parameters: ["inputSaturation": 1.0])
                .applyingFilter("ClarityFilter", parameters: ["inputClarity": 0.5])
                .applyingFilter("CISharpenLuminance", parameters: ["inputRadius": 1.6, "inputSharpness": 0.4])
            guard adjustedImg != nil else {
                log.error("NIL adjustedImg")
                return
            }
            
            let mpath = fullpath.cgPath as! CGMutablePath
            let mask = createmask(cgpath: mpath, size: self.inputSize)
            guard mask != nil else {
                log.error("NIL Mask")
                return
            }
            
            // blend the original and the adjusted version using the mask
            let maskedImg =  adjustedImg?
                .applyingFilter("CIBlendWithMask", parameters: [kCIInputMaskImageKey: mask!, kCIInputBackgroundImageKey:inputImage!])
            
            self.maskView.image = UIImage(ciImage: maskedImg!) // tmp dbg
            
            showMask() // tmp dbg
        }
    }
    
    func skinHandler(){
        // funky interface so set defaults
        let descriptor = filterManager.getFilterDescriptor(key: "MaskedSkinSmoothingFilter")
        if descriptor != nil {
            descriptor?.reset()
            descriptor?.setParameter("inputAmount", value: 1.0)
            descriptor?.setParameter("inputRadius", value: 16.0)
            EditManager.addPreviewFilter(descriptor)
        } else {
            log.error("Error creating skin filter")
        }
    }
    
    func teethHandler(){
        
        guard inputImage != nil else {
            log.error("NIL inputImage")
            return
        }

        if faceList.count > 0 {
            clearMask()
            hideMask()
            self.maskView.isHidden = false
            
            // generate a mask of the teeth
            //var paths: [UIBezierPath] = []
            var fullpath: UIBezierPath! = UIBezierPath()
            for face in faceList {
                //                paths.append(createPath(points: face.innerLips))
                fullpath.append(createCGPath(points: face.innerLips))
            }
            
            
            // de-saturate yellow, brighten the teeth
            let yVector = CIVector(x: 0.0, y: 0.1, z: 1.0) // set saturation to low value (but not 0.0)
            let adjustedImg = inputImage?
                .applyingFilter("MultiBandHSV", parameters: ["inputYellowShift": yVector, "inputOrangeShift": yVector])
                //.applyingFilter("CIExposureAdjust", parameters: ["inputEV": 0.3]) // tmp  value for debug
                .applyingFilter("BrightnessFilter", parameters: ["inputBrightness": 0.01]) // tmp  value for debug
            
            // create a mask
            //            let mask = createMask(from: paths, size: self.toolView.frame.size)
            //            let teethMask = CIImage(image: mask!)?
            //                .applyingFilter("CIPhotoEffectMono") // mask must be greyscale
            //                .resize(size: inputSize)
            
            let mpath = fullpath.cgPath as! CGMutablePath
            let mask = createmask(cgpath: mpath, size: self.inputSize)
            guard mask != nil else {
                log.error("NIL Mask")
                return
            }
            
            let teethMask = mask //?
                //.applyingFilter("CIPhotoEffectMono") // mask must be greyscale
                //.resize(size: inputSize)
            guard teethMask != nil else {
                log.error("NIL teethMask")
                return
            }

            // TODO: figure out transform to take orientation into account
            
            // blend the original and the adjusted version using the mask
            let maskedImg =  adjustedImg?
                .applyingFilter("CIBlendWithMask", parameters: [kCIInputMaskImageKey: teethMask!, kCIInputBackgroundImageKey:inputImage!])
            
            self.maskView.image = UIImage(ciImage: maskedImg!) // tmp dbg
        }
    }
    
    
    func eyesHandler(){

        if faceList.count > 0 {
            // generate a mask
            var fullpath: UIBezierPath! = UIBezierPath()
            for face in faceList {
                fullpath.append(createCGPath(points: face.leftEye))
                fullpath.append(createCGPath(points: face.rightEye))
            }
 
            // de-saturate red, brighten, increase vibrance and sharpen
            let yVector = CIVector(x: 0.0, y: 0.1, z: 1.0) // set saturation to low value (but not 0.0)
            let adjustedImg = inputImage?
                .applyingFilter("MultiBandHSV", parameters: ["inputRedShift": yVector])
                //.applyingFilter("CIExposureAdjust", parameters: ["inputEV": 0.3])
                .applyingFilter("BrightnessFilter", parameters: ["inputBrightness": 0.01])
                .applyingFilter("CIVibrance", parameters: ["inputAmount": 0.6])
                .applyingFilter("ClarityFilter", parameters: ["inputClarity": 0.5])
                .applyingFilter("CISharpenLuminance", parameters: ["inputRadius": 1.6, "inputSharpness": 0.4])

            
            let mpath = fullpath.cgPath as! CGMutablePath
            let mask = createmask(cgpath: mpath, size: self.inputSize)
            guard mask != nil else {
                log.error("NIL Mask")
                return
            }
            
            // blend the original and the adjusted version using the mask
            let maskedImg =  adjustedImg?
                .applyingFilter("CIBlendWithMask", parameters: [kCIInputMaskImageKey: mask!, kCIInputBackgroundImageKey:inputImage!])
            
            self.maskView.image = UIImage(ciImage: maskedImg!) // tmp dbg

            showMask() // tmp dbg
        }
        
    }
    
    func autoHandler(){
        let descriptor = filterManager.getFilterDescriptor(key: "AutoAdjustFilter")
        
        // TODO: figure out how to add a bunch of filters as a group, then run all of the filters along with AutoAdjust
        if descriptor != nil {
            EditManager.addPreviewFilter(descriptor)
        }
        //skinHandler()
    }
    
    func eyebrowsHandler(){

        if faceList.count > 0 {
            // generate a mask
            var fullpath: UIBezierPath! = UIBezierPath()
            for face in faceList {
                fullpath.append(createCGPath(points: face.leftEyebrow))
                fullpath.append(createCGPath(points: face.rightEyebrow))
            }
            
            // add some clarity and sharpen
            let adjustedImg = inputImage?
                .applyingFilter("ClarityFilter", parameters: ["inputClarity": 0.5])
                .applyingFilter("CISharpenLuminance", parameters: ["inputRadius": 1.6, "inputSharpness": 0.4])
            
            
            let mpath = fullpath.cgPath as! CGMutablePath
            let mask = createmask(cgpath: mpath, size: self.inputSize)
            guard mask != nil else {
                log.error("NIL Mask")
                return
            }
            
            // blend the original and the adjusted version using the mask
            let maskedImg =  adjustedImg?
                .applyingFilter("CIBlendWithMask", parameters: [kCIInputMaskImageKey: mask!, kCIInputBackgroundImageKey:inputImage!])
            
            self.maskView.image = UIImage(ciImage: maskedImg!) // tmp dbg
            
            showMask() // tmp dbg
        }
    }
    
    func selectHandler(){
        self.selectNextFace()
    }
    
    
    // debug:
    private func showMask(){
        self.maskView.isHidden = false
        self.editView.isHidden = true
        self.maskShapeLayer.isHidden = false
    }
    
    private func hideMask(){
        self.maskView.isHidden = true
        self.editView.isHidden = false
        self.maskShapeLayer.isHidden = true
    }
    
    private func clearMask() {
        self.pathView.clear()
        self.maskShapeLayer.sublayers?.removeAll()
    }
    
    //////////////////////////////////////////
    // MARK: - Face Detection
    //////////////////////////////////////////
    
    
    
    var faceDetection = VNDetectFaceRectanglesRequest()
    var faceLandmarks = VNDetectFaceLandmarksRequest()
    var faceLandmarksDetectionRequest = VNSequenceRequestHandler()
    var faceDetectionHandler = VNSequenceRequestHandler()
    
    
    
    private func drawOutline(_ rect: CGRect) {
        let faceBox = UIView(frame: rect)
        
        log.verbose("drawing: \(rect)")
        faceBox.layer.borderWidth = 3
        faceBox.layer.borderColor = theme.highlightColor.cgColor
        faceBox.backgroundColor = UIColor.clear
        //overlayView.addSubview(faceBox)
        //shapeLayer.addSubview(faceBox)
    }
    
    
    func detectFaces(on image: CIImage, orientation: CGImagePropertyOrientation) {
        self.faceList = []
        self.currFaceIndex = -1
        
        try? faceDetectionHandler.perform([faceDetection], on: image, orientation: orientation)
        if let results = faceDetection.results as? [VNFaceObservation] {
            if !results.isEmpty {
                log.verbose("Found \(results.count) faces. Orientation:\(orientation)")
                faceLandmarks.inputFaceObservations = results
                detectLandmarks(on: image, orientation: orientation)
                
                DispatchQueue.main.async {
                    self.shapeLayer.sublayers?.removeAll()
                }
            }
        }
    }
    
    
    func detectLandmarks(on image: CIImage, orientation: CGImagePropertyOrientation) {
        try? faceLandmarksDetectionRequest.perform([faceLandmarks], on: image, orientation: orientation)
        if let landmarksResults = faceLandmarks.results as? [VNFaceObservation] {
            //for observation in landmarksResults {
            DispatchQueue.main.async {
                for i in 0..<landmarksResults.count {
                    let observation = landmarksResults[i]
                    
                    //if let boundingBox = self.faceLandmarks.inputFaceObservations?.first?.boundingBox {
                    //if let boundingBox = observation.boundingBox {
                    //let faceBoundingBox = boundingBox.scaled(to: self.toolView.frame.size)
                    if let faceBoundingBox = self.faceLandmarks.inputFaceObservations?[i].boundingBox.scaled(to: image.extent.size) {
                        let face = FacialFeatures()
                        face.faceBounds = faceBoundingBox
                        
                        // convert all of the different types of landmarks
                        face.faceContour = self.convertFaceLandmark(observation.landmarks?.faceContour, faceBoundingBox)
                        face.leftEye = self.convertFaceLandmark(observation.landmarks?.leftEye, faceBoundingBox)
                        face.rightEye = self.convertFaceLandmark(observation.landmarks?.rightEye, faceBoundingBox)
                        face.leftEyebrow = self.convertFaceLandmark(observation.landmarks?.leftEyebrow, faceBoundingBox)
                        face.rightEyebrow = self.convertFaceLandmark(observation.landmarks?.rightEyebrow, faceBoundingBox)
                        face.nose = self.convertFaceLandmark(observation.landmarks?.nose, faceBoundingBox)
                        face.noseCrest = self.convertFaceLandmark(observation.landmarks?.noseCrest, faceBoundingBox)
                        face.medianLine = self.convertFaceLandmark(observation.landmarks?.medianLine, faceBoundingBox)
                        face.outerLips = self.convertFaceLandmark(observation.landmarks?.outerLips, faceBoundingBox)
                        face.innerLips = self.convertFaceLandmark(observation.landmarks?.innerLips, faceBoundingBox)
                        face.leftPupil = self.convertFaceLandmark(observation.landmarks?.leftPupil, faceBoundingBox)
                        face.rightPupil = self.convertFaceLandmark(observation.landmarks?.rightPupil, faceBoundingBox)
                        
                        if face.faceContour.count >= 2 {
                            let n = face.faceContour.count - 1
                            let x = face.faceContour[0].x + 0.5*(face.faceContour[n].x - face.faceContour[0].x)
                            let y = face.faceContour[0].y + 0.5*(face.faceContour[n].y - face.faceContour[0].y)
                            let skinpos = CGPoint(x: x, y: y)
                            face.skinColor = CIColor(cgColor: (image.cgImage?.getColor(x: Int(skinpos.x), y: Int(skinpos.y)))!)
                            log.verbose("Skin Color: \(face.skinColor)")
                        }
                        self.faceList.append(face)
                    }
                    // }
                }
                DispatchQueue.main.async {
                    //self.drawAllFaces()
                    self.drawBoundingBoxes()
                }
            }
        }
        
        
    }
    
    // convert landmarks into CGPoint arrays
    func convertFaceLandmark(_ landmark: VNFaceLandmarkRegion2D?, _ boundingBox: CGRect) -> [CGPoint] {
        
        var faceLandmarkPoints: [CGPoint] = []
        if let points = landmark?.normalizedPoints, let count = landmark?.pointCount {
            
            if count > 0 {
                for point in points {
                    let pointX = point.x * boundingBox.width + boundingBox.origin.x
                    let pointY = point.y * boundingBox.height + boundingBox.origin.y
                    let point = CGPoint(x: pointX, y: pointY)
                    faceLandmarkPoints.append(point)
                    //                    if !(boundingBox.contains(point)){
                    //                        log.error("Point [\(pointX),\(pointY)] not in rect:\(boundingBox)")
                    //                    }
                    //log.verbose("norm:[\(point.x),\(point.y)] => CG:[\(pointX),\(pointY)]")
                }
                
            } else {
                log.warning("No landmarks returned")
            }
        }
        return faceLandmarkPoints
    }
    
    
    // draw al of the available faces
    func drawAllFaces() {
        if faceList.count > 0 {
            for face in faceList {
                self.drawFace(face)
            }
        } else {
            log.verbose("No faces found")
        }
    }
    
    
    // draw just the bounding boxes
    func drawBoundingBoxes() {
        if faceList.count > 0 {
            for face in faceList {
                var box: [CGPoint] = []
                let w = face.faceBounds.size.width
                let h = face.faceBounds.size.height
                box.append(CGPoint(x: face.faceBounds.origin.x, y: face.faceBounds.origin.y))
                box.append(CGPoint(x: face.faceBounds.origin.x, y: face.faceBounds.origin.y + h))
                box.append(CGPoint(x: face.faceBounds.origin.x + w, y: face.faceBounds.origin.y + h))
                box.append(CGPoint(x: face.faceBounds.origin.x + w, y: face.faceBounds.origin.y))
                self.draw(points: box)
            }
        } else {
            log.verbose("No faces found")
        }
    }
    
    // draw all of the facial data
    func drawFace(_ face: FacialFeatures){
        
        DispatchQueue.main.async {
            // convert rect to list of points
            var box: [CGPoint] = []
            let w = face.faceBounds.size.width
            let h = face.faceBounds.size.height
            box.append(CGPoint(x: face.faceBounds.origin.x, y: face.faceBounds.origin.y))
            box.append(CGPoint(x: face.faceBounds.origin.x, y: face.faceBounds.origin.y + h))
            box.append(CGPoint(x: face.faceBounds.origin.x + w, y: face.faceBounds.origin.y + h))
            box.append(CGPoint(x: face.faceBounds.origin.x + w, y: face.faceBounds.origin.y))
            
            self.draw(points: box)
            self.draw(points: face.faceContour)
            self.draw(points: face.leftEye)
            self.draw(points: face.rightEye)
            self.draw(points: face.leftEyebrow)
            self.draw(points: face.rightEyebrow)
            self.draw(points: face.nose)
            self.draw(points: face.noseCrest)
            self.draw(points: face.medianLine)
            self.draw(points: face.outerLips)
            self.draw(points: face.innerLips)
            self.draw(points: face.leftPupil)
            self.draw(points: face.rightPupil)
            
        }
        
    }
    
    func selectNextFace() {
        if faceList.count > 0 {
            currFaceIndex = (currFaceIndex < (faceList.count-1)) ? (currFaceIndex + 1) : 0
            zoomToFace(currFaceIndex)
        }
    }
    
    func zoomToFace(_ index: Int) {
        var idx: Int = index
        if (idx<0) || (idx>=faceList.count) {
            idx = 0
        }
        let irect = faceList[idx].faceBounds.scaled(to: CGSize(width: 1.5, height: 1.5))
        let vrect = cgToViewRect(irect)
        log.verbose("Zooming to: \(vrect)")
        self.editView.zoom(to: vrect)
    }
    
    
    ///////////////////////////
    // MARK: - Masking
    ///////////////////////////
    
    // masking proving to be tricky. Testing out approaches here:
    private func testMask() {
        
        // create a test shape
        let imgsize = EditManager.getImageSize()
        let cx:CGFloat = toolView.frame.size.width/2.0
        let cy:CGFloat = toolView.frame.size.height/2.0
        let w: CGFloat = 32.0
        let square = [CGPoint(x: cx-w, y: cy-w), CGPoint(x: cx+w, y: cy-w), CGPoint(x: cx+w, y: cy+w), CGPoint(x: cx-w, y: cy+w)]
        
        maskView.isHidden = false
        self.maskShapeLayer.sublayers?.removeAll()
        
        
        // create the corresponding Bezier path
        let path = UIBezierPath()
        //let start = cgToViewPoint(square[0])
        let start = square[0]
        path.move(to: start)
        for i in 1..<square.count {
            //let point = cgToViewPoint(square[i])
            let point = square[i]
            path.addLine(to: point)
            path.move(to: point)
        }
        path.addLine(to: start)
        path.close()
        
        maskShapeLayer.path = path.cgPath
        toolView.setNeedsDisplay()
        
    }
    
    private func test2(){
        let path = self.createRectangle()
        
        let shapeLayer = CAShapeLayer()
        
        shapeLayer.path = path.cgPath
        
        UIColor.orange.setFill()
        path.fill()
        
        toolView.layer.addSublayer(shapeLayer)
        shapeLayer.fillSuperview()
    }
    
    private func testMask3(){
        
        // clear existing paths
        pathView.clear()
        
        // create a test shape
        _ = EditManager.getImageSize()
        let cx:CGFloat = toolView.frame.size.width/2.0
        let cy:CGFloat = toolView.frame.size.height/2.0
        let w: CGFloat = 32.0
        let square = [CGPoint(x: cx-w, y: cy-w), CGPoint(x: cx+w, y: cy-w), CGPoint(x: cx+w, y: cy+w), CGPoint(x: cx-w, y: cy+w)]
        
        // create the corresponding Bezier path
        let path = UIBezierPath()
        /***
         //let start = cgToViewPoint(square[0])
         let start = square[0]
         path.move(to: start)
         for i in 1..<square.count {
         //let point = cgToViewPoint(square[i])
         let point = square[i]
         path.addLine(to: point)
         path.move(to: point)
         }
         path.addLine(to: start)
         ***/
        path.interpolatePointsWithHermite(interpolationPoints: square)
        path.close()
        
        pathView.addPath(path)
        pathView.setNeedsDisplay()
    }
    
    private func createRectangle() -> UIBezierPath {
        // Initialize the path.
        let path = UIBezierPath()
        
        // Specify the point that the path should start get drawn.
        path.move(to: CGPoint(x: 0.0, y: 0.0))
        
        // Create a line between the starting point and the bottom-left side of the view.
        path.addLine(to: CGPoint(x: 0.0, y: toolView.frame.size.height))
        
        // Create the bottom line (bottom-left to bottom-right).
        path.addLine(to: CGPoint(x: toolView.frame.size.width, y: toolView.frame.size.height))
        
        // Create the vertical line from the bottom-right to the top-right side.
        path.addLine(to: CGPoint(x: toolView.frame.size.width, y: 0.0))
        
        // Close the path. This will create the last line automatically.
        path.close()
        
        return path
    }
    
    
    // crate a mask image
    private func createMask(from paths: [UIBezierPath], size: CGSize) -> UIImage? {
        guard paths.count > 0 else {
            log.error("No paths supplied")
            return nil
        }
        
        self.maskShapeLayer.sublayers?.removeAll()
        self.maskShapeLayer.backgroundColor = maskBackground.cgColor
        self.maskShapeLayer.strokeColor = maskForeground.cgColor
        self.maskShapeLayer.fillColor = maskForeground.cgColor

        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.setFillColor(maskForeground.cgColor)
        context?.setStrokeColor(maskForeground.cgColor)

        for path in paths {
            let newLayer = CAShapeLayer()
            newLayer.backgroundColor = maskBackground.cgColor
            newLayer.strokeColor = maskForeground.cgColor
            newLayer.fillColor = maskForeground.cgColor
            //newLayer.lineWidth = 1.0
            
            path.close()
            path.stroke()
            path.fill()
            //log.verbose("path: \(path)")
            context?.addPath(path.cgPath)
            newLayer.path = path.cgPath
            maskShapeLayer.addSublayer(newLayer)
        }
        context?.drawPath(using: .eoFill)
        //context?.drawPath(using: .fill)
        
        maskShapeLayer.render(in: context!)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        
//        let renderer = UIGraphicsImageRenderer(size: size)
//        let image = renderer.image { ctx in
//            ctx.cgContext.setFillColor(self.maskForeground.cgColor)
//            ctx.cgContext.setStrokeColor(self.maskForeground.cgColor)
//            return maskShapeLayer.render(in: ctx.cgContext)
//        }
        
        UIGraphicsEndImageContext()

        return image
    }
    
    // alternate func to create a mask from a CGPath and return the corresponding CIImage. This version is intended for use in filters eventually (i.e. no use of UIKit)
    private func createmask(cgpath: CGMutablePath, size: CGSize) -> CIImage? {
        
        var img:CIImage? = nil
        
        let colorspace = CGColorSpaceCreateDeviceRGB()
        let bitmapinfo =  CGImageAlphaInfo.premultipliedLast.rawValue
        
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
        
        // don't need high quality here
        context?.interpolationQuality = .low
        

//        let black = CGColor(colorSpace: colorspace, components: [0, 0, 0, 1])
//        guard (black != nil) else {
//            log.error("Could not create black")
//            return nil
//        }

        let white = CGColor(colorSpace: colorspace, components: [1, 1, 1, 1])
        guard (white != nil) else {
            log.error("Could not create white")
            return nil
        }
        
        context?.setFillColor(white!)
        context?.addPath(cgpath)
        context?.fillPath()
        
        // create the CGImage
        let cgImage = context?.makeImage()
        
        guard cgImage != nil else {
            log.error("Could not create CGImage")
            return nil
        }
        
        img = CIImage(cgImage: cgImage!)
        
        log.verbose("image size: \(img?.extent.size)\n Path:\(cgpath)")
        return img
    }


    // mask the input image withe supplied mask image
    private func maskedImage(image: CGImage?, mask: CGImage?) -> CGImage? {
        guard (image != nil), (mask != nil) else {
            log.error("NIL input image(s)")
            return image
        }
        
        //let imageMask = image?.masking(mask!)
        
        /***/
        let imageMask = CGImage(maskWidth: (mask?.width)!,
                                height: (mask?.height)!,
                                bitsPerComponent: (mask?.bitsPerComponent)!,
                                bitsPerPixel: (mask?.bitsPerPixel)!,
                                bytesPerRow: (mask?.bytesPerRow)!,
                                provider: (mask?.dataProvider)!, decode: nil, shouldInterpolate: true)
        /***/

        if imageMask != nil {
            return image?.masking(imageMask!)
        } else {
            log.error("Error masking image")
            return image
        }
    }
    
    ///////////////////////////
    // MARK: - Utilities
    ///////////////////////////
    
    // create a Bezier path from an array of (image) points. Bezier path is in View coordinates 
    func createPath(points: [CGPoint]) -> UIBezierPath {
        let path = UIBezierPath()
        var vpoints:[CGPoint] = []
        /***
         let start = cgToViewPoint(points[0])
         path.move(to: start)
         for i in 1..<points.count {
         let point = cgToViewPoint(points[i])
         path.addLine(to: point)
         path.move(to: point)
         }
         path.addLine(to: start)
         ***/
        // convert to view coordinates
        let start = cgToViewPoint(points[0])
        vpoints.append(start)
        for i in 1..<points.count {
            vpoints.append(cgToViewPoint(points[i]))
        }
        vpoints.append(start)
        
        // smooth the curve
        path.interpolatePointsWithHermite(interpolationPoints: vpoints) // create a smooth curve from the points
        
        // close the path and return it
        path.close()
        return path
    }
    
    // create a CG path from an array of (image) points. In (CG) image coordinates, not UI coordinates
    func createCGPath(points: [CGPoint]) -> UIBezierPath {
        let path = UIBezierPath()
        var vpoints:[CGPoint] = []

        let start = points[0]
        vpoints.append(start)
        for i in 1..<points.count {
            vpoints.append(points[i])
        }
        vpoints.append(start)
        
        // smooth the curve
        path.interpolatePointsWithHermite(interpolationPoints: vpoints) // create a smooth curve from the points
        
        // close the path and return it
        path.close()

        return path
    }

    // draw the points. Note that we convert from CG- to UI-based points here
    func draw(points: [CGPoint]) {
        if points.count > 0 {
            let newLayer = CAShapeLayer()
            newLayer.strokeColor = theme.highlightColor.cgColor
            newLayer.lineWidth = 1.0
            
            let path = UIBezierPath()
            let start = cgToViewPoint(points[0])
            path.move(to: start)
            for i in 1..<points.count {
                let point = cgToViewPoint(points[i])
                path.addLine(to: point)
                path.move(to: point)
            }
            path.addLine(to: start)
            path.close()
            newLayer.path = path.cgPath
            
            shapeLayer.addSublayer(newLayer)
        }
    }
    
    // convert normalised, CG-based rect to view-based rect. It is assumed that the normalised rect is specified relative to the supplied view
    private func normalToViewRect(_ rect: CGRect, size: CGSize) -> CGRect {
        let vrect = rect
            .scaled(to: size)
            .applying(CGAffineTransform(scaleX: 1.0, y: -1.0))
            .applying(CGAffineTransform(translationX: 0, y: size.height))
        return vrect
    }
    
    private func cgToViewRect(_ rect: CGRect) -> CGRect {
        var vrect: CGRect = CGRect.zero
        
        vrect.origin = self.editView.getViewPosition(imagePos: rect.origin)
        
        let topright = CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height)
        let vtopright = self.editView.getViewPosition(imagePos: topright)
        vrect.size.width = vtopright.x - vrect.origin.x
        vrect.size.height = abs(vtopright.y - vrect.origin.y)
        vrect.origin.y -= vrect.size.height
        
        return vrect
    }
    
    
    // convert normalised, CG-based point to view-based point. It is assumed that the normalised point is specified relative to the supplied view
    private func normalToViewPoint(_ point: CGPoint, view: UIView) -> CGPoint {
        let pointX = point.x * view.frame.size.width + view.frame.origin.x
        let pointY = point.y * view.frame.size.height + view.frame.origin.y
        
        let vpoint = CGPoint(x: pointX, y: view.frame.size.height - pointY)
        return vpoint
    }
    
    
    // convert CG-based point coordinate to UI-based coordinate for specified view
    // It is assumed that the CG-based point has already been appropriately scaled (i.e. is not in image-based coordinates)
    private func cgToViewPoint(_ point: CGPoint) -> CGPoint {
        //return CGPoint(x: point.x, y: view.frame.size.height - point.y)
        return self.editView.getViewPosition(imagePos: point)
    }
    
} // EditFacesController
//########################



extension EditFacesToolController: AdornmentDelegate {
    func adornmentItemSelected(key: String) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.handleSelection(key: key)
        })
    }
}

extension UIImage {
    func imageFromPaths(paths: [UIBezierPath]) -> UIImage! {
        let frame = CGRect(origin: CGPoint.zero, size: self.size)
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        for path in paths {
            path.addClip()
        }
        self.draw(in: frame)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        context?.restoreGState()
        UIGraphicsEndImageContext()
        return newImage
    }
}
