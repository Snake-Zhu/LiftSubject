//
//  BackgroundEffectView.swift
//  LiftSubject2
//
//  Created by 朱国卿 on 2023/07/01.
//

import SwiftUI
import VisionKit
import Vision
import CoreImage

class BackgroundEffectViewModel: ObservableObject {
    @Published var foregroundImage: UIImage?
    private var backgroundImage: UIImage?
    
    var maskImage: CIImage?
    
    @Published var outputImage: UIImage?
    
    func makeForegroundImageMask() {
        guard let foregroundImage else { return }
        do {
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(cgImage: foregroundImage.cgImage!)
            try handler.perform([request])
            
            guard let result = request.results?.first else { return }
            
            let mask = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
            maskImage = convertPixelBufferToCIImage(pixelBuffer: mask)
            if let _ = maskImage {
                print("MaskImage ready!")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updateBackgroundImage(image: UIImage) {
        guard let backgroundCGimage = image.cgImage,
              let foregroundCGImage = foregroundImage?.cgImage else
        {
            return
        }
        
        if let maskImage {
            let backgroundCIImage = CIImage(cgImage: backgroundCGimage)
            let foregroundCIImage = CIImage(cgImage: foregroundCGImage)
            let output = apply(inputImage: foregroundCIImage, maskImage: maskImage, backgroundImage: backgroundCIImage)
            if let output {
                outputImage = UIImage(ciImage: output)
            } else {
                print("blendedImage is nil!!")
            }
        }
    }
    
    func updateBackgroundColor(color: UIColor) {
        guard let foregroundCGImage = foregroundImage?.cgImage else
        {
            return
        }
        
        let image = UIImage.colorImage(color: color, size: CGSize(width: foregroundCGImage.width, height: foregroundCGImage.height))
        let background = image?.cgImage
        
        if let maskImage,
           let backgroundCGImage = background
        {
            let foregroundCIImage = CIImage(cgImage: foregroundCGImage)
            let backgroundCIImage = CIImage(cgImage: backgroundCGImage)
            let output = apply(inputImage: foregroundCIImage, maskImage: maskImage, backgroundImage: backgroundCIImage)
            if let output {
                outputImage = UIImage(ciImage: output)
            } else {
                print("blendedImage is nil!!")
            }
        }
    }
    
    func apply(inputImage: CIImage, maskImage: CIImage, backgroundImage: CIImage) -> CIImage? {
        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else {
            return nil
        }
        
        // ソース画像とターゲット画像を指定
        blendFilter.setValue(inputImage, forKey: kCIInputImageKey)
        blendFilter.setValue(backgroundImage, forKey: kCIInputBackgroundImageKey)
        
        // マスク画像を指定
        blendFilter.setValue(maskImage, forKey: kCIInputMaskImageKey)
        
        // ブレンドを実行して結果のCIImageを取得
        guard let blendedImage = blendFilter.outputImage else {
            return nil
        }
        
        return blendedImage
    }
    
    func convertPixelBufferToCIImage(pixelBuffer: CVPixelBuffer) -> CIImage {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        return ciImage
    }
}
    
struct BackgroundEffectView: View {
    @State private var showImagePicker = false
    @State private var bindingImage: UIImage?
    @StateObject private var viewModel: BackgroundEffectViewModel = BackgroundEffectViewModel()
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    self.showImagePicker = true
                } label: {
                    Text("前景画像選択")
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
                        Text("全景をクリア")
                    }
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
