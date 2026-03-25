//
//  DiceFaceNormals.swift
//  zaruri
//

import simd

/// Precomputed outward face normals for each DiceType.
/// Used to snap a die's orientation so the face showing the correct value points upward after physics settles.
/// Each normal at index i corresponds to the face that displays value (i+1).
/// Geometry matches exactly what DiceMeshProvider generates.
enum DiceFaceNormals {

    /// Returns the outward face normal (in the die's local coordinate system) for the face
    /// that displays `value`. Rotating the die so this normal aligns with world +Y causes
    /// the correct value to appear face-up.
    static func faceUpNormal(for type: DiceType, value: Int) -> SIMD3<Float> {
        let idx = value - 1
        let normals = allNormals(for: type)
        guard idx >= 0 && idx < normals.count else { return SIMD3(0, 1, 0) }
        return normals[idx]
    }

    // MARK: - Cache

    private static var cache: [DiceType: [SIMD3<Float>]] = [:]

    private static func allNormals(for type: DiceType) -> [SIMD3<Float>] {
        if let cached = cache[type] { return cached }
        let result = computeNormals(for: type)
        cache[type] = result
        return result
    }

    // MARK: - Per-type Normal Computation

    private static func computeNormals(for type: DiceType) -> [SIMD3<Float>] {
        switch type {
        case .d2:  return d2Normals()
        case .d4:  return d4Normals()
        case .d6:  return d6Normals()
        case .d8:  return d8Normals()
        case .d10: return d10Normals()
        case .d12: return d12Normals()
        case .d20: return d20Normals()
        case .d3:  return []
        }
    }

    /// d2 coin — top cap (value 1) normal = +Y; bottom cap (value 2) normal = −Y.
    private static func d2Normals() -> [SIMD3<Float>] {
        [SIMD3(0, 1, 0), SIMD3(0, -1, 0)]
    }

    /// d4 tetrahedron — matches DiceMeshProvider.tetrahedronMesh() vertex/index layout.
    private static func d4Normals() -> [SIMD3<Float>] {
        let v: [SIMD3<Float>] = [
            normalize(SIMD3( 1,  1,  1)),
            normalize(SIMD3(-1, -1,  1)),
            normalize(SIMD3(-1,  1, -1)),
            normalize(SIMD3( 1, -1, -1))
        ]
        // sharedIndices from DiceMeshProvider: [0,2,1], [0,1,3], [0,3,2], [1,2,3]
        let faceVerts: [[Int]] = [[0,2,1], [0,1,3], [0,3,2], [1,2,3]]
        return faceVerts.map { idx in normalize(v[idx[0]] + v[idx[1]] + v[idx[2]]) }
    }

    /// d6 cube — face order from cubeMesh(): top(1), front(2), right(3), left(4), back(5), bottom(6).
    private static func d6Normals() -> [SIMD3<Float>] {
        [
            SIMD3( 0,  1,  0),  // value 1: +Y top
            SIMD3( 0,  0,  1),  // value 2: +Z front
            SIMD3( 1,  0,  0),  // value 3: +X right
            SIMD3(-1,  0,  0),  // value 4: -X left
            SIMD3( 0,  0, -1),  // value 5: -Z back
            SIMD3( 0, -1,  0),  // value 6: -Y bottom
        ]
    }

    /// d8 octahedron — matches DiceMeshProvider.octahedronMesh() vertex/index layout.
    private static func d8Normals() -> [SIMD3<Float>] {
        let v: [SIMD3<Float>] = [
            SIMD3( 1, 0, 0), SIMD3(-1, 0, 0),
            SIMD3( 0, 1, 0), SIMD3( 0,-1, 0),
            SIMD3( 0, 0, 1), SIMD3( 0, 0,-1)
        ]
        // sharedIndices: [0,2,4],[0,4,3],[0,3,5],[0,5,2],[1,4,2],[1,3,4],[1,5,3],[1,2,5]
        let faceVerts: [[Int]] = [
            [0,2,4], [0,4,3], [0,3,5], [0,5,2],
            [1,4,2], [1,3,4], [1,5,3], [1,2,5]
        ]
        return faceVerts.map { idx in normalize(v[idx[0]] + v[idx[1]] + v[idx[2]]) }
    }

