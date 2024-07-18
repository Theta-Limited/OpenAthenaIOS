// class Cubic.swift
// ported from OpenAthena Android by ChatGPT
// java package originally written by 
// package org.matthiaszimmermann.location.egm96;
// http://mrl.nyu.edu/~perlin/cubic/Cubic_java.html">http://mrl.nyu.edu/~perlin/cubic/Cubic_java.html
// Ken Perlin
// Copyright 2024, Theta Informatics LLC
// AGPLv3
// https://www.gnu.org/licenses/agpl-3.0.txt

class Cubic {
    static let BEZIER: [[Double]] = [      // Bezier basis matrix
        [-1  ,  3  , -3  , 1  ],
        [ 3  , -6  ,  3  , 0  ],
        [-3  ,  3  ,  0  , 0  ],
        [ 1  ,  0  ,  0  , 0  ]
    ]
    static let BSPLINE: [[Double]] = [     // BSpline basis matrix
        [-1.0/6,  3.0/6, -3.0/6, 1.0/6],
        [ 3.0/6, -6.0/6,  3.0/6, 0.0   ],
        [-3.0/6,  0.0   ,  3.0/6, 0.0   ],
        [ 1.0/6,  4.0/6,  1.0/6, 0.0   ]
    ]
    static let CATMULL_ROM: [[Double]] = [ // Catmull-Rom basis matrix
        [-0.5,  1.5, -1.5,  0.5],
        [ 1.0, -2.5,  2.0, -0.5],
        [-0.5,  0.0,  0.5,  0.0],
        [ 0.0,  1.0,  0.0,  0.0]
    ]
    static let HERMITE: [[Double]] = [     // Hermite basis matrix
        [ 2  , -2  ,  1  ,  1  ],
        [-3  ,  3  , -2  , -1  ],
        [ 0  ,  0  ,  1  ,  0  ],
        [ 1  ,  0  ,  0  ,  0  ]
    ]

    var a, b, c, d: Double                  // cubic coefficients vector

    init(matrix1D M: [[Double]], G: [Double]) {
        a = 0
        b = 0
        c = 0
        d = 0
        for k in 0..<4 {  // (a,b,c,d) = M G
            a += M[0][k] * G[k]
            b += M[1][k] * G[k]
            c += M[2][k] * G[k]
            d += M[3][k] * G[k]
        }
    }

    func eval(t: Double) -> Double {
        return t * (t * (t * a + b) + c) + d
    }

    var C = [[Double]](repeating: [Double](repeating: 0, count: 4), count: 4)    // bicubic coefficients matrix
    var T = [[Double]](repeating: [Double](repeating: 0, count: 4), count: 4)    // scratch matrix

    init(matrix2D M: [[Double]], G: [[Double]]) {
        // set a,b,c,d = 0.0 to get rid of compiler warning
        // not sure they are ever initialized
        a = 0.0
        b = 0.0
        c = 0.0
        d = 0.0
        
        for i in 0..<4 {
            for j in 0..<4 {
                for k in 0..<4 {
                    T[i][j] += G[i][k] * M[j][k]
                }
            }
        }

        for i in 0..<4 {
            for j in 0..<4 {
                for k in 0..<4 {
                    C[i][j] += M[i][k] * T[k][j]
                }
            }
        }
    }

    var C3: [Double] { return C[0] }
    var C2: [Double] { return C[1] }
    var C1: [Double] { return C[2] }
    var C0: [Double] { return C[3] }

    func eval(u: Double, v: Double) -> Double {
        return u * (u * (u * (v * (v * (v * C3[0] + C3[1]) + C3[2]) + C3[3])
                           + (v * (v * (v * C2[0] + C2[1]) + C2[2]) + C2[3]))
                           + (v * (v * (v * C1[0] + C1[1]) + C1[2]) + C1[3]))
                           + (v * (v * (v * C0[0] + C0[1]) + C0[2]) + C0[3])
    }
}
