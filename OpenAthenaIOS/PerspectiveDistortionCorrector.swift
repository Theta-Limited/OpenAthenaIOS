// PerspectiveDistortionCorrector.swift
// OpenAthenaIOS
// Created by Bobby Krupczak on 10/6/23.
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

// re issue #64
// The previous lens distortion correction equations were wrong. They incorrectly applied the distortion
// again instead of reversing it as we intended.  To fix this in OpenAthena iOS, should use a modified distortion
// correction equation based on the division model which only accounts for the radial distortion parameters
// and not the tangential ones
// https://en.wikipedia.org/wiki/Distortion_(optics)#Software_correction

import Foundation

class PerspectiveDistortionCorrector {
    
    // Assuming these values are obtained from lens calibration
    private var k1, k2, k3: Double
    
    init(k1: Double, k2: Double, k3: Double) {
        self.k1 = k1
        self.k2 = k2
        self.k3 = k3
    }

    func correctDistortion(xNormalizedDistorted: Double, yNormalizedDistorted: Double)  -> (Double, Double)
    {
//        var x: Double = xNormalized
//        var y: Double = yNormalized
//        var r2: Double = x*x + y*y
//        var r4: Double = r2 * r2
//
//        // Radial distortion correction
//        var xCorrectedNormalized = x * (1 + k1 * r2 + k2 * r4);
//        var yCorrectedNormalized = y * (1 + k1 * r2 + k2 * r4);
//
//        // Tangential distortion correction
//        xCorrectedNormalized = xCorrectedNormalized + (2 * p1 * x * y + p2 * (r2 + 2 * x * x));
//        yCorrectedNormalized = yCorrectedNormalized + (p1 * (r2 + 2 * y * y) + 2 * p2 * x * y);
//
//        return (xCorrectedNormalized, yCorrectedNormalized)
        
        // simplified distortion correction based on the division model
        // omits correction for tangential distortion.
        // https://en.wikipedia.org/wiki/Distortion_(optics)#Software_correction

        // Compute r^2
        var r2: Double = xNormalizedDistorted * xNormalizedDistorted + yNormalizedDistorted * yNormalizedDistorted
        var r4: Double = r2 * r2
        var r6: Double = r2 * r4
        
        // Denominator: 1 + k1*r^2 + k2*r^4 + k3*r^6
        var denom: Double = 1.0 + k1 * r2 + k2 * r4 + k3 * r6
        
        // Invert the division model
        var xNormalizedUndistorted: Double = xNormalizedDistorted / denom
        var yNormalizedUndistorted: Double = yNormalizedDistorted / denom
        
        return (xNormalizedUndistorted, yNormalizedUndistorted)
    }
    
} // PerspectiveDistortionCorrector
