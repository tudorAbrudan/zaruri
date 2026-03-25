//
//  DiceMeshProvider.swift
//  zaruri
//

import RealityKit
import simd

/// Generates RealityKit MeshResource for each DiceType.
/// Meshes for d4/d6/d8/d10/d12/d20 use unshared vertices with UV coordinates
/// and per-face material indices so each face can display a distinct number texture.
/// Material index i corresponds to the face that shows number (i+1).
///
/// d2 (coin) uses 3 material slots: 0=rim, 1=top-cap("1"), 2=bottom-cap("2").
enum DiceMeshProvider {

    static func mesh(for type: DiceType) throws -> MeshResource {
        switch type {
        case .d2:  return try coinMesh()
        case .d3:  return try cubeMesh()    // cube with faces labeled 1–3
        case .d4:  return try tetrahedronMesh()
        case .d6:  return try cubeMesh()
        case .d8:  return try octahedronMesh()
        case .d10: return try bipyramidMesh()
        case .d12: return try dodecahedronMesh()
        case .d20: return try icosahedronMesh()
        }
    }

    // MARK: - d2 Coin (cylinder with 3 material slots: rim, top cap, bottom cap)

    private static func coinMesh() throws -> MeshResource {
        let segments = 32
        let h: Float = 0.05   // half-height (total thickness 0.10 — thin coin, avoids landing on edge)
        let r: Float = 0.50   // radius

        var positions: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        var matIdx: [UInt32] = []

        // ── RIM (material 0): quad strip around the curved side ──────────────
        for i in 0..<segments {
            let a0 = Float(i)     / Float(segments) * 2 * .pi
            let a1 = Float(i + 1) / Float(segments) * 2 * .pi
            let x0 = cos(a0) * r, z0 = sin(a0) * r
            let x1 = cos(a1) * r, z1 = sin(a1) * r

            let base = UInt32(positions.count)
            positions += [
                SIMD3(x0,  h, z0),   // top-left
                SIMD3(x1,  h, z1),   // top-right
                SIMD3(x1, -h, z1),   // bottom-right
                SIMD3(x0, -h, z0)    // bottom-left
            ]
            let u0 = Float(i)     / Float(segments)
            let u1 = Float(i + 1) / Float(segments)
            uvs += [SIMD2(u0, 0), SIMD2(u1, 0), SIMD2(u1, 1), SIMD2(u0, 1)]
            indices += [base, base+1, base+2,  base, base+2, base+3]
            matIdx  += [0, 0]
        }

        // ── TOP CAP (material 1): fan from centre pointing +Y ─────────────────
        // Winding [centre, p1, p0] → (B-A)×(C-A) = +Y, face visible from above.
        let topCentre = SIMD3<Float>(0, h, 0)
        for i in 0..<segments {
            let a0 = Float(i)     / Float(segments) * 2 * .pi
            let a1 = Float(i + 1) / Float(segments) * 2 * .pi
            let x0 = cos(a0) * r, z0 = sin(a0) * r
            let x1 = cos(a1) * r, z1 = sin(a1) * r

            let base = UInt32(positions.count)
            positions += [topCentre, SIMD3(x1, h, z1), SIMD3(x0, h, z0)]
            // UV: flip U to compensate for reversed winding so number reads correctly.
            uvs += [
                SIMD2(0.5, 0.5),
                SIMD2(-cos(a1) / 2 + 0.5, sin(a1) / 2 + 0.5),
                SIMD2(-cos(a0) / 2 + 0.5, sin(a0) / 2 + 0.5)
            ]
            indices += [base, base+1, base+2]
            matIdx.append(1)
        }

        // ── BOTTOM CAP (material 2): fan from centre pointing −Y ──────────────
        // Winding [centre, p0, p1] → (B-A)×(C-A) = −Y, face visible from below.
        let botCentre = SIMD3<Float>(0, -h, 0)
        for i in 0..<segments {
            let a0 = Float(i)     / Float(segments) * 2 * .pi
            let a1 = Float(i + 1) / Float(segments) * 2 * .pi
            let x0 = cos(a0) * r, z0 = sin(a0) * r
            let x1 = cos(a1) * r, z1 = sin(a1) * r

            let base = UInt32(positions.count)
            positions += [botCentre, SIMD3(x0, -h, z0), SIMD3(x1, -h, z1)]
            uvs += [
                SIMD2(0.5, 0.5),
                SIMD2(cos(a0) / 2 + 0.5, sin(a0) / 2 + 0.5),
                SIMD2(cos(a1) / 2 + 0.5, sin(a1) / 2 + 0.5)
            ]
            indices += [base, base+1, base+2]
            matIdx.append(2)
        }

        return try buildMeshWithUVs(name: "d2", positions: positions, uvs: uvs,
                                    indices: indices, matIndices: matIdx)
    }

