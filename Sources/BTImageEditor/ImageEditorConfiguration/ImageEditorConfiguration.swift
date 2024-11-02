//
//  ImageEditorConfiguration.swift
//  BTImageEditor
//
//  Created by Ensar Batuhan Ünverdi on 2.11.2024.
//

import UIKit

final class ImageEditorConfiguration {
    
    @MainActor static let shared = ImageEditorConfiguration()
    
    private var preDrawColors: [UIColor]
    private var preTextColors: [UIColor]
    
    private let defaultColors: [UIColor] = [
        .white,
        .black,
        UIColor(red: 241 / 255, green: 79 / 255, blue: 79 / 255, alpha: 1),
        UIColor(red: 243 / 255, green: 170 / 255, blue: 78 / 255, alpha: 1),
        UIColor(red: 80 / 255, green: 169 / 255, blue: 56 / 255, alpha: 1),
        UIColor(red: 30 / 255, green: 183 / 255, blue: 243 / 255, alpha: 1),
        UIColor(red: 139 / 255, green: 105 / 255, blue: 234 / 255, alpha: 1)
    ]
    
    public init() {
        self.preDrawColors = defaultColors
        self.preTextColors = defaultColors
    }
    
    @objc public var drawColors: [UIColor] {
        get { preDrawColors.isEmpty ? defaultColors : preDrawColors }
        set { preDrawColors = newValue }
    }
    
    @objc public var textColors: [UIColor] {
        get { preTextColors.isEmpty ? defaultColors : preTextColors }
        set { preTextColors = newValue }
    }
}


