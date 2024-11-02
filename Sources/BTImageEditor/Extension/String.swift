//
//  String.swift
//  BTImageEditor
//
//  Created by Ensar Batuhan Ünverdi on 2.11.2024.
//

import UIKit

extension String {
    func boundingRect(font: UIFont, limitSize: CGSize) -> CGSize {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byCharWrapping

        let attributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.paragraphStyle: style]
        let attributesContent = NSMutableAttributedString(string: self, attributes: attributes)
        let size = attributesContent.boundingRect(with: limitSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).size
        
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
    
    func image() -> UIImage? {
        let size = CGSize(width: 35, height: 35)
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 10.0)
        UIColor.clear.set()
        UIRectFill(rect)
        (self as NSString).draw(in: rect, withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 30)])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
