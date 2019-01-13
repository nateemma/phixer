//
//  EditCurvesToolController.swift
//  phixer
//
//  Created by Philip Price on 12/17/18
//  Copyright © 2018 Nateemma. All rights reserved.
//

import UIKit
import Neon
import CoreImage



private var filterList: [String] = []
private var filterCount: Int = 0

// This View Controller is the 'base' class used for creating Edit 'Tool' displays, which take up most of the screen
// This mostly just sets up the framing, title, navigation etc. Other stuff must be done in the subclass, via the loadToolView() callback

class EditCurvesToolController: EditBaseToolController {
    


    
 
    ////////////////////
    // 'Virtual' funcs, these must be overidden by the subclass
    ////////////////////
    
    override func getTitle() -> String{
        return "Tone Curve Editor"
    }
    
    override func loadToolView(toolview: UIView){
        buildView(toolview)
    }
    
    override func commit() {
        // Save preview filter(s)
        // TODO: modify EditManager to handle multiple preview filters
        EditManager.savePreviewFilter()
        delegate?.filterControllerCompleted(tag:self.getTag())
        dismiss()
    }
    
    
    
    ////////////////////
    // Tool-specific code
    ////////////////////

    private var filterManager: FilterManager? = FilterManager.sharedInstance

    // container views
    private var histogramView:UIView! = UIView()
    private var curveView:UIView! = UIView()
    private var controlView:UIView! = UIView()
    
    // display items
    private var histogramImageView:UIImageView! = UIImageView()
    private var curveImageView:UIImageView! = UIImageView()
    private var controlPoints: [UIImageView] = [ ]


    private var histogramDataFilter:CIFilter? = nil
    private var histogramDisplayFilter:CIFilter? = nil
    private var toneCurveFilter:FilterDescriptor? = nil
    
