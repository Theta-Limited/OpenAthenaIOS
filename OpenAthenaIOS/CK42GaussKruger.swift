//
//  CK42GaussKruger.swift
//  OpenAthenaIOS
//
//  Created by Bobby Krupczak on 4/19/23.
//
//  Code adapted from https://gis.stackexchange.com/a/418152/205005 user Nickname Nick
//  Modified by mkrupczak3 for use with OpenAthena
//  Ported to Swift by ChatGPT
//  Enhanced by rdk for convenience functions, comments, etc.
//

import Foundation

class CK42GaussKruger {
    
    // Parameters of the Krasovsky ellipsoid
    static let a = CK42Geodetic.aP
    static let b = 6356863.019
    static let e2 = (pow(a, 2) - pow(b, 2)) / pow(a, 2)
    static let n = (a - b) / (a + b)

    // Parameters of the Gauss-Kruger zone
    static let F = 1.0
    static let Lat0 = 0.0

    static func CK42_to_GaussKruger(CK42_LatDegrees: Double,
                                    CK42_LonDegrees: Double) -> (Int64,Int64)
    {
        var CK42_LonDegrees = CK42_LonDegrees

        while CK42_LonDegrees < 0 {
            CK42_LonDegrees += 360
        }
        while CK42_LonDegrees >= 360 {
            CK42_LonDegrees -= 360
        }

        let zone = Int(CK42_LonDegrees / 6 + 1)
        let Lon0 = (Double(zone) * 6 - 3) * Double.pi / 180
        let N0 = 0.0
        let E0 = Double(zone) * 1e6 + 500000.0

        let Lat = CK42_LatDegrees * Double.pi / 180.0
        let Lon = CK42_LonDegrees * Double.pi / 180.0

        let sinLat = sin(Lat)
        let cosLat = cos(Lat)
        let tanLat = tan(Lat)

        let v = a * F * pow(1 - e2 * pow(sinLat, 2), -0.5)
        let p = a * F * (1 - e2) * pow(1 - e2 * pow(sinLat, 2), -1.5)
        let n2 = v / p - 1
        let M1 = (1 + n + 5.0 / 4.0 * pow(n, 2) + 5.0 / 4.0 * pow(n, 3)) * (Lat - Lat0)
        let M2 = (3 * n + 3 * pow(n, 2) + 21.0 / 8.0 * pow(n, 3)) * sin(Lat - Lat0) * cos(Lat + Lat0)
        let M3 = (15.0 / 8.0 * pow(n, 2) + 15.0 / 8.0 * pow(n, 3)) * sin(2 * (Lat - Lat0)) * cos(2 * (Lat + Lat0))
        let M4 = 35.0 / 24.0 * pow(n, 3) * sin(3 * (Lat - Lat0)) * cos(3 * (Lat + Lat0))
        let M = b * F * (M1 - M2 + M3 - M4)
        let I = M + N0
        let II = v / 2 * sinLat * cosLat
        let III = v / 24 * sinLat * pow(cosLat, 3) * (5 - pow(tanLat, 2) + 9 * n2)
        let IIIA = v / 720 * sinLat * pow(cosLat, 5) * (61 - 58 * pow(tanLat, 2) + pow(tanLat, 4))
        let IV = v * cosLat
        let V = v / 6 * pow(cosLat, 3) * (v / p - pow(tanLat, 2))
        let VI = v / 120 * pow(cosLat, 5) * (5 - 18 * pow(tanLat, 2) + pow(tanLat, 4) + 14 * n2 - 58 * pow(tanLat, 2) * n2)

        let N = I + II * pow(Lon - Lon0, 2) + III * pow(Lon - Lon0, 4) + IIIA * pow(Lon - Lon0, 6)
        let E = E0 + IV * (Lon - Lon0) + V * pow(Lon - Lon0, 3) + VI * pow(Lon - Lon0, 5)

        return (Int64(N), Int64(E))
    }
    
} // CK42GaussKruger
