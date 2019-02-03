//
//  GridOverlayView.swift
//  phixer
//
//  Created by Philip Price on 2/1/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

// A View class that draws a Crop Grid display, with a clear background
// Note: this is a 'passive' class, i.e. it just draws the grid. Touch handling etc. is done elsewhere
import Foundation
import UIKit

class GridOverlayView: UIView {
    
    
    private var theme = ThemeManager.currentTheme()
    
    private lazy var gridFrame: CGRect = self.frame
    
    //////////////////////
    // MARK - Accessors
    //////////////////////
    
    // set the frame for the grid drawing.
    public func setGridFrame(_ frame: CGRect) {
        // make sure the grid stays within the containing view
        self.gridFrame.origin.x = max(frame.origin.x, self.frame.origin.x)
        self.gridFrame.origin.y = max(frame.origin.y, self.frame.origin.y)
        self.gridFrame.size.width = min(frame.size.width, self.frame.size.width)
        self.gridFrame.size.height = min(frame.size.height, self.frame.size.height)
        
        drawGridLines()
    }
    
    //////////////////////
    // MARK: Main logic
    //////////////////////

    override func layoutSubviews() {
        super.layoutSubviews()
        
        theme = ThemeManager.currentTheme()
        
        self.backgroundColor = UIColor.clear
        
        setupGridLayer()
        drawGridLines()
    }
    
    let gridLayer:CAShapeLayer = CAShapeLayer()

    private func setupGridLayer(){
        gridLayer.frame = self.frame
        gridLayer.fillColor = UIColor.clear.cgColor
        gridLayer.strokeColor = theme.borderColor.cgColor
        gridLayer.lineWidth = 2.0
        gridLayer.lineJoin = CAShapeLayerLineJoin.round
        gridLayer.lineCap = CAShapeLayerLineCap.round
        self.layer.addSublayer(gridLayer)
    }
    
    
    private func drawGridLines(){
        
        //log.debug("self:\(self.frame) grid:\(gridFrame)")
        let gridPath = UIBezierPath()
        let x = gridFrame.origin.x
        let y = gridFrame.origin.y
        let w = gridFrame.size.width
        let h = gridFrame.size.height
        
        //let strokeColor = theme.borderColor
        //UIColor.white.setStroke()
        
        // draw the bounding rectangle
        gridLayer.lineWidth = 4.0
        gridPath.move(to: CGPoint(x:x, y:y))
        gridPath.addLine(to: CGPoint(x:x+w, y:y))
        gridPath.addLine(to: CGPoint(x:x+w, y:y+h))
        gridPath.addLine(to: CGPoint(x:x, y:y+h))
        gridPath.addLine(to: CGPoint(x:x, y:y))
        gridPath.close()
        //gridPath.stroke()
        
        //log.debug("tl:\(CGPoint(x:x, y:y)) br:\(CGPoint(x:x+w, y:y+h))")

        // draw lines at 1/3 height and width
        let xsep = (w / 3.0).rounded()
        let ysep = (h / 3.0).rounded()

        gridLayer.lineWidth = 1.0
        // horizontal
        gridPath.move(to: CGPoint(x:x, y:y+ysep))
        gridPath.addLine(to: CGPoint(x:x+w, y:y+ysep))
        gridPath.move(to: CGPoint(x:x, y:y+2*ysep))
        gridPath.addLine(to: CGPoint(x:x+w, y:y+2*ysep))

        // vertical
        gridPath.move(to: CGPoint(x:x+xsep, y:y))
        gridPath.addLine(to: CGPoint(x:x+xsep, y:y+h))
        gridPath.move(to: CGPoint(x:x+2.0*xsep, y:y))
        gridPath.addLine(to: CGPoint(x:x+2.0*xsep, y:y+h))

        // set the color and stroke
        //gridPath.stroke()
        
        gridLayer.path = gridPath.cgPath

    }
}
