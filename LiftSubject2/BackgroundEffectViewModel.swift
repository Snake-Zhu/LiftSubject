//
//  BackgroundEffectViewModel.swift
//  LiftSubject2
//
//  Created by 朱国卿 on 2023/07/03.
//

import UIKit
import Vision

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
    
    func showMaskImage() {
        if let maskImage {
            outputImage = UIImage(ciImage: maskImage)
        }
    }
    
    func convertPixelBufferToCIImage(pixelBuffer: CVPixelBuffer) -> CIImage {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        return ciImage
    }
}
