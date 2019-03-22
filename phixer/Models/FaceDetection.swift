//
//  FaceDetection.swift
//  phixer
//
//  Created by Philip Price on 3/19/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import Vision

// This is a class that encapsulates the main Face Detection logic.
// It is intended for use in Filter classes but can be used elsewhere, but be aware that all coordinates are in CG Image format

// Usage:
// - call reset() for a new image
// - call detectFaces() with the image to be processed
// - call getFeatures() to get the list of detected features
// - select the features you want to use
// - create a path (or compound path) from the selected features
// - call createMask() to convert the path into a mask
// - run the desired operation(s) on the input image
// - call maskImage() to mask out the feature areas and overlay onto the source image


class FaceDetection {
    
    private static var faceDetection: VNDetectFaceRectanglesRequest? = nil
    private static var faceLandmarks: VNDetectFaceLandmarksRequest? = nil
    private static var faceLandmarksDetectionRequest: VNSequenceRequestHandler? = nil
    private static var faceDetectionHandler: VNSequenceRequestHandler? = nil

    private static var faceList: [FacialFeatures] = []
    public static let defaultSkinColor =  CIColor(red: 1.0, green: 206/255, blue: 180/255, alpha: 1.0) // typical (N.European) Caucasian skin colour

    
    ////////////////////////
    // Mark: Accessors
    ////////////////////////

    // reset
    public static func reset() {
//        FaceDetection.faceDetection = VNDetectFaceRectanglesRequest()
//        FaceDetection.faceLandmarks = VNDetectFaceLandmarksRequest()
//        FaceDetection.faceLandmarksDetectionRequest = VNSequenceRequestHandler()
//        FaceDetection.faceDetectionHandler = VNSequenceRequestHandler()
        FaceDetection.faceList = []
    }
    
    // run face detection on the supplied image. Once run, use the other APIs to get the features
    public static func detectFaces(on image: CIImage, orientation: CGImagePropertyOrientation, completion: @escaping ()->()) {
        FaceDetection.faceList = []
        
        FaceDetection.faceDetection = VNDetectFaceRectanglesRequest()
        FaceDetection.faceLandmarks = VNDetectFaceLandmarksRequest()
        FaceDetection.faceLandmarksDetectionRequest = VNSequenceRequestHandler()
        FaceDetection.faceDetectionHandler = VNSequenceRequestHandler()

        try? FaceDetection.faceDetectionHandler?.perform([FaceDetection.faceDetection!], on: image, orientation: orientation)
        if let results = FaceDetection.faceDetection?.results as? [VNFaceObservation] {
            if !results.isEmpty {
                log.verbose("Found \(results.count) faces. Orientation:\(orientation)")
                FaceDetection.faceLandmarks?.inputFaceObservations = results
                detectLandmarks(on: image, orientation: orientation, completion: completion)
                
            }
        }
    }
    
