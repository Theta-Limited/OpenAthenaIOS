// class EGM96Geoid.swift
// ported to Swift by ChatGPT-4
// originally from Java package
// org.matthiaszimmermann.location.egm96;
// make sure to include EGM96complete.dat[.gz]
// and GeoidHeights.dat[.gz] in the bundle
// so they can be read

// mods and tweaks by Matthew Krupczak, Bobby Krupczak

import Foundation
import Compression

class EGM96Geoid {

    static let OFFSET_INVALID = -9999.99
    static let OFFSET_MISSING = 9999.99

    static let ROWS = 719
    static let COLS = 1440

    static let LATITUDE_MAX = 90.0
    static let LATITUDE_MAX_GRID = 89.74
    static let LATITUDE_ROW_FIRST = 89.50
    static let LATITUDE_ROW_LAST = -89.50
    static let LATITUDE_MIN_GRID = -89.74
    static let LATITUDE_MIN = -90.0
    static let LATITUDE_STEP = 0.25

    static let LONGITUDE_MIN = 0.0
    static let LONGITUDE_MIN_GRID = 0.0
    static let LONGITUDE_MAX_GRID = 359.75
    static let LONGITUDE_MAX = 360.0
    static let LONGITUDE_STEP = 0.25

    static let INVALID_OFFSET = "-9999.99"
    static let COMMENT_PREFIX = "//"

    private static var offset = Array(repeating: Array(repeating: 0.0, count: COLS), count: ROWS)
    private static var offset_north_pole = 0.0
    private static var offset_south_pole = 0.0
    private static var s_model_ok = false

    // call this function to set up the model and load it into RAM
    static func initEGM96Geoid() -> Bool {
        if s_model_ok {
            return true
        }

        // EGM96complete.bin is gzip'd data file
        if let filePath = Bundle.main.path(forResource: "EGM96complete", ofType: "bin") {
            do {
                var fileData = try Data(contentsOf: URL(fileURLWithPath: filePath))
 
                print("initEGM96Geoid: read data of size \(fileData.count) bytes")

                // eat the first two bytes 0x78, 0x9c as a test as that might
                // be screwing up the zlib decompression
                
                // eat the first two bytes 0x78, 0x9c as a test
                // zlib on iOS may not like these two bytes? XXX
                
                fileData.removeFirst(2)
                
                // remove last 4 bytes which is a checksum
                fileData.removeLast(4)

                print("initEGM96Geoid: calling readEGM96GeoidOffsets with \(fileData.count) bytes")

                s_model_ok = readEGM96GeoidOffsets(data: fileData)
            } catch {
                s_model_ok = false
                print("Failed to read file: \(error)")
            }
        } else {
            s_model_ok = false
            print("File 'EGM96complete.dat' not found in the bundle.")
        }

        return s_model_ok
    }

    // return offset for lat/lng w/o caller creating EGM96Location object
    // too many location classes already :(
    
    static func getOffset(lat: Double, lng: Double) -> Double {
        return getOffset(location: EGM96Location(lat: lat, lng: lng))
    }
    
    static func getOffset(location: EGM96Location) -> Double {
        let lat = location.latitude
        let lng = location.longitude

        if latIsGridPoint(lat: lat) && lngIsGridPoint(lng: lng) {
            return getGridOffset(lat: lat, lng: lng)
        }

        var q = Array(repeating: Array(repeating: EGM96Location(), count: 4), count: 4)

        q[1][1] = getGridFloorLocation(lat: lat, lng: lng)
        q[1][2] = getUpperLocation(location: q[1][1])
        q[2][1] = getRightLocation(location: q[1][1])
        q[2][2] = getUpperLocation(location: q[2][1])

        if q[1][1].latitude >= LATITUDE_MIN_GRID && q[1][2].latitude <= LATITUDE_MAX_GRID {
            // left column
            q[0][1] = getLeftLocation(location: q[1][1])
            q[0][2] = getUpperLocation(location: q[0][1])
            q[0][3] = getUpperLocation(location: q[0][2])

            // top row
            q[1][3] = getRightLocation(location: q[0][3])
            q[2][3] = getRightLocation(location: q[1][3])
            q[3][3] = getRightLocation(location: q[2][3])

            // bottom row
            q[0][0] = getLowerLocation(location: q[0][1])
            q[1][0] = getRightLocation(location: q[0][0])
            q[2][0] = getRightLocation(location: q[1][0])

            // right column
            q[3][0] = getRightLocation(location: q[2][0])
            q[3][1] = getUpperLocation(location: q[3][0])
            q[3][2] = getUpperLocation(location: q[3][1])

            return bicubicSplineInterpolation(target: location, grid: q)
        } else {
            return bilinearInterpolation(target: location, q11: q[1][1], q12: q[1][2], q21: q[2][1], q22: q[2][2])
        }
    }

