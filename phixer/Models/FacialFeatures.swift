//
//  FacialFeatures.swift
//  phixer
//
//  Created by Philip Price on 2/9/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import CoreGraphics


// This is just a simple class that encapsulates the facial recognition data returned by the Vision framework, mostly so that you can pass it around
// Note that all values are in CG Image coordinates (because that is what is needed by filters). This is different from the Vision fraamework


class FacialFeatures {
    // a rectangle that defines the bounds of the face (can be useful for sampling, passing to filters etc.)
    public var faceBounds: CGRect
    
    // The region containing all face landmark points.
    public var allPoints: [CGPoint]
    
    // The region containing points that trace the face contour from the left cheek, over the chin, to the right cheek.
    public var faceContour: [CGPoint]
    
    // The region containing points that outline the left eye.
    public var leftEye: [CGPoint]
    
    // The region containing points that outline the right eye.
    public var rightEye: [CGPoint]
    
    // The region containing points that trace the left eyebrow.
    public var leftEyebrow: [CGPoint]
    
    // The region containing points that trace the right eyebrow.
    public var rightEyebrow: [CGPoint]

    // The region containing points that outline the nose.
    public var nose: [CGPoint]

    // The region containing points that trace the center crest of the nose.
    public var noseCrest: [CGPoint]
    
    // The region containing points that trace a vertical line down the center of the face.
    public var medianLine: [CGPoint]
    
    // The region containing points that outline the outside of the lips.
    public var outerLips: [CGPoint]
    
    // The region containing points that outline the space between the lips.
    public var innerLips: [CGPoint]
    
    // The region containing the point where the left pupil is located.
    public var leftPupil: [CGPoint]
    
    // The region containing the point where the right pupil is located.
    public var rightPupil: [CGPoint]

    
    init (){
        self.faceBounds = CGRect.zero
        self.allPoints = []
        self.faceContour = []
        self.leftEye = []
        self.rightEye = []
        self.leftEyebrow = []
        self.rightEyebrow = []
        self.nose = []
        self.noseCrest = []
        self.medianLine = []
        self.outerLips = []
        self.innerLips = []
        self.leftPupil = []
        self.rightPupil = []
    }
    
}
