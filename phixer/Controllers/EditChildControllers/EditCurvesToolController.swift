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


    
    // the main func
    
    private func buildView(_ toolview: UIView){
        
        // set up the view sizes
        histogramView.frame.size.height = toolview.frame.size.width.rounded()
        histogramView.frame.size.width = histogramView.frame.size.height
        histogramView.backgroundColor = UIColor.clear

        curveView.frame.size.height = histogramView.frame.size.height
        curveView.frame.size.width = histogramView.frame.size.width
        curveView.backgroundColor = UIColor.clear // needs to be transparent
        
        /*** for now, leaving control area empty. Later, add controls for chanells, presets etc.
        controlView.frame.size.height = toolview.frame.size.height - histogramView.frame.size.height
        controlView.frame.size.width = toolview.frame.size.width
        controlView.backgroundColor = UIColor.clear
         ***/
        controlView.frame.size.height = 0
        controlView.frame.size.width = toolview.frame.size.width
        controlView.backgroundColor = UIColor.clear
        
        // adjust the overall size to account for the control panel
        let toolHeight = histogramView.frame.size.height + controlView.frame.size.height + 16
        resetToolHeight(toolHeight) // calls back to the base class
        
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
        // TODO: just leaving it simple for now (other priorities)
    }

    ////////////////////////
    // Tone Curve
    ////////////////////////
    
    let controlPointSize:CGFloat = 24.0
    let curvePath:UIBezierPath = UIBezierPath()
    let curveLayer:CAShapeLayer = CAShapeLayer()


    // load the main curve view
    private func loadCurve() {

        curveImageView.frame = histogramImageView.frame
        curveView.addSubview(curveImageView)

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
        curveLayer.lineWidth = 4.0
        curveLayer.lineJoin = kCALineJoinRound
        curveLayer.lineCap = kCALineCapRound
        curveImageView.layer.addSublayer(curveLayer)

        // create the views for the control points
        for point in currToneCurve {
            let v = UIImageView()
            v.backgroundColor = theme.highlightColor.withAlphaComponent(0.6)
            let x:CGFloat = ((point.x * curveImageView.frame.size.width) - controlPointSize / 2.0).rounded()
            // UIView origin is top left, graph is bottom left
            let y:CGFloat = ((curveImageView.frame.size.height - point.y * curveImageView.frame.size.height) - controlPointSize / 2.0).rounded()
            //log.debug("(\(point.x),\(point.y)) -> (\(x),\(y))")
            v.frame = CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: controlPointSize, height: controlPointSize))
            v.isUserInteractionEnabled = true
            controlPoints.append(v)
            curveImageView.addSubview(v)
        }
        
        updateCurve()
    }

    // called when the control points are changed
    func updateCurve(){
        
        // update the screen position of the control points
        for i in 0...(currToneCurve.count-1) {
            let v = controlPoints[i]
            let point = currToneCurve[i]
            let x:CGFloat = ((point.x * curveImageView.frame.size.width) - controlPointSize / 2.0).rounded()
            let y:CGFloat = ((curveImageView.frame.size.height - point.y * curveImageView.frame.size.height) - controlPointSize / 2.0).rounded()
            //log.debug("(\(point.x),\(point.y)) -> (\(x),\(y))")
            v.frame.origin = CGPoint(x: x, y: y)
            v.tag = i // lets the touch handler identify which point
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
            let x:CGFloat = ((point.x * curveImageView.frame.size.width)).rounded()
            let y:CGFloat = ((curveImageView.frame.size.height - point.y * curveImageView.frame.size.height)).rounded()
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

    // convert a position in view coordinates to the equivalent in Graph coordinates
    func graphToViewPosition(_ position: CGPoint) -> CGPoint {
        let x:CGFloat = ((position.x * curveImageView.frame.size.width)).rounded().clamped(0.0, curveImageView.frame.size.width)
        let y:CGFloat = ((curveImageView.frame.size.height - position.y * curveImageView.frame.size.height)).rounded().clamped(0.0, curveImageView.frame.size.height)
        //log.debug("(\(position.x),\(position.y)) -> (\(x),\(y))")
        return CGPoint(x: x, y: y)
    }

    // convert a position in view coordinates to the equivalent in Graph coordinates
    func viewToGraphPosition(_ position: CGPoint) -> CGPoint {
        let x:CGFloat = ((position.x / curveImageView.frame.size.width)) //.clamped(0.0, 1.0)
        let y:CGFloat = (1.0 - position.y / curveImageView.frame.size.height) //.clamped(0.0, 1.0)
        //log.debug("frame:(\(curveImageView.frame.size.width),\(curveImageView.frame.size.height)) view:(\(position.x),\(position.y)) -> graph:(\(x),\(y))")
        return CGPoint(x: x, y: y)
    }

    //////////////////////////////////////////
    // MARK: - Touch handling
    //////////////////////////////////////////
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: curveImageView)
            //log.debug("touch:\(position)")
            handleTouch(position)
        }
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: curveImageView)
            //log.debug("touch:\(position)")
            handleTouch(position)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: curveImageView)
            //log.debug("touch:\(position)")
            handleTouch(position)
         }
    }

    // common routine to handle a touch
    private func handleTouch(_ position: CGPoint){
        // find which view was touched
        for v in controlPoints {
            if v.frame.contains(position) {
                let gpos = viewToGraphPosition(position)
                let index = v.tag
                log.debug("index:\(index) view:\(position) graph:\(gpos)")
                if (index >= 0) && (index < currToneCurve.count) {
                    // don't allow points to cross in the x direction, or exceed the graph bounds
                    if (gpos.x>=0.0) && (gpos.x<=1.0) && (gpos.y>=0.0) && (gpos.y<=1.0) { // within graph bounds?
                        var ok:Bool = false
                        let margin:CGFloat = 0.1 // points cannot get closer than this
                        if (index == 0){ // left item
                            if gpos.x < (currToneCurve[index+1].x - margin) {
                                ok = true
                            }
                        } else if index == (currToneCurve.count-1) { // right point
                            if gpos.x > (currToneCurve[index-1].x + margin) {
                                ok = true
                           }
                        } else { // middle points
                            if (gpos.x < (currToneCurve[index+1].x - margin)) &&
                                (gpos.x > (currToneCurve[index-1].x + margin)) {
                                ok = true
                            }

                        }
                        
                        // update the tone curve and the control points displays
                        if ok {
                            currToneCurve[index] = gpos
                            controlPoints[index].frame.origin = CGPoint(x: position.x-controlPointSize/2.0, y: position.y-controlPointSize/2.0)
                            applyCurve()
                        } else {
                            log.debug("position out of allowed range")
                        }
                    }
                }
                break
            }
        }

    }

} // EditCurvesToolController
//########################

class ToneCurvePresets {
    // pre-defined tone curves
    public static let linear = [ CGPoint(x: 0.0, y: 0.0), CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.75, y: 0.75), CGPoint(x: 1.0, y: 1.0) ]
    
    public static let mediumContrast = [ CGPoint(x: 0.0, y: 0.0), CGPoint(x: 0.25, y: 0.20), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.75, y: 0.80), CGPoint(x: 1.0, y: 1.0) ]
    
    public static let strongContrast = [ CGPoint(x: 0.0, y: 0.0), CGPoint(x: 0.25, y: 0.15), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.75, y: 0.85), CGPoint(x: 1.0, y: 1.0) ]

}

//////////////////////////////////////////
// MARK: - Delegate functions
//////////////////////////////////////////



