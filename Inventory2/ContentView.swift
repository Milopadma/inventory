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
            allowedContentTypes: [.usdz, .threeDContent]
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

struct ModelViewer: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = .clear
        
        // Create scene and load model
        let scene = try? SCNScene(url: url, options: nil)
        sceneView.scene = scene
        
        // Setup rotation animation if we have a model
        if let node = scene?.rootNode.childNodes.first {
            let rotation = SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 8)
            let forever = SCNAction.repeatForever(rotation)
            node.runAction(forever)
        }
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
}

#Preview {
    ContentView()
}
