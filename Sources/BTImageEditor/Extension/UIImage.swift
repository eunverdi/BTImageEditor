//
//  UIImage.swift
//  BTImageEditor
//
//  Created by Ensar Batuhan Ünverdi on 2.11.2024.
//

import UIKit.UIImage
import UIKit.UIScreen

extension UIImage {
    @MainActor
    func mosaicImage() -> UIImage? {
        guard let currCgImage = self.cgImage else {
            return nil
        }
        
        let scale = 8 * self.size.width / UIScreen.main.bounds.width
        let currCiImage = CIImage(cgImage: currCgImage)
        let filter = CIFilter(name: "CIPixellate")
        filter?.setValue(currCiImage, forKey: kCIInputImageKey)
        filter?.setValue(scale, forKey: kCIInputScaleKey)
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        
        if let cgImg = context.createCGImage(outputImage, from: CGRect(origin: .zero, size: self.size)) {
            return UIImage(cgImage: cgImg)
        } else {
            return nil
        }
    }
}
