//
//  DrawingColorPickerPinView.swift
//  BTImageEditor
//
//  Created by Ensar Batuhan Ünverdi on 2.11.2024.
//

import UIKit

final class DrawingColorPickerPinView: UIView {
    
    private var color: CGColor = UIColor.black.cgColor
    private var width: CGFloat = 4
    
    private var path: UIBezierPath?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        UIGraphicsGetCurrentContext()?.clear(rect)

        let halfSize: CGFloat = min( bounds.size.width / 2, bounds.size.height / 2)

        let circlePath = path ?? UIBezierPath(
            arcCenter: CGPoint(x: halfSize, y: halfSize),
            radius: width,
            startAngle: 0,
            endAngle: CGFloat.pi * 2,
            clockwise: true)


        UIColor(cgColor: color).setStroke()
        UIColor(cgColor: color).setFill()
        circlePath.lineWidth = 20
        circlePath.stroke()
        circlePath.fill()
    }
    
    func setColor(_ color: CGColor) {
        self.color = color
        setNeedsDisplay()
    }
    
    func setWidth(_ width: CGFloat) {
        self.width = width / 2 // radius
        setNeedsDisplay()
    }
}
