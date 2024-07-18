// FisheyeDistortionCorrector.swift
// OpenAthenaIOS
//
// Created by Bobby Krupczak on 10/6/23.
// Ported from OpenAthenaAndroid java code
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

import Foundation

class FisheyeDistortionCorrector {
    
    var p0,p1,p2,p3,p4: Double
    var c,d,e,f: Double

    init(p0: Double, p1: Double, p2: Double, p3: Double, p4: Double,
         c: Double, d: Double, e: Double, f: Double) {

        self.p0 = p0
        self.p1 = p1
        self.p2 = p2
        self.p3 = p3
        self.p4 = p4
        self.c = c
        self.d = d
        self.e = e
        self.f = f
    }

    func correctDistortion(xNormalized: Double,  yNormalized: Double) -> (Double, Double)
    {
        var x = xNormalized;
        var y = yNormalized;
        var rDistorted: Double = sqrt(x * x + y * y)
        var thetaDistorted: Double  = atan(rDistorted)
        
        var thetaUndistorted: Double = p0 + p1 * thetaDistorted + p2 * pow(thetaDistorted, 2) +
                p3 * pow(thetaDistorted, 3) + p4 * pow(thetaDistorted, 4)

        var rUndistorted: Double = tan(thetaUndistorted)

        var xRadial: Double = x * (rUndistorted / rDistorted)
        var yRadial: Double = y * (rUndistorted / rDistorted)

        var deltaX: Double = 2 * c * xRadial * yRadial + d * (rUndistorted * rUndistorted + 2 * xRadial * xRadial)
        var deltaY: Double = 2 * d * xRadial * yRadial + c * (rUndistorted * rUndistorted + 2 * yRadial * yRadial)

        var xUndistortedNormalized = xRadial + deltaX
        var yUndistortedNormalized = yRadial + deltaY

        return (xUndistortedNormalized, yUndistortedNormalized)
    }
    
} // FisheyeDistortionCorrector
