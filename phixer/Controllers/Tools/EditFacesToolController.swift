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
    //var overlayView: UIView! = UIView()
    let shapeLayer = CAShapeLayer()
    
    var faceList: [FacialFeatures] = []
    
    
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
        
        // overlay view for displaying feature outlines
//        overlayView.backgroundColor = UIColor.clear
//        toolView.addSubview(overlayView)
//        overlayView.fillSuperview()
//        overlayView.isUserInteractionEnabled = false
        
        
        shapeLayer.strokeColor = theme.highlightColor.cgColor
        shapeLayer.lineWidth = 2.0
 
        toolView.layer.addSublayer(shapeLayer)
        shapeLayer.fillSuperview()
        
        setupMenu()
        
        let image = EditManager.getPreviewImage()
        let orientation = InputSource.getOrientation()

        DispatchQueue.main.async {
            self.detectFaces(on: image!, orientation: orientation)
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
    fileprivate var itemList: [Adornment] = [ Adornment(key: "redeye",     text: "Fix Redeye"),
                                              Adornment(key: "smoothskin", text: "Smooth Skin"),
                                              Adornment(key: "teeth",      text: "Whiten Teeth"),
                                              Adornment(key: "brighteyes", text: "Brighten Eyes"),
                                              Adornment(key: "auto",       text: "Auto Adjust") ]

    // returns the list of titles for each item
    func getItemList() -> [Adornment] {
        return itemList
    }

    // handler for selected adornments:
    func handleSelection(key:String){
        switch (key){
        case "redeye": redeyeHandler()
        case "smoothskin": smoothskinHandler()
        case "teeth": teethHandler()
        case "brighteyes": brighteyesHandler()
        case "auto": autoHandler()
        default:
            log.error("Unknown key: \(key)")
        }
    }

    func redeyeHandler(){
        self.coordinator?.selectFilterNotification(key: "CIRedEyeCorrection")
    }
    
    func smoothskinHandler(){
        // funky interface so set defaults
        let descriptor = filterManager.getFilterDescriptor(key: "SkinSmoothingFilter")
        descriptor?.reset()
        self.coordinator?.selectFilterNotification(key: "SkinSmoothingFilter")
    }
    
    func teethHandler(){
        //self.coordinator?.selectFilterNotification(key: "BrightnessFilter")
    }
    
    func brighteyesHandler(){
        //self.coordinator?.selectFilterNotification(key: "ContrastFilter")
    }
    
    func autoHandler(){
        self.coordinator?.selectFilterNotification(key: "AutoAdjustFilter")
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
                        face.allPoints = self.convertFaceLandmark(observation.landmarks?.allPoints, faceBoundingBox)
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
                        
                        self.faceList.append(face)
                    }
                    // }
                }
                DispatchQueue.main.async {
                    self.drawAllFaces()
                    //self.drawBoundingBoxes()
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
                    if !(boundingBox.contains(point)){
                        log.error("Point [\(pointX),\(pointY)] not in rect:\(boundingBox)")
                    }
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
            //self.draw(points: face.allPoints)
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
    
    // draw the points. Note that we convert from CG- to UI-based points here
    func draw(points: [CGPoint]) {
        if points.count > 0 {
            let newLayer = CAShapeLayer()
            newLayer.strokeColor = theme.highlightColor.cgColor
            newLayer.lineWidth = 2.0
            
            let path = UIBezierPath()
            let start = cgToViewPoint(points[0])
            path.move(to: start)
            for i in 0..<points.count {
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
