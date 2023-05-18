//
//  Geodetic.swift
//  OpenAthenaIOS
//
//  Created by Bobby Krupczak on 4/18/23.
//
//  CK42 Coordinate system conversion functions
//  Originally ported from https://github.com/Dimowner/WGS84_TO_SK42/
//  http://gis-lab.info/qa/wgs84-sk42-wgs84-formula.html
//  http://gis-lab.info/qa/datum-transform-methods.html
//  Port/conversion to Swift done by ChatGPT and then
//  modified/enhanced by rdk

import Foundation

public class CK42Geodetic {
    
    // WGS84 to CK42 conversions
    
    // convert WGS84 Lat/Lon/H to CK42 Lat/Lon
    // calls separate functions for converting Lat and Lon
    // and combines into single function
    
    static func WGS84_CK42(Bd: Double, Ld: Double, H: Double) -> (Double,Double,Double) {
        var ck42Lat, ck42Lon, ck42alt: Double
        
        ck42Lat = WGS84_CK42_Lat(Bd: Bd, Ld: Ld, H: H)
        
        ck42Lon = WGS84_CK42_Long(Bd: Bd, Ld: Ld, H: H)
        
        ck42alt = WGS84_CK42_Altitude(CK42Lat: ck42Lat, CK42Lon: ck42Lon, WGS84Alt: H)
        
        return (ck42Lat,ck42Lon,ck42alt)
    }
    
    // Given CK42 Lat/Lon and a WGS84 altitude (in meters), return CK42 altitude
    // Altitude calculation assumes the SK42 and WGS84 ellipsoids have exact same
    // center.  This is not totally correct, but in practice it is close enough to the
    // actual value
    // See https://gis.stackexchange.com/a/88499
    
    static func WGS84_CK42_Altitude(CK42Lat: Double, CK42Lon: Double, WGS84Alt: Double) -> Double
    {
        var ck42alt: Double
        
        ck42alt = WGS84Alt - CK42_WGS84_Alt(Bd: CK42Lat, Ld: CK42Lon, H: 0.0)
        ck42alt = ck42alt.rounded()
        
        return ck42alt
    }

    // Recalculation of latitude from WGS-84 to CK-42.
    // @param Bd latitude
    // @param Ld longitude
    // @param H height
    // @return latitude in CK-42
    
    static func WGS84_CK42_Lat(Bd: Double, Ld: Double, H: Double) -> Double {
        return Bd - dB(Bd: Bd, Ld: Ld, H: H) / 3600
    }

    // Recalculation of longitude from WGS-84 to CK-42.
    // @param Bd latitude
    // @param Ld longitude
    // @param H height
    // @return longitude in CK-42

     static func WGS84_CK42_Long(Bd: Double, Ld: Double, H: Double) -> Double {
        return Ld - dL(Bd: Bd, Ld: Ld, H: H) / 3600
    }

    // @param Bd latitude
    // @param Ld longitude
    // @param H height
    // @return

     static func dB(Bd: Double, Ld: Double, H: Double) -> Double {
        let B = Bd * .pi / 180
        let L = Ld * .pi / 180
        let M = a * (1 - e2) / pow((1 - e2 * pow(sin(B), 2)), 1.5)
        let N = a * pow((1 - e2 * pow(sin(B), 2)), -0.5)
        let result = ro / (M + H) * (N / a * e2 * sin(B) * cos(B) * da
            + (pow(N, 2) / pow(a, 2) + 1) * N * sin(B) *
            cos(B) * de2 / 2 - (dx * cos(L) + dy * sin(L)) *
            sin(B) + dz * cos(B)) - wx * sin(L) * (1 + e2 *
            cos(2 * B)) + wy * cos(L) * (1 + e2 * cos(2 * B)) -
            ro * ms * e2 * sin(B) * cos(B)
        return result
    }

    // @param Bd latitude
    // @param Ld longitude
    // @param H height
    // @return
    
    static func dL(Bd: Double, Ld: Double, H: Double) -> Double {
        let B = Bd * .pi / 180
        let L = Ld * .pi / 180
        let N = a * pow((1 - e2 * pow(sin(B), 2)), -0.5)
        return ro / ((N + H) * cos(B)) * (-dx * sin(L) + dy * cos(L))
            + tan(B) * (1 - e2) * (wx * cos(L) + wy * sin(L)) - wz
    }

    // @param Bd latitude (CK-42)
    // @param Ld longitude (CK-42)
    // @param H height (CK-42)
    // @return height, in meters (WGS84)
    
    static func CK42_WGS84_Alt(Bd: Double, Ld: Double, H: Double) -> Double {
        let B = Bd * .pi / 180
        let L = Ld * .pi / 180
        let N = a * pow((1 - e2 * pow(sin(B), 2)), -0.5)
        let dH = -a / N * da + N * pow(sin(B), 2) * de2 / 2 +
            (dx * cos(L) + dy * sin(L)) *
            cos(B) + dz * sin(B) - N * e2 *
            sin(B) * cos(B) *
            (wx / ro * sin(L) - wy / ro * cos(L)) +
            (pow(a, 2) / N + H) * ms
        return H + dH
    }

    // Mathematical constants
    static let ro: Double = 206264.8062   // Number of arcseconds in radians

    // Krasovsky's ellipsoid
    static let aP: Double = 6378245

    // Krasovsky's ellipsoid continued
    static let alP: Double = 1 / 298.3
    static let e2P: Double = 2 * alP - pow(alP, 2)

    // WGS84 (GRS80) ellipsoid
    static let aW: Double = 6378137
    static let alW: Double = 1 / 298.257223563
    static let e2W: Double = 2 * alW - pow(alW, 2)

    // Auxiliary values for transforming ellipsoids
    static let a: Double = (aP + aW) / 2
    static let e2: Double = (e2P + e2W) / 2
    static let da: Double = aW - aP
    static let de2: Double = e2W - e2P

    // Linear transform elements, in meters
    static let dx: Double = 23.92
    static let dy: Double = -141.27
    static let dz: Double = -80.9

    // Corner transform elements, in seconds
    static let wx: Double = 0
    static let wy: Double = 0
    static let wz: Double = 0

    // Differential scale difference
    static let ms: Double = 0
    
    // end of WGS84 to CK42 code
    
} // Geodetic
