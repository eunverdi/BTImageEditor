//
//  ImageStickerState.swift
//  BTImageEditor
//
//  Created by Ensar Batuhan Ünverdi on 2.11.2024.
//

import UIKit.UIImage

public class ImageStickerState {
    let image: UIImage
    let originScale: CGFloat
    let originAngle: CGFloat
    let originFrame: CGRect
    let gestureScale: CGFloat
    let gestureRotation: CGFloat
    let totalTranslationPoint: CGPoint
    
    init(
        image: UIImage,
        originScale: CGFloat,
        originAngle: CGFloat,
        originFrame: CGRect,
        gestureScale: CGFloat,
        gestureRotation: CGFloat,
        totalTranslationPoint: CGPoint
    ) {
        self.image = image
        self.originScale = originScale
        self.originAngle = originAngle
        self.originFrame = originFrame
        self.gestureScale = gestureScale
        self.gestureRotation = gestureRotation
        self.totalTranslationPoint = totalTranslationPoint
    }
}
