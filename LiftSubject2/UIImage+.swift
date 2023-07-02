//
//  File.swift
//  LiftSubject2
//
//  Created by 朱国卿 on 2023/07/01.
//

import Foundation
import UIKit

extension UIImage {
    static func colorImage(color: UIColor, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        
        let rect = CGRect(origin: CGPoint.zero, size: size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image
    }
}
