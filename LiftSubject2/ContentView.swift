//
//  ContentView.swift
//  LiftSubject
//
//  Created by 朱国卿 on 2023/06/23.
//

import SwiftUI
import VisionKit

struct ContentView: View {
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            VStack{
                Button(action: {
                    self.showImagePicker = true
                }) {
                    Text("画像を選択")
                }
                .sheet(isPresented: $showImagePicker) {
                    ImagePickerView(selectedImage: self.$selectedImage)
                }
                
                if let image = selectedImage {
                    ImageView(image: image)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            
            .tabItem {
                Text("Lift Subject")
            }
            .tag(0)
            
            BackgroundEffectView()
                .tabItem {
                    Text("Change Background")
                }
                .tag(1)
            
        }
    }
    
}

#Preview {
    ContentView()
}

struct ImageView: UIViewControllerRepresentable {
    var image: UIImage?

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = ImageViewController()
        
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let controller = uiViewController as? ImageViewController, let image else {
            return
        }
        controller.updateImage(image: image)
    }
}

class ImageViewController: UIViewController {
    var imageView: UIImageView?
    var imageAnalyzer: ImageAnalyzer?
    var interaction: ImageAnalysisInteraction?
    var panGestureRecognizer: UIPanGestureRecognizer?
    
    var floatingImageView: UIImageView?
    
    var subject: ImageAnalysisInteraction.Subject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView = UIImageView()
        guard let imageView else {
            return
        }
        imageView.contentMode = .scaleAspectFit
        
        imageView.isUserInteractionEnabled = true
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        floatingImageView = UIImageView()
        floatingImageView?.frame = CGRect(origin: .zero, size: .init(width: 300, height: 300))
        floatingImageView?.contentMode = .scaleAspectFit
        view.addSubview(floatingImageView!)
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(hovering(_:)))
        imageView.addGestureRecognizer(panGestureRecognizer!)
        
        imageAnalyzer = ImageAnalyzer()
        
        interaction = ImageAnalysisInteraction()
        
        imageView.addInteraction(interaction!)
    }
    
    func updateImage(image: UIImage) {
        imageView?.image = image
        
        Task { @MainActor in
            let config = ImageAnalyzer.Configuration([.text])
            do {
                let analyze = try await imageAnalyzer?.analyze(imageView!.image!, configuration: config)
                interaction?.analysis = analyze
//                interaction?.preferredInteractionTypes = .automatic
                interaction?.preferredInteractionTypes = .imageSubject
                interaction?.selectableItemsHighlighted = true
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    @objc
    func hovering(_ recognizer: UIPanGestureRecognizer) {
        defer {
            if recognizer.state == .ended {
                subject = nil
                updateFloatingImage(image: nil)
            }
        }
        guard recognizer.state == .began || recognizer.state == .changed else {
            return
        }
        
        let location = recognizer.location(in: imageView)
        print(location)
        let translation = recognizer.location(in: view)
        print(translation)
        let point = CGPoint(x: translation.x, y: translation.y)
        
        Task { @MainActor in
            if subject == nil {
                subject = await interaction?.subject(at: location)
                do {
                    if let image = try await subject?.image {
                        updateFloatingImage(image: image)
                        updateFloatingImageViewLocation(location: point)
                    }
                } catch {
                    print(error.localizedDescription)
                }
            } else {
                updateFloatingImageViewLocation(location: point)
            }
            
            
        }
    }
    
    func updateFloatingImage(image: UIImage?) {
        floatingImageView?.image = image
    }
    
    func updateFloatingImageViewLocation(location: CGPoint) {
        floatingImageView?.center = location
    }
}