    static func bilinearInterpolation(target: EGM96Location, q11: EGM96Location, q12: EGM96Location, q21: EGM96Location, q22: EGM96Location) -> Double {
        let fq11 = getGridOffset(location: q11)
        let fq12 = getGridOffset(location: q12)
        let fq21 = getGridOffset(location: q21)
        let fq22 = getGridOffset(location: q22)

        let x1 = q11.longitude
        var x2 = q22.longitude
        let y1 = q22.latitude
        let y2 = q11.latitude

        if x1 == 359.75 && x2 == 0.0 {
            x2 = 360.0
        }

        let x = target.longitude
        let y = target.latitude

        let f11 = fq11 * (x2 - x) * (y2 - y)
        let f12 = fq12 * (x2 - x) * (y - y1)
        let f21 = fq21 * (x - x1) * (y2 - y)
        let f22 = fq22 * (x - x1) * (y - y1)

        return (f11 + f12 + f21 + f22) / ((x2 - x1) * (y2 - y1))
    }

    static func bicubicSplineInterpolation(target: EGM96Location, grid: [[EGM96Location]]) -> Double {
        var G = Array(repeating: Array(repeating: 0.0, count: 4), count: 4)

        for i in 0..<4 {
            for j in 0..<4 {
                G[i][j] = getGridOffset(location: grid[i][j])
            }
        }

        let u1 = grid[1][1].latitude
        let v1 = grid[1][1].longitude

        let u = (target.latitude - u1 + LATITUDE_STEP) / (4 * LATITUDE_STEP)
        let v = (target.longitude - v1 + LONGITUDE_STEP) / (4 * LONGITUDE_STEP)

        let c = Cubic( matrix2D: Cubic.BEZIER, G: G)

        return c.eval(u: u, v: v)
    }

    static func getUpperLocation(location: EGM96Location) -> EGM96Location {
        var lat = location.latitude
        let lng = location.longitude

        if lat == LATITUDE_MAX_GRID {
            lat = LATITUDE_MAX
        } else if lat == LATITUDE_ROW_FIRST {
            lat = LATITUDE_MAX_GRID
        } else if lat == LATITUDE_MIN {
            lat = LATITUDE_MIN_GRID
        } else if lat == LATITUDE_MIN_GRID {
            lat = LATITUDE_ROW_LAST
        } else {
            lat += LATITUDE_STEP
        }

        return EGM96Location(lat: lat, lng: lng)
    }

    static func getLowerLocation(location: EGM96Location) -> EGM96Location {
        var lat = location.latitude
        let lng = location.longitude

        if lat == LATITUDE_MIN_GRID {
            lat = LATITUDE_MIN
        } else if lat == LATITUDE_ROW_FIRST {
            lat = LATITUDE_MIN_GRID
        } else if lat == LATITUDE_MAX {
            lat = LATITUDE_MAX_GRID
        } else if lat == LATITUDE_MAX_GRID {
            lat = LATITUDE_ROW_FIRST
        } else {
            lat -= LATITUDE_STEP
        }

        return EGM96Location(lat: lat, lng: lng)
    }

    static func getLeftLocation(location: EGM96Location) -> EGM96Location {
        let lat = location.latitude
        var lng = location.longitude

        lng -= LONGITUDE_STEP

        return EGM96Location(lat: lat, lng: lng)
    }

    static func getRightLocation(location: EGM96Location) -> EGM96Location {
        let lat = location.latitude
        var lng = location.longitude

        lng += LONGITUDE_STEP

        return EGM96Location(lat: lat, lng: lng)
    }