    private var currToneCurve:[CGPoint] = [ CGPoint(x: 0.0, y: 0.0), CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.75, y: 0.75), CGPoint(x: 1.0, y: 1.0) ] {
        didSet { updateCurve() }
    }
    
    private let scale:CGFloat = 256.0
    private var pixelsPerValue:CGFloat = 1.0

    // pre-defined tone curves
    private let curveLinear = [ CGPoint(x: 0.0, y: 0.0), CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.75, y: 0.75), CGPoint(x: 1.0, y: 1.0) ]
    private let curveMedContrast = [ CGPoint(x: 0.0, y: 0.0), CGPoint(x: 0.25, y: 0.20), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.75, y: 0.80), CGPoint(x: 1.0, y: 1.0) ]
    private let curveStrongContrast = [ CGPoint(x: 0.0, y: 0.0), CGPoint(x: 0.25, y: 0.15), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.75, y: 0.85), CGPoint(x: 1.0, y: 1.0) ]

    
    // the main func
    
    private func buildView(_ toolview: UIView){
        
        // set up the view sizes
        histogramView.frame.size.height = toolview.frame.size.width.rounded()
        histogramView.frame.size.width = histogramView.frame.size.height
        histogramView.backgroundColor = UIColor.clear

        curveView.frame.size.height = histogramView.frame.size.height
        curveView.frame.size.width = histogramView.frame.size.width
        curveView.backgroundColor = UIColor.clear // needs to be transparent
        
        controlView.frame.size.height = toolview.frame.size.height - histogramView.frame.size.height
        controlView.frame.size.width = toolview.frame.size.width
        controlView.backgroundColor = UIColor.clear

        // layout
        toolview.addSubview(histogramView)
        toolview.addSubview(curveView)
        toolview.addSubview(controlView)
        
        histogramView.anchorToEdge(.top, padding: 0, width: histogramView.frame.size.width, height: histogramView.frame.size.height)
        curveView.anchorToEdge(.top, padding: 0, width: curveView.frame.size.width, height: curveView.frame.size.height)
        controlView.anchorToEdge(.bottom, padding: 0, width: controlView.frame.size.width, height: controlView.frame.size.height)
        
        initFilters()
        loadHistogram()
        loadCurve()
        loadControls()


        //DBG:
        currToneCurve = curveMedContrast
    }
    
    private func initFilters(){
        // allocate filters once for efficiency
        histogramDataFilter = CIFilter(name: "CIAreaHistogram")
        histogramDisplayFilter = CIFilter(name: "CIHistogramDisplayFilter")
        toneCurveFilter = filterManager?.getFilterDescriptor(key: "CIToneCurve")
    }

    ////////////////////////
    // Histogram
    ////////////////////////
    
    private func loadHistogram() {
        
        let w = histogramView.frame.size.width - 32
        histogramImageView.frame.size.width = w
        histogramImageView.frame.size.height = w
        histogramImageView.layer.borderWidth = 2.0
        histogramImageView.layer.borderColor = theme.borderColor.withAlphaComponent(0.5).cgColor
        histogramView.addSubview(histogramImageView)
        histogramImageView.anchorInCenter(width: histogramImageView.frame.size.width, height: histogramImageView.frame.size.height)

        pixelsPerValue = 100.0 * histogramImageView.frame.size.width / scale
        
        // get the histogram data from the current image
        histogramDataFilter?.setValuesForKeys(["inputImage": InputSource.getCurrentImage()!,
                                               "inputExtent": InputSource.getExtent(),
                                               "inputCount": histogramImageView.frame.size.width,
                                               "inputScale": (scale - 1.0).rounded() ])
        let hData = histogramDataFilter?.outputImage
        
        // generate the histogram display
        histogramDisplayFilter?.setValuesForKeys(["inputImage": hData!, "inputHeight": histogramImageView.frame.size.height, "inputHighLimit": 1.0, "inputLowLimit": 1.0 ])
        histogramImageView.image = UIImage(ciImage: (histogramDisplayFilter?.outputImage)!)

    }
 
    ////////////////////////
    // Controls
    ////////////////////////
    

    // load the UI controls
    private func loadControls() {
        
    }

    ////////////////////////
    // Tone Curve
    ////////////////////////
    
    let controlPointSize:CGFloat = 16.0
    let curvePath:UIBezierPath = UIBezierPath()
    let curveLayer:CAShapeLayer = CAShapeLayer()


    // load the main curve view
    private func loadCurve() {

        //curveImageView.frame.size.width = histogramImageView.frame.size.width
        //curveImageView.frame.size.height = histogramImageView.frame.size.height
        curveImageView.frame = histogramImageView.frame
        curveView.addSubview(curveImageView)
        //curveImageView.anchorInCenter(width: curveImageView.frame.size.width, height: curveImageView.frame.size.height)

        loadControlPoints()
        displayCurve()
        applyCurve()
        
        EditManager.addPreviewFilter(toneCurveFilter)
    }
 
    // builds the views for the control points and creates the layer for the Bezier line path
    func loadControlPoints() {
        
        controlPoints = [ ]
     
        
        // set up the curve layer
        curveLayer.frame = CGRect(origin: CGPoint.zero, size: curveImageView.frame.size)
        curveLayer.fillColor = UIColor.clear.cgColor
        curveLayer.strokeColor = theme.borderColor.cgColor
        curveLayer.lineWidth = 3.0
        curveLayer.lineJoin = kCALineJoinRound
        curveLayer.lineCap = kCALineCapRound
        curveImageView.layer.addSublayer(curveLayer)

        // create the views for the control points
        for point in currToneCurve {
            let v = UIImageView()
            v.backgroundColor = theme.highlightColor
            let x = ((point.x * curveImageView.frame.size.width) - controlPointSize / 2.0).rounded()
            // UIView origin is top left, graph is bottom left
            let y = ((curveImageView.frame.size.height - point.y * curveImageView.frame.size.height) - controlPointSize / 2.0).rounded()
            //log.debug("(\(point.x),\(point.y)) -> (\(x),\(y))")
            v.frame = CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: controlPointSize, height: controlPointSize))
            controlPoints.append(v)
            curveImageView.addSubview(v)
        }
    }

    // called when the control points are changed
    func updateCurve(){
        
        // update the screen position of the control points
        for i in 0...(currToneCurve.count-1) {
            let v = controlPoints[i]
            let point = currToneCurve[i]
            let x = ((point.x * curveImageView.frame.size.width) - controlPointSize / 2.0).rounded()
            let y = ((curveImageView.frame.size.height - point.y * curveImageView.frame.size.height) - controlPointSize / 2.0).rounded()
            //log.debug("(\(point.x),\(point.y)) -> (\(x),\(y))")
            v.frame.origin = CGPoint(x: x, y: y)
        }
        
        displayCurve()
    }
    
    
    // display the curve through the control points
    func displayCurve(){
        
        // update the Bezier curve based on the positions of the control points
        
        var pathPoints : [CGPoint] = []
        curvePath.removeAllPoints()
        
        //log.debug("frame:\(curveImageView.frame)")
        for i in 0...(currToneCurve.count-1) {
            let point = currToneCurve[i]
            let x = ((point.x * curveImageView.frame.size.width)).rounded()
            let y = ((curveImageView.frame.size.height - point.y * curveImageView.frame.size.height)).rounded()
            //log.debug("(\(point.x),\(point.y)) -> (\(x),\(y))")
            pathPoints.append(CGPoint(x: x, y: y))
        }

        curvePath.interpolatePointsWithHermite(interpolationPoints: pathPoints)
        curveLayer.path = self.curvePath.cgPath
    }
    
    // apply the tone curve to the displayed image
    func applyCurve() {
        
        //displayCurve()
        
        toneCurveFilter?.setPositionParameter("inputPoint0", position: CIVector(cgPoint: currToneCurve[0]))
        toneCurveFilter?.setPositionParameter("inputPoint1", position: CIVector(cgPoint: currToneCurve[1]))
        toneCurveFilter?.setPositionParameter("inputPoint2", position: CIVector(cgPoint: currToneCurve[2]))
        toneCurveFilter?.setPositionParameter("inputPoint3", position: CIVector(cgPoint: currToneCurve[3]))
        toneCurveFilter?.setPositionParameter("inputPoint4", position: CIVector(cgPoint: currToneCurve[4]))
        
        self.delegate?.filterControllerUpdateRequest(tag: self.getTag())
    }

} // EditCurvesToolController
//########################



//////////////////////////////////////////
// MARK: - Delegate functions
//////////////////////////////////////////



