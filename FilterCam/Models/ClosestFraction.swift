//
//  ClosestFraction.swift
//  FilterCam
//
//  Created by Philip Price on 10/4/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation

/**
 /*
 ** find rational approximation to given real number
 ** David Eppstein / UC Irvine / 8 Aug 1993
 **
 ** With corrections from Arno Formella, May 2008
 **
 **
 ** based on the theory of continued fractions
 ** if x = a1 + 1/(a2 + 1/(a3 + 1/(a4 + ...)))
 ** then best approximation is found by truncating this series
 ** (with some adjustments in the last term).
 **
 ** Note the fraction can be recovered as the first column of the matrix
 **  ( a1 1 ) ( a2 1 ) ( a3 1 ) ...
 **  ( 1  0 ) ( 1  0 ) ( 1  0 )
 ** Instead of keeping the sequence of continued fraction terms,
 ** we just keep the last partial product of these matrices.
 */
 
 #include <stdio.h>
 
 main(ac, av)
 int ac;
 char ** av;
 {
 double atof();
 int atoi();
 void exit();
 
 long m[2][2];
 double x, startx;
 long maxden;
 long ai;
 
 /* read command line arguments */
 if (ac != 3) {
	fprintf(stderr, "usage: %s r d\n",av[0]);  // AF: argument missing
	exit(1);
 }
 startx = x = atof(av[1]);
 maxden = atoi(av[2]);
 
 /* initialize matrix */
 m[0][0] = m[1][1] = 1;
 m[0][1] = m[1][0] = 0;
 
 /* loop finding terms until denom gets too big */
 while (m[1][0] *  ( ai = (long)x ) + m[1][1] <= maxden) {
	long t;
	t = m[0][0] * ai + m[0][1];
	m[0][1] = m[0][0];
	m[0][0] = t;
	t = m[1][0] * ai + m[1][1];
	m[1][1] = m[1][0];
	m[1][0] = t;
 if(x==(double)ai) break;     // AF: division by zero
	x = 1/(x - (double) ai);
 if(x>(double)0x7FFFFFFF) break;  // AF: representation failure
 }
 
 /* now remaining x is between 0 and 1/ai */
 /* approx as either 0 or 1/m where m is max that will fit in maxden */
 /* first try zero */
 printf("%ld/%ld, error = %e\n", m[0][0], m[1][0],
 startx - ((double) m[0][0] / (double) m[1][0]));
 
 /* now try other possibility */
 ai = (maxden - m[1][1]) / m[1][0];
 m[0][0] = m[0][0] * ai + m[0][1];
 m[1][0] = m[1][0] * ai + m[1][1];
 printf("%ld/%ld, error = %e\n", m[0][0], m[1][0],
 startx - ((double) m[0][0] / (double) m[1][0]));
 }
 **/




/***
 ** find rational approximation to given real number
 ** David Eppstein / UC Irvine / 8 Aug 1993
 **
 ** With corrections from Arno Formella, May 2008
 ***/
class ClosestFraction{
    static func find(_ number:Float, maxDenominator:Int)->(Int,Int){
        
        var startx: Float
        var maxden: Int
        var m:  [[Int]] = [[1,0], [0,1]]
        var x: Float
        var ai: Int
        var af: Float
        var t: Int
        var err1: Float, err2: Float
        var n1:Int, n2: Int, d1: Int, d2: Int
        
        startx = number
        maxden = maxDenominator
        
        /* initialize matrix */
        m[0][0] = 1
        m[1][1] = 1
        m[0][1] = 0
        m[1][0] = 0
        
        /* loop finding terms until denom gets too big */
        x = startx
        ai = Int(x)
        while ((m[1][0] *  ai  + m[1][1]) <= maxden) {
            t = m[0][0] * ai + m[0][1]
            m[0][1] = m[0][0]
            m[0][0] = t
            t = m[1][0] * ai + m[1][1]
            m[1][1] = m[1][0]
            m[1][0] = t
            
            af = Float(ai)
            if ((x-af)>0.00000001){
                x = 1 / (x - af)
            } else {
                break
            }
            
            // if(x>(double)0x7FFFFFFF) break;  // AF: representation failure (TODO: how to do in Swift?)
            
           ai = Int(x)
        }
        
        /* now remaining x is between 0 and 1/ai */
        /* approx as either 0 or 1/m where m is max that will fit in maxden */
        /* first try zero */
        n1 = m[0][0]
        d1 = m[1][0]
        err1 = startx - Float(n1)/Float(d1)
        //log.debug("Fraction1: \(n1)/\(d1) err:\(err1)")
        
        /* now try other possibility */
        ai = (maxden - m[1][1]) / m[1][0]
        n2 = m[0][0] * ai + m[0][1]
        d2 = m[1][0] * ai + m[1][1]
        err2 = startx - Float(n2)/Float(d2)
        //log.debug("Fraction2: \(n2)/\(d2) err:\(err2)")
        
        //figure out which one works best!
        if (fabsf(err1)<fabsf(err2)){
            return (n1, d1)
        } else {
            return (n2, d2)
        }

    }
}
