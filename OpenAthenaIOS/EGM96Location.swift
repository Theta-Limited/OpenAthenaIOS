// class EGM96Location (need to rename)
// originally contained in package
// java package org.matthiaszimmermann.location;
// ported to swift by ChatGPT-3.5

import Foundation
import Darwin

public class EGM96Location {
    // TODO verify if this is meaningful (eg. if this is sufficient for cm accuracy on earth)
    public static let EPSILON: Double = 0.00000001
    
    public static let LATITUDE_MIN_STRICT: Double = -90.0
    public static let LATITUDE_MAX_STRICT: Double = 90.0
    
    public static let LONGITUDE_MIN_STRICT: Double = 0.0
    public static let LONGITUDE_MAX_STRICT: Double = 360.0
    
    public var m_lat: Double = 0.0
    public var m_lng: Double = 0.0
    
    convenience init() {
        self.init(lat: 0.0, lng: 0.0, lenient: true)
    }
    
    convenience init(lat: Double, lng: Double) {
        self.init( lat: lat, lng: lng, lenient: true)
    }
    
    //convenience init(lat: Double, lng: Double, lenient: Bool) {
    //    self.init_model( lat: lat, lng: lng, lenient: lenient)
    //}
    
    init(lat: Double, lng: Double, lenient: Bool)
    {        
        if lenient {
            self.m_lat = normalizeLat(lat)
            self.m_lng = normalizeLong(lng)
        } else {
            if lat < EGM96Location.LATITUDE_MIN_STRICT || lat > EGM96Location.LATITUDE_MAX_STRICT {
                fatalError("latitude out of bounds [\(EGM96Location.LATITUDE_MIN_STRICT),\(EGM96Location.LATITUDE_MAX_STRICT)]")
            }
            
            if lng < EGM96Location.LONGITUDE_MIN_STRICT || lng >= EGM96Location.LONGITUDE_MAX_STRICT {
                fatalError("longitude out of bounds [\(EGM96Location.LONGITUDE_MIN_STRICT),\(EGM96Location.LONGITUDE_MAX_STRICT))")
            }
            
            self.m_lat = lat
            self.m_lng = lng
        }

    }
    
    public var latitude: Double {
        return m_lat
    }
    public var longitude: Double {
        return m_lng
    }
    
    private func normalizeLat(_ lat: Double) -> Double {
        if lat > 90.0 {
            return normalizeLatPositive(lat)
        } else if lat < -90.0 {
            return -normalizeLatPositive(-lat)
        }
        
        return lat
    }
    
    private func normalizeLatPositive(_ lat: Double) -> Double {
        let delta = (lat - 90.0).truncatingRemainder(dividingBy: 360.0)
        
        if delta <= 180.0 {
            return 90.0 - delta
        } else {
            return delta - 270.0
        }
    }
    
    private func normalizeLong(_ lng: Double) -> Double {
        let normalizedLng = lng.truncatingRemainder(dividingBy: 360.0)
        
        if normalizedLng >= 0.0 {
            return normalizedLng
        } else {
            return normalizedLng + 360.0
        }
    }
    
    public static func ==(lhs: EGM96Location, rhs: EGM96Location) -> Bool {
        return abs(lhs.latitude - rhs.latitude) <= EPSILON && abs(lhs.longitude - rhs.longitude) <= EPSILON
    }
    
    public func floorLocation(step: Double) -> EGM96Location {
        guard step > 0.0 && step <= 1.0 else {
            fatalError("precision out of bounds (0,1]")
        }
        
        let latFloor = floor(latitude / step) * step
        let lngFloor = floor(longitude / step) * step
        
        return EGM96Location(lat: latFloor, lng: lngFloor)
    }

} // EGM96Location