    /// d10 pentagonal bipyramid — matches DiceMeshProvider.bipyramidMesh() layout.
    /// Faces are interleaved: top0, bot0, top1, bot1, ..., top4, bot4.
    private static func d10Normals() -> [SIMD3<Float>] {
        let n = 5
        let eq: [SIMD3<Float>] = (0..<n).map { i in
            let angle = Float(i) / Float(n) * 2 * .pi + .pi / Float(n)
            return SIMD3(cos(angle) * 0.60, 0, sin(angle) * 0.60)
        }
        let top = SIMD3<Float>(0,  0.65, 0)
        let bot = SIMD3<Float>(0, -0.65, 0)
        var normals: [SIMD3<Float>] = []
        for i in 0..<n {
            let a = i, b = (i + 1) % n
            normals.append(normalize(top + eq[a] + eq[b]))  // top face (even index)
            normals.append(normalize(bot + eq[b] + eq[a]))  // bottom face (odd index)
        }
        return normals
    }

    /// d12 dodecahedron — matches DiceMeshProvider.dodecahedronMesh() vertex/face layout.
    private static func d12Normals() -> [SIMD3<Float>] {
        let φ: Float = (1 + sqrt(5.0)) / 2
        let a: Float = 1 / φ
        let vRaw: [SIMD3<Float>] = [
            SIMD3( 1,  1,  1), SIMD3( 1,  1,-1), SIMD3( 1,-1,  1), SIMD3( 1,-1,-1),
            SIMD3(-1,  1,  1), SIMD3(-1,  1,-1), SIMD3(-1,-1,  1), SIMD3(-1,-1,-1),
            SIMD3( 0,  a,  φ), SIMD3( 0, -a,  φ), SIMD3( 0,  a, -φ), SIMD3( 0, -a,-φ),
            SIMD3( a,  φ,  0), SIMD3(-a,  φ,  0), SIMD3( a, -φ,  0), SIMD3(-a, -φ,  0),
            SIMD3( φ,  0,  a), SIMD3( φ,  0, -a), SIMD3(-φ,  0,  a), SIMD3(-φ,  0, -a)
        ]
        let v = vRaw.map { normalize($0) }
        let faces: [[Int]] = [
            [0, 8, 9, 2,16], [0,16,17, 1,12], [0,12,13, 4, 8],
            [5,13,12, 1,10], [1,17, 3,11,10], [3,17,16, 2,14],
            [2, 9, 6,15,14], [6, 9, 8, 4,18], [4,13, 5,19,18],
            [7,19, 5,10,11], [7,11, 3,14,15], [7,15, 6,18,19]
        ]
        return faces.map { face in
            let sum = face.reduce(SIMD3<Float>.zero) { $0 + v[$1] }
            return normalize(sum)
        }
    }

    /// d20 icosahedron — matches DiceMeshProvider.icosahedronMesh() vertex/index layout.
    private static func d20Normals() -> [SIMD3<Float>] {
        let φ: Float = (1 + sqrt(5.0)) / 2
        let v: [SIMD3<Float>] = [
            SIMD3( 0,  1,  φ), SIMD3( 0, -1,  φ), SIMD3( 0,  1, -φ), SIMD3( 0, -1, -φ),
            SIMD3( 1,  φ,  0), SIMD3(-1,  φ,  0), SIMD3( 1, -φ,  0), SIMD3(-1, -φ,  0),
            SIMD3( φ,  0,  1), SIMD3(-φ,  0,  1), SIMD3( φ,  0, -1), SIMD3(-φ,  0, -1)
        ].map { normalize($0) }
        let faceVerts: [[Int]] = [
            [0,1,8], [0,8,4], [0,4,5], [0,5,9], [0,9,1],
            [3,2,10],[3,10,6],[3,6,7], [3,7,11],[3,11,2],
            [1,6,8], [8,6,10],[8,10,4],[4,10,2],[4,2,5],
            [5,2,11],[5,11,9],[9,11,7],[9,7,1], [1,7,6]
        ]
        return faceVerts.map { idx in normalize(v[idx[0]] + v[idx[1]] + v[idx[2]]) }
    }
}
