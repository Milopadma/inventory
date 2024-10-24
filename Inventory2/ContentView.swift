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
import GLTFSceneKit // IGNORE THIS ERR

@available(iOS 16.0, *)
struct ContentView: View {
    @State private var models: [ModelItem] = []
    @State private var showFilePicker = false
    @State private var selectedModel: ModelItem?
    
    init() {
        // Debug the bundle path
        print("DEBUG Bundle path:", Bundle.main.bundlePath)
        
        // Try all possible paths
        let fm = FileManager.default
        let bundlePath = Bundle.main.bundlePath
        let modelsPaths = [
            "\(bundlePath)/models",
            "\(bundlePath)/Models",
            Bundle.main.path(forResource: "models", ofType: nil),
            Bundle.main.path(forResource: "Models", ofType: nil)
        ].compactMap { $0 }
        
        print("DEBUG Checking paths:", modelsPaths)
        
        for path in modelsPaths {
            print("DEBUG Checking path:", path)
            if fm.fileExists(atPath: path) {
                print("DEBUG Found models at:", path)
                do {
                    let contents = try fm.contentsOfDirectory(atPath: path)
                    print("DEBUG Directory contents:", contents)
                    if let modelUrl = URL(string: "file://\(path)/drink.glb") {
                        print("DEBUG Loading model from:", modelUrl)
                        _models = State(initialValue: [ModelItem(url: modelUrl, name: "Drink")])
                        break
                    }
                } catch {
                    print("DEBUG Error reading directory:", error)
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // models carousel
                    TabView {
                        ForEach(models) { model in
                            VStack {
                                Text(model.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                
                                ModelViewer(url: model.url)
                                    .frame(
                                        width: geometry.size.width * 0.9,
                                        height: geometry.size.height * 0.7
                                    )
                                    .padding()
                            }
                        }
                    }
                    .tabViewStyle(.page)
                    .frame(maxHeight: geometry.size.height * 0.8)
                    
                    Spacer()
                    
                    // add model button at bottom
                    AddModelButton(showFilePicker: $showFilePicker)
                        .frame(height: 60)
                        .padding(.horizontal)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 8)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Items")
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.usdz, .threeDContent, UTType(filenameExtension: "glb") ?? .threeDContent]
            ) { result in
                switch result {
                case .success(let url):
                    do {
                        // Get documents directory
                        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        let destinationURL = documentsURL.appendingPathComponent(url.lastPathComponent)
                        
                        // Remove existing file if it exists
                        try? FileManager.default.removeItem(at: destinationURL)
                        
                        // Copy file to documents directory
                        if url.startAccessingSecurityScopedResource() {
                            defer { url.stopAccessingSecurityScopedResource() }
                            try FileManager.default.copyItem(at: url, to: destinationURL)
                        }
                        
                        let newModel = ModelItem(url: destinationURL, name: url.lastPathComponent)
                        models.append(newModel)
                    } catch {
                        print("DEBUG ModelViewer error copying file:", error.localizedDescription)
                    }
                case .failure(let error):
                    print("DEBUG ModelViewer error:", error.localizedDescription)
                }
            }
        }
    }
}

// add these type definitions at the top of the file, marked with a comment since we can't use a types folder in SwiftUI
// MARK: - Type Definitions
struct ModelItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ModelItem, rhs: ModelItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct AddModelButton: View {
    @Binding var showFilePicker: Bool
    
    var body: some View {
        Button(action: { showFilePicker = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("Add Model")
                    .font(.callout)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct ModelGridItem: View {
    let model: ModelItem
    
    var body: some View {
        VStack {
            ModelViewer(url: model.url)
                .frame(height: 120)
                .cornerRadius(8)
            
            Text(model.name)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ModelDetailView: View {
    let model: ModelItem
    
    var body: some View {
        ModelViewer(url: model.url)
            .ignoresSafeArea()
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(model.name)
    }
}

struct ModelViewer: View {
    let url: URL
    
    var body: some View {
        SceneView(
            scene: loadModel(),
            options: [.allowsCameraControl, .autoenablesDefaultLighting]
        )
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func loadModel() -> SCNScene {
        // Handle GLB/GLTF files
        if url.pathExtension.lowercased() == "glb" || url.pathExtension.lowercased() == "gltf" {
            do {
                // ensure we have a valid file URL
                let secureURL = url.startAccessingSecurityScopedResource() ? url : url
                defer { url.stopAccessingSecurityScopedResource() }
                
                // copy file to temporary location with read permissions
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.removeItem(at: tempURL) // remove if exists
                try FileManager.default.copyItem(at: secureURL, to: tempURL)
                
                print("DEBUG ModelViewer: Loading GLTF from:", tempURL.path)
                let sceneSource = try GLTFSceneSource(url: tempURL)
                let scene = try sceneSource.scene()
                setupRotationAnimation(for: scene.rootNode)
                return scene
            } catch {
                print("DEBUG ModelViewer: Failed to load GLTF model:", error.localizedDescription)
                return SCNScene()
            }
        }
        
        // Handle other 3D formats
        if let scene = try? SCNScene(url: url, options: nil) {
            setupRotationAnimation(for: scene.rootNode)
            return scene
        } else {
            print("DEBUG ModelViewer: Failed to load model from \(url.lastPathComponent)")
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
    if #available(iOS 16.0, *) {
        ContentView()
    } else {
        Text("This view requires iOS 16.0 or later")
    }
}