    // get the number of faces that have ben detected
    public static func count() -> Int {
        return FaceDetection.faceList.count
    }
    
    
    public static func getFeatures() -> [FacialFeatures] {
        return FaceDetection.faceList
    }
    
    
    // create a CG path from an array of (image) points. In (CG) image coordinates, not UI coordinates
    public static func createPath(points: [CGPoint]) -> CGMutablePath {
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
        let mpath: CGMutablePath = path.cgPath as! CGMutablePath
        
        return mpath
    }
    
    
    // create a compound CG path from multiple arrays of (image) points. In (CG) image coordinates, not UI coordinates
    public static func createCompoundPath(points: [[CGPoint]]) -> CGMutablePath {
        let cpath = UIBezierPath()
        
        if points.count > 0 {
            for i in 0..<points.count {
                if points[i].count > 0 {
                    let path = UIBezierPath()
                    var vpoints:[CGPoint] = []
                    
                    let start = points[i][0]
                    vpoints.append(start)
                    for j in 1..<points[i].count {
                        vpoints.append(points[i][j])
                    }
                    vpoints.append(start)
                    
                    // smooth the curve
                    path.interpolatePointsWithHermite(interpolationPoints: vpoints) // create a smooth curve from the points
                    
                    // close the path and add the the compound path
                    path.close()
                    cpath.append(path)
                } else {
                    log.warning("Empty contour supplied")
                }
            }
        } else {
            log.error("No points provided")
        }
        
        
        let mpath: CGMutablePath = cpath.cgPath as! CGMutablePath
        
        return mpath
    }

    
    // create a mask from a CGPath and return the corresponding CIImage. This version is intended for use in filters to mask out features from the source image
    public static func createMask(cgpath: CGMutablePath, size: CGSize) -> CIImage? {
        
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
                
        //log.verbose("image size: \(img?.extent.size)\n Path:\(cgpath)")
        return img
    }
    
    
    // mask the input image with the supplied mask image
    public static func maskImage(image: CGImage?, mask: CGImage?) -> CGImage? {
        guard (image != nil), (mask != nil) else {
            log.error("NIL input image(s)")
            return image
        }
        
        let imageMask = CGImage(maskWidth: (mask?.width)!,
                                height: (mask?.height)!,
                                bitsPerComponent: (mask?.bitsPerComponent)!,
                                bitsPerPixel: (mask?.bitsPerPixel)!,
                                bytesPerRow: (mask?.bytesPerRow)!,
                                provider: (mask?.dataProvider)!, decode: nil, shouldInterpolate: true)
        
        if imageMask != nil {
            return image?.masking(imageMask!)
        } else {
            log.error("Error masking image")
            return image
        }
    }
    
    
    ////////////////////////
    // Mark: Processing
    ////////////////////////
    
    
    // issue a request to the Vision framework and save the results in a facialFeatures struct for each face, which is added to faceList[]
    private static func detectLandmarks(on image: CIImage, orientation: CGImagePropertyOrientation, completion: @escaping ()->()) {

        try? FaceDetection.faceLandmarksDetectionRequest?.perform([FaceDetection.faceLandmarks!], on: image, orientation: orientation)
        if let landmarksResults = FaceDetection.faceLandmarks?.results as? [VNFaceObservation] {

            DispatchQueue.main.async {
                for i in 0..<landmarksResults.count {
                    let observation = landmarksResults[i]
                    
                    if let faceBoundingBox = FaceDetection.faceLandmarks?.inputFaceObservations?[i].boundingBox.scaled(to: image.extent.size) {
                        let face = FacialFeatures()
                        face.faceBounds = faceBoundingBox
                        
                        // convert all of the different types of landmarks
                        face.faceContour = FaceDetection.convertFaceLandmark(observation.landmarks?.faceContour, faceBoundingBox)
                        face.leftEye = FaceDetection.convertFaceLandmark(observation.landmarks?.leftEye, faceBoundingBox)
                        face.rightEye = FaceDetection.convertFaceLandmark(observation.landmarks?.rightEye, faceBoundingBox)
                        face.leftEyebrow = FaceDetection.convertFaceLandmark(observation.landmarks?.leftEyebrow, faceBoundingBox)
                        face.rightEyebrow = FaceDetection.convertFaceLandmark(observation.landmarks?.rightEyebrow, faceBoundingBox)
                        face.nose = FaceDetection.convertFaceLandmark(observation.landmarks?.nose, faceBoundingBox)
                        face.noseCrest = FaceDetection.convertFaceLandmark(observation.landmarks?.noseCrest, faceBoundingBox)
                        face.medianLine = FaceDetection.convertFaceLandmark(observation.landmarks?.medianLine, faceBoundingBox)
                        face.outerLips = FaceDetection.convertFaceLandmark(observation.landmarks?.outerLips, faceBoundingBox)
                        face.innerLips = FaceDetection.convertFaceLandmark(observation.landmarks?.innerLips, faceBoundingBox)
                        face.leftPupil = FaceDetection.convertFaceLandmark(observation.landmarks?.leftPupil, faceBoundingBox)
                        face.rightPupil = FaceDetection.convertFaceLandmark(observation.landmarks?.rightPupil, faceBoundingBox)
                        
//                        if face.faceContour.count >= 2 {
//                            let n = face.faceContour.count - 1
//                            let x = face.faceContour[0].x + 0.5*(face.faceContour[n].x - face.faceContour[0].x)
//                            let y = face.faceContour[0].y + 0.5*(face.faceContour[n].y - face.faceContour[0].y)
//                            let skinpos = CGPoint(x: x, y: y)
//                            if image.extent.contains(skinpos) {
//                                face.skinColor = CIColor(cgColor: (image.cgImage?.getColor(x: Int(skinpos.x), y: Int(skinpos.y)))!)
//                            } else {
//                                face.skinColor = FaceDetection.defaultSkinColor
//                            }
//                            log.verbose("Skin Color: \(face.skinColor)")
//                        }
                        FaceDetection.faceList.append(face)
                    }
                }
            }
        }
        DispatchQueue.main.async {
            completion()
            FaceDetection.faceDetection = nil
            FaceDetection.faceLandmarks = nil
            FaceDetection.faceLandmarksDetectionRequest = nil
            FaceDetection.faceDetectionHandler = nil
        }
    }
    
    // convert landmarks into CGPoint arrays
    private static func convertFaceLandmark(_ landmark: VNFaceLandmarkRegion2D?, _ boundingBox: CGRect) -> [CGPoint] {
        
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
    
}
