// PerspectiveDistortionCorrector.swift
// OpenAthenaIOS
// Created by Bobby Krupczak on 10/6/23.
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

import Foundation

class PerspectiveDistortionCorrector {
    
    // Assuming these values are obtained from lens calibration
    private var k1, k2, p1, p2: Double
    
    init(k1: Double, k2: Double, p1: Double, p2: Double) {
        self.k1 = k1
        self.k2 = k2
        self.p1 = p1
        self.p2 = p2
    }

    func correctDistortion(xNormalized: Double, yNormalized: Double)  -> (Double, Double)
    {
        var x: Double = xNormalized
        var y: Double = yNormalized
        var r2: Double = x*x + y*y
        var r4: Double = r2 * r2

        // Radial distortion correction
        var xCorrectedNormalized = x * (1 + k1 * r2 + k2 * r4);
        var yCorrectedNormalized = y * (1 + k1 * r2 + k2 * r4);

        // Tangential distortion correction
        xCorrectedNormalized = xCorrectedNormalized + (2 * p1 * x * y + p2 * (r2 + 2 * x * x));
        yCorrectedNormalized = yCorrectedNormalized + (p1 * (r2 + 2 * y * y) + 2 * p2 * x * y);

        return (xCorrectedNormalized, yCorrectedNormalized)
    }
    
} // PerspectiveDistortionCorrector