    // MARK: - d4 Tetrahedron (4 triangular faces)

    private static func tetrahedronMesh() throws -> MeshResource {
        let shared: [SIMD3<Float>] = [
            normalize(SIMD3( 1,  1,  1)),
            normalize(SIMD3(-1, -1,  1)),
            normalize(SIMD3(-1,  1, -1)),
            normalize(SIMD3( 1, -1, -1))
        ]
        let sharedIndices: [UInt32] = [
            0, 2, 1,
            0, 1, 3,
            0, 3, 2,
            1, 2, 3
        ]
        // Standard UV triangle with centroid at (0.5, 0.5) so the single winning number
        // texture renders at the visual centre of the face.
        let d4UVs: [SIMD2<Float>] = [SIMD2(0.50, 0.07), SIMD2(0.13, 0.72), SIMD2(0.87, 0.72)]
        return try triangularFaceMesh(name: "d4", shared: shared, sharedIndices: sharedIndices, faceUVs: d4UVs)
    }

    // MARK: - d6 Cube (6 quad faces)

    private static func cubeMesh() throws -> MeshResource {
        let s: Float = 0.45
        // Faces listed so that correct outward normals result from (0,1,2),(0,2,3) winding.
        // Order: top(1), front(2), right(3), left(4), back(5), bottom(6)
        let faceVerts: [[SIMD3<Float>]] = [
            [SIMD3(-s, s, s), SIMD3(s, s, s), SIMD3(s, s,-s), SIMD3(-s, s,-s)],   // +Y top
            [SIMD3(-s,-s, s), SIMD3(s,-s, s), SIMD3(s, s, s), SIMD3(-s, s, s)],   // +Z front
            [SIMD3( s,-s, s), SIMD3(s,-s,-s), SIMD3(s, s,-s), SIMD3(s,  s, s)],   // +X right
            [SIMD3(-s,-s,-s), SIMD3(-s,-s,s), SIMD3(-s,s, s), SIMD3(-s, s,-s)],   // -X left
            [SIMD3( s,-s,-s), SIMD3(-s,-s,-s),SIMD3(-s, s,-s),SIMD3( s, s,-s)],   // -Z back
            [SIMD3(-s,-s,-s), SIMD3(s,-s,-s), SIMD3(s,-s, s), SIMD3(-s,-s, s)],   // -Y bottom
        ]
        let quadUVs: [SIMD2<Float>] = [SIMD2(0,0), SIMD2(1,0), SIMD2(1,1), SIMD2(0,1)]

        var positions: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        var matIdx: [UInt32] = []

        for (face, verts) in faceVerts.enumerated() {
            let base = UInt32(positions.count)
            positions.append(contentsOf: verts)
            uvs.append(contentsOf: quadUVs)
            indices += [base, base+1, base+2,  base, base+2, base+3]
            matIdx  += [UInt32(face), UInt32(face)]
        }
        return try buildMeshWithUVs(name: "d6", positions: positions, uvs: uvs,
                                    indices: indices, matIndices: matIdx)
    }

    // MARK: - d8 Octahedron (8 triangular faces)