    static func getGridFloorLocation(lat: Double, lng: Double) -> EGM96Location {
        let floor = EGM96Location(lat: lat, lng: lng).floorLocation(step: LATITUDE_STEP)
        var latFloor = floor.latitude

        if lat >= LATITUDE_MAX_GRID && lat < LATITUDE_MAX {
            latFloor = LATITUDE_MAX_GRID
        } else if lat < LATITUDE_MIN_GRID {
            latFloor = LATITUDE_MIN
        } else if lat < LATITUDE_ROW_LAST {
            latFloor = LATITUDE_MIN_GRID
        }

        return EGM96Location(lat: latFloor, lng: floor.longitude)
    }

    static func getGridOffset(location: EGM96Location) -> Double {
        return getGridOffset(lat: location.latitude, lng: location.longitude)
    }

    static func getGridOffset(lat: Double, lng: Double) -> Double {
        if !s_model_ok {
            return OFFSET_INVALID
        }

        if !latIsGridPoint(lat: lat) || !lngIsGridPoint(lng: lng) {
            return OFFSET_INVALID
        }

        if latIsPole(lat: lat) {
            if lat == LATITUDE_MAX {
                return offset_north_pole
            } else {
                return offset_south_pole
            }
        }

        let i = latToI(lat: lat)
        let j = lngToJ(lng: lng)

        return offset[i][j]
    }

    // handle reading with dos \r\n In this version, the lines are
    // split based on the DOS carriage return (\r) character, and each
    // line is trimmed of any leading or trailing newlines.
    
    
    private static func readEGM96GeoidOffsets(data: Data) -> Bool {
        assignMissingOffsets()

        var decompressedData: Data
        do {
            print("Uncompressing \(data.count) bytes")
            print("First few bytes \(data.bytes[0..<10])")
            
            
            
            decompressedData = try (data as NSData).decompressed(using: .zlib) as Data
            print("Decompression returned \(decompressedData.count) bytes")
            
        } catch {
            print("Failed to decompress data: \(error)")
            return false
        }
        
        // print first few bytes of decompressed data
        print("First few uncompressed bytes \(decompressedData.bytes[0..<10])")

        let lines = decompressedData.split(separator: 13) // 13 is the ASCII code for carriage return (\r)

        for line in lines {
            let lineString = String(data: line, encoding: .utf8)?.trimmingCharacters(in: .newlines) ?? ""

            if lineIsOk(line: lineString) {

                let tokens = lineString.split(separator: " ")
                if tokens.count != 3 {
                    print("Error: Found \(tokens.count) tokens on line: \(lineString)")
                }

                if let lat = Double(tokens[0]), let lng = Double(tokens[1]), let off = Double(tokens[2]) {
                    if latLongOk(lat: lat, lng: lng) {
                        var i_lat = 0
                        var j_lng = 0

                        if lat == LATITUDE_MAX {
                            offset_north_pole = off
                        } else if lat == LATITUDE_MIN {
                            offset_south_pole = off
                        } else {
                            if lat == LATITUDE_MAX_GRID {
                                i_lat = 0
                            } else if lat == LATITUDE_MIN_GRID {
                                i_lat = ROWS - 1
                            } else {
                                i_lat = Int((LATITUDE_MAX - lat) / LATITUDE_STEP) - 1
                            }

                            j_lng = Int(lng / LONGITUDE_STEP)

                            offset[i_lat][j_lng] = off
                        }
                    }
                } else {
                    print("Error parsing line: \(lineString)")
                }
            }
        }

        return !hasMissingOffsets()
    }
    
