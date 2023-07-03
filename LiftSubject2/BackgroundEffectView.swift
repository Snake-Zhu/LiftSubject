//
//  BackgroundEffectView.swift
//  LiftSubject2
//
//  Created by 朱国卿 on 2023/07/01.
//

import SwiftUI
import CoreImage
    
struct BackgroundEffectView: View {
    @State private var showImagePicker = false
    @State private var bindingImage: UIImage?
    @StateObject private var viewModel: BackgroundEffectViewModel = BackgroundEffectViewModel()
    
    var body: some View {
        VStack {
            HStack {
                if viewModel.foregroundImage == nil {
                    Button {
                        self.showImagePicker = true
                    } label: {
                        Text("画像選択")
                    }
                    
                }
                
                if let _ = viewModel.foregroundImage {
                    Button {
                        self.showImagePicker = true
                    } label: {
                        Text("背景画像選択")
                    }
                    
                    Button {
                        viewModel.foregroundImage = nil
                        viewModel.outputImage = nil
                    } label: {
                        Text("クリア")
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(selectedImage: $bindingImage)
            }
            .onChange(of: bindingImage) { _, newValue in
                if viewModel.foregroundImage == nil {
                    viewModel.foregroundImage = newValue
                    viewModel.makeForegroundImageMask()
                    viewModel.outputImage = newValue
                } else {
                    viewModel.updateBackgroundImage(image: newValue!)
                }
            }
            
            HStack {
                if let _ = viewModel.foregroundImage {
                    Button {
                        viewModel.updateBackgroundColor(color: .red)
                    } label: {
                        Image(systemName: "circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.red)
                            
                    }
                    Button {
                        viewModel.updateBackgroundColor(color: .green)
                    } label: {
                        Image(systemName: "circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.green)
                    }
                    Button {
                        viewModel.updateBackgroundColor(color: .blue)
                    } label: {
                        Image(systemName: "circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.blue)
                    }
                    Button {
                        viewModel.updateBackgroundColor(color: .white)
                    } label: {
                        Image(systemName: "circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.white)
                    }
                    Button {
                        viewModel.updateBackgroundColor(color: .gray)
                    } label: {
                        Image(systemName: "circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.gray)
                    }
                    
                    Button {
                        viewModel.showMaskImage()
                    } label: {
                        Text("Mask")
                    }
                }
            }
            
            
            if let image = viewModel.outputImage {
                EffectImageView(image: image)
            }
        }
        .navigationTitle("背景変更")
    }
}

#Preview {
    BackgroundEffectView()
}


struct EffectImageView: UIViewControllerRepresentable {
    var image: UIImage?
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = EffectImageViewController()
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let controller = uiViewController as? EffectImageViewController else {
            return
        }
        
        if let image {
            controller.updateImage(image: image)
        }
    }
}

class EffectImageViewController: UIViewController {
    var imageView: UIImageView?
    
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
    }
    
    func updateImage(image: UIImage) {
        imageView?.image = image
    }
}
