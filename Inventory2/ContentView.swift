//
//  ContentView.swift
//  inventory
//
//  Created by mylo on 10/9/24.
//

import SwiftUI
import SceneKit
import QuickLook
import ModelIO
import UniformTypeIdentifiers
import MetalKit

struct ContentView: View {
    @State private var selectedURL: URL?
    @State private var showFilePicker = false
    
    var body: some View {
        VStack {
            if let url = selectedURL {
                ModelViewer(url: url)
                    .ignoresSafeArea()
            } else {
                Button("Select 3D Model") {
                    showFilePicker = true
                }
                .padding()
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.usdz, .threeDContent, UTType(filenameExtension: "glb") ?? .threeDContent]
        ) { result in
            switch result {
            case .success(let url):
                selectedURL = url
            case .failure(let error):
                print("DEBUG ModelViewer error:", error.localizedDescription)
            }
        }
    }
}

struct ModelViewer: View {
    let url: URL
    
    var body: some View {
        SceneView(
            scene: {
                if url.pathExtension.lowercased() == "glb" {
                    return loadGLBModel()
                } else {
                    return loadDefaultModel()
                }
            }(),
            options: [.allowsCameraControl, .autoenablesDefaultLighting]
        )
        .background(Color.clear)
    }
    
    private func loadGLBModel() -> SCNScene {
        // Create Metal device
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("DEBUG ModelViewer: Failed to create Metal device")
            return SCNScene()
        }
        
        // Create asset with Metal device
        let asset = MDLAsset(url: url, vertexDescriptor: nil, bufferAllocator: MTKMeshBufferAllocator(device: device))
        let scene = SCNScene()
        
        asset.loadTextures()
        if let object = asset.object(at: 0) as? MDLMesh {
            let node = SCNNode()
            
            // Create geometry sources from MDLMesh
            if let vertexBuffer = object.vertexBuffers[0] as? MTLBuffer {
                let vertexSource = SCNGeometrySource(buffer: vertexBuffer, 
                                                   vertexFormat: .float3, 
                                                   semantic: .vertex, 
                                                   vertexCount: object.vertexCount,
                                                   dataOffset: 0,
                                                   dataStride: 12)
                
                // Create geometry elements
                if let submeshes = object.submeshes as? [MDLSubmesh] {
                    let elements = submeshes.compactMap { submesh -> SCNGeometryElement? in
                        let indexBuffer = submesh.indexBuffer
                        let indexCount = submesh.indexCount
                        let bufferMap = indexBuffer.map()
                        let data = Data(bytes: bufferMap.bytes, count: indexCount * 2)
                        
                        return SCNGeometryElement(data: data,
                                                primitiveType: .triangles,
                                                primitiveCount: indexCount / 3,
                                                bytesPerIndex: 2)
                    }
                    
                    // Create geometry
                    let geometry = SCNGeometry(sources: [vertexSource], elements: elements)
                    node.geometry = geometry
                    scene.rootNode.addChildNode(node)
                    setupRotationAnimation(for: scene.rootNode)
                }
            }
        } else {
            print("DEBUG ModelViewer: Failed to convert MDL to SCN")
        }
        
        return scene
    }
    
    private func loadDefaultModel() -> SCNScene {
        if let scene = try? SCNScene(url: url, options: nil) {
            setupRotationAnimation(for: scene.rootNode)
            return scene
        } else {
            print("DEBUG ModelViewer: Failed to load default model")
            return SCNScene()
        }
    }
    
    private func setupRotationAnimation(for node: SCNNode) {
        if let firstChild = node.childNodes.first {
            let rotation = SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 8)
            let forever = SCNAction.repeatForever(rotation)
            firstChild.runAction(forever)
        }
    }
}

#Preview {
    ContentView()
}