    private static func octahedronMesh() throws -> MeshResource {
        let shared: [SIMD3<Float>] = [
            SIMD3( 1, 0, 0), SIMD3(-1, 0, 0),
            SIMD3( 0, 1, 0), SIMD3( 0,-1, 0),
            SIMD3( 0, 0, 1), SIMD3( 0, 0,-1)
        ]
        let sharedIndices: [UInt32] = [
            0, 2, 4,   0, 4, 3,
            0, 3, 5,   0, 5, 2,
            1, 4, 2,   1, 3, 4,
            1, 5, 3,   1, 2, 5
        ]
        // d8 winding produces mirrored UVs relative to the default — swap left/right to correct.
        let d8UVs: [SIMD2<Float>] = [SIMD2(0.50, 0.07), SIMD2(0.87, 0.72), SIMD2(0.13, 0.72)]
        return try triangularFaceMesh(name: "d8", shared: shared, sharedIndices: sharedIndices, faceUVs: d8UVs)
    }

    // MARK: - d10 Bipyramid (10 triangular faces)

    private static func bipyramidMesh() throws -> MeshResource {
        let n = 5
        let eqRadius: Float = 0.60   // wider equatorial belt → less "rugby ball", more visible faces
        let poleHeight: Float = 0.65 // shorter poles → fatter overall shape
        var shared: [SIMD3<Float>] = (0..<n).map { i in
            let angle = Float(i) / Float(n) * 2 * .pi + .pi / Float(n)
            return SIMD3(cos(angle) * eqRadius, 0, sin(angle) * eqRadius)
        }
        let topIdx = UInt32(shared.count); shared.append(SIMD3(0,  poleHeight, 0))
        let botIdx = UInt32(shared.count); shared.append(SIMD3(0, -poleHeight, 0))

        var sharedIndices: [UInt32] = []
        for i in 0..<n {
            let a = UInt32(i), b = UInt32((i + 1) % n)
            sharedIndices += [topIdx, a, b]
            sharedIndices += [botIdx, b, a]
        }
        // Swap L/R UVs (same fix as d8/d20) to correct mirrored number orientation.
        let d10UVs: [SIMD2<Float>] = [SIMD2(0.50, 0.07), SIMD2(0.87, 0.72), SIMD2(0.13, 0.72)]
        return try triangularFaceMesh(name: "d10", shared: shared, sharedIndices: sharedIndices, faceUVs: d10UVs)
    }

    // MARK: - d12 Dodecahedron (12 pentagonal faces)

    private static func dodecahedronMesh() throws -> MeshResource {
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

        let faces: [[UInt32]] = [
            [0, 8, 9, 2,16], [0,16,17, 1,12], [0,12,13, 4, 8],
            [5,13,12, 1,10], [1,17, 3,11,10], [3,17,16, 2,14],
            [2, 9, 6,15,14], [6, 9, 8, 4,18], [4,13, 5,19,18],
            [7,19, 5,10,11], [7,11, 3,14,15], [7,15, 6,18,19]
        ]

        var positions: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        var matIdx: [UInt32] = []

        for (faceIdx, face) in faces.enumerated() {
            let faceVerts = face.map { v[Int($0)] }
            // Compute per-vertex UVs so the full pentagon maps to one texture (not once per triangle).
            let faceUVs = pentagonFaceUVs(faceVerts)

            for t in 1..<(face.count - 1) {
                let base = UInt32(positions.count)
                positions += [faceVerts[0], faceVerts[t], faceVerts[t + 1]]
                uvs       += [faceUVs[0],   faceUVs[t],   faceUVs[t + 1]]
                indices   += [base, base+1, base+2]
                matIdx.append(UInt32(faceIdx))
            }
        }
        return try buildMeshWithUVs(name: "d12", positions: positions, uvs: uvs,
                                    indices: indices, matIndices: matIdx)
    }

    /// Projects the 5 pentagon vertices onto the face's local 2D plane and returns
    /// UV coordinates centred at (0.5, 0.5). U is negated to match the outward-facing
    /// winding so the number reads correctly (not mirrored).
    private static func pentagonFaceUVs(_ verts: [SIMD3<Float>]) -> [SIMD2<Float>] {
        let centroid = verts.reduce(SIMD3<Float>.zero, +) / Float(verts.count)
        let right    = normalize(verts[0] - centroid)
        let normal   = normalize(centroid)          // outward normal for a unit dodecahedron
        let up       = normalize(cross(normal, right))

        let coords = verts.map { vert -> SIMD2<Float> in
            let d = vert - centroid
            return SIMD2(simd_dot(d, right), simd_dot(d, up))
        }

        let maxR = coords.map { sqrt($0.x * $0.x + $0.y * $0.y) }.max() ?? 1
        let scale: Float = 0.42 / maxR

        // Negate u to fix left-right mirroring; negate v to fix upside-down orientation.
        return coords.map { SIMD2(-$0.x * scale + 0.5, -$0.y * scale + 0.5) }
    }