    private static func readEGM96GeoidOffsetsUNIX(data: Data) -> Bool {
        assignMissingOffsets()

        let decompressedData: Data
        do {
            
            decompressedData = try (data as NSData).decompressed(using: .zlib) as Data
            
        } catch {
            print("Failed to decompress data: \(error)")
            return false
        }

        let lines = decompressedData.split(separator: 10) // 10 is the ASCII code for line feed (\n)

        for line in lines {
            let lineString = String(data: line, encoding: .utf8) ?? ""

            if lineIsOk(line: lineString) {
                let tokens = lineString.split(separator: " ")
                if tokens.count != 3 {
                    print("Error: Found \(tokens.count) tokens on line: \(lineString)")
                }

                if let lat = Double(tokens[0]), let lng = Double(tokens[1]), let off = Double(tokens[2]) {
                    if latLongOk(lat: lat, lng: lng) {
                        var i_lat = 0
                        var j_lng = 0

                        if lat == LATITUDE_MAX {
                            offset_north_pole = off
                        } else if lat == LATITUDE_MIN {
                            offset_south_pole = off
                        } else {
                            if lat == LATITUDE_MAX_GRID {
                                i_lat = 0
                            } else if lat == LATITUDE_MIN_GRID {
                                i_lat = ROWS - 1
                            } else {
                                i_lat = Int((LATITUDE_MAX - lat) / LATITUDE_STEP) - 1
                            }

                            j_lng = Int(lng / LONGITUDE_STEP)

                            offset[i_lat][j_lng] = off
                        }
                    }
                } else {
                    print("Error parsing line: \(lineString)")
                }
            }
        }

        return !hasMissingOffsets()
    }

    private static func lineIsOk(line: String) -> Bool {
        if line.hasPrefix(COMMENT_PREFIX) {
            return false
        }

        if line.hasSuffix(INVALID_OFFSET) {
            return false
        }
        
        // eat blank links or lines with space at beginning -- rdk
        if line.isEmpty {
            return false
        }

        return true
    }

    private static func assignMissingOffsets() {
        offset_north_pole = OFFSET_MISSING
        offset_south_pole = OFFSET_MISSING

        for i in 0..<ROWS {
            for j in 0..<COLS {
                offset[i][j] = OFFSET_MISSING
            }
        }
    }

    private static func hasMissingOffsets() -> Bool {
        if offset_north_pole == OFFSET_MISSING { return true }
        if offset_south_pole == OFFSET_MISSING { return true }

        for i in 0..<ROWS {
            for j in 0..<COLS {
                if offset[i][j] == OFFSET_MISSING {
                    return true
                }
            }
        }

        return false
    }

    // ChatGPT forgot to include this function!
    // ChatGPT botched line arg so we dropped it; only used for error printing
    
    private static func latLongOk(lat: Double, lng: Double) -> Bool
    {
        if latOk(lat: lat) == false {
            return false
        }
        if lngOkGrid(lng: lng) == false {
            return false
        }
        return true
    }
    
    private static func latOk(lat: Double) -> Bool {
        let lat_in_bounds = lat >= LATITUDE_MIN && lat <= LATITUDE_MAX
        return lat_in_bounds
    }

    private static func lngOk(lng: Double) -> Bool {
        let lng_in_bounds = lng >= LONGITUDE_MIN && lng <= LONGITUDE_MAX
        return lng_in_bounds
    }

    private static func lngOkGrid(lng: Double) -> Bool {
        let lng_in_bounds = lng >= LONGITUDE_MIN_GRID && lng <= LONGITUDE_MAX_GRID
        return lng_in_bounds
    }

    private static func latIsGridPoint(lat: Double) -> Bool {
        if !latOk(lat: lat) {
            return false
        }

        if latIsPole(lat: lat) {
            return true
        }

        if lat == LATITUDE_MAX_GRID || lat == LATITUDE_MIN_GRID {
            return true
        }

        if lat <= LATITUDE_ROW_FIRST && lat >= LATITUDE_ROW_LAST && lat / LATITUDE_STEP == Double(Int(lat / LATITUDE_STEP)) {
            return true
        }

        return false
    }

    private static func lngIsGridPoint(lng: Double) -> Bool {
        if !lngOkGrid(lng: lng) {
            return false
        }

        if lng / LONGITUDE_STEP == Double(Int(lng / LONGITUDE_STEP)) {
            return true
        }

        return false
    }

    private static func latIsPole(lat: Double) -> Bool {
        return lat == LATITUDE_MAX || lat == LATITUDE_MIN
    }

    private static func latToI(lat: Double) -> Int {
        if lat == LATITUDE_MAX_GRID { return 0 }
        if lat == LATITUDE_MIN_GRID { return ROWS - 1 }
        return Int((LATITUDE_ROW_FIRST - lat) / LATITUDE_STEP) + 1
    }

    private static func lngToJ(lng: Double) -> Int {
        return Int(lng / LONGITUDE_STEP)
    }

} // EGM96Geoid