    // MARK: - d20 Icosahedron (20 triangular faces)

    private static func icosahedronMesh() throws -> MeshResource {
        let φ: Float = (1 + sqrt(5.0)) / 2
        let shared: [SIMD3<Float>] = [
            SIMD3( 0,  1,  φ), SIMD3( 0, -1,  φ), SIMD3( 0,  1, -φ), SIMD3( 0, -1, -φ),
            SIMD3( 1,  φ,  0), SIMD3(-1,  φ,  0), SIMD3( 1, -φ,  0), SIMD3(-1, -φ,  0),
            SIMD3( φ,  0,  1), SIMD3(-φ,  0,  1), SIMD3( φ,  0, -1), SIMD3(-φ,  0, -1)
        ].map { normalize($0) }

        let sharedIndices: [UInt32] = [
            0, 1, 8,   0, 8, 4,   0, 4, 5,   0, 5, 9,   0, 9, 1,
            3, 2,10,   3,10, 6,   3, 6, 7,   3, 7,11,   3,11, 2,
            1, 6, 8,   8, 6,10,   8,10, 4,   4,10, 2,   4, 2, 5,
            5, 2,11,   5,11, 9,   9,11, 7,   9, 7, 1,   1, 7, 6
        ]
        // d20 winding produces mirrored UVs — swap left/right to correct, same as d8.
        let d20UVs: [SIMD2<Float>] = [SIMD2(0.50, 0.10), SIMD2(0.84, 0.76), SIMD2(0.16, 0.76)]
        return try triangularFaceMesh(name: "d20", shared: shared, sharedIndices: sharedIndices, faceUVs: d20UVs)
    }

    // MARK: - Generic Helpers

    /// Expands a shared-vertex mesh into per-face unshared vertices with UV coordinates.
    /// `faceUVs`: 3 UV coordinates [v0, v1, v2] applied to each triangle.
    /// Default covers the central ~65% of the texture square — works for centred-number faces.
    /// d4 uses a wider triangle so corner numbers near the edges are fully visible.
    private static func triangularFaceMesh(
        name: String,
        shared: [SIMD3<Float>],
        sharedIndices: [UInt32],
        faceUVs: [SIMD2<Float>] = [SIMD2(0.50, 0.07), SIMD2(0.13, 0.72), SIMD2(0.87, 0.72)]
    ) throws -> MeshResource {
        let triCount = sharedIndices.count / 3

        var positions: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        var matIdx: [UInt32] = []

        positions.reserveCapacity(triCount * 3)
        uvs.reserveCapacity(triCount * 3)
        indices.reserveCapacity(triCount * 3)
        matIdx.reserveCapacity(triCount)

        for t in 0..<triCount {
            let i0 = Int(sharedIndices[t * 3])
            let i1 = Int(sharedIndices[t * 3 + 1])
            let i2 = Int(sharedIndices[t * 3 + 2])
            let base = UInt32(positions.count)
            positions.append(shared[i0])
            positions.append(shared[i1])
            positions.append(shared[i2])
            uvs.append(contentsOf: faceUVs)
            indices += [base, base+1, base+2]
            matIdx.append(UInt32(t))
        }
        return try buildMeshWithUVs(name: name, positions: positions, uvs: uvs,
                                    indices: indices, matIndices: matIdx)
    }

    private static func buildMeshWithUVs(
        name: String,
        positions: [SIMD3<Float>],
        uvs: [SIMD2<Float>],
        indices: [UInt32],
        matIndices: [UInt32]
    ) throws -> MeshResource {
        var descriptor = MeshDescriptor(name: name)
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        descriptor.primitives = .triangles(indices)
        descriptor.materials = .perFace(matIndices)
        return try MeshResource.generate(from: [descriptor])
    }

}
