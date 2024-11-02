//
//  DrawingColorPickerBarView.swift
//  BTImageEditor
//
//  Created by Ensar Batuhan Ünverdi on 2.11.2024.
//

import UIKit

@MainActor
protocol DrawingColorPickerBarViewDelegate: AnyObject {
    func colorPicked(_ color: CGColor)
    func strokeWidthSet(_ widht: CGFloat)
    
    func touchBegan()
    func touchEnded()
}

final class DrawingColorPickerBarView: UIView {
    
    weak var delegate: DrawingColorPickerBarViewDelegate?
    
    private var colorLocations = [CGFloat]()
    private var colors = [CGColor]()
    private var currentWidth: CGFloat = 4
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func trimFirstDecimal(float: CGFloat) -> CGFloat {
        let divisor = pow(10.0, CGFloat(3))
        return (float * divisor).rounded() / divisor
    }
    
    private func handleColorPick(point: CGFloat) {
        guard let matchedLocationIndex = colorLocations.firstIndex(of: trimFirstDecimal(float: point)) else { return }
        delegate?.colorPicked(colors[matchedLocationIndex])
    }
    
    func addColorLayer() {
        var colors = [CGColor]()
        
        for r in 0..<255 + 30 + 30 { // Black and White
            if r < 30 {
                colors.append(UIColor.black.cgColor)
            } else if r < 60 {
                colors.append(UIColor.white.cgColor)
            } else {
                colors.append(UIColor(hue: CGFloat(r - 60) / 255.0, saturation: 1, brightness: 1, alpha: 1).cgColor)
            }
        }
        
        self.colors = colors
        let count = colors.count
        
        let gl = CAGradientLayer()
        gl.colors = colors
        gl.locations = (0..<count).map{
            NSNumber(value: Double($0) / Double(count))
        }
        
        colorLocations = gl.locations!.map { trimFirstDecimal(float: CGFloat($0.floatValue)) }
        
        gl.cornerRadius = frame.width / 2
        layer.cornerRadius = frame.width / 2
        
        layer.addSublayer(gl)
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
        
        gl.frame = bounds
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        delegate?.touchBegan()
        let position = touch.location(in: self)
        let locationPoint = (position.y) / frame.height
        handleColorPick(point: locationPoint)
        delegate?.strokeWidthSet(currentWidth)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        // Color
        let position = touch.location(in: self)
        let locationPoint = (position.y) / frame.height
        handleColorPick(point: locationPoint)
        
        // Stroke Width Min 3 : Max 25
        var strokePosition = -position.x / 10
        
        guard strokePosition > 1 else { return }
        
        if strokePosition < 3 {
            strokePosition = 3
        } else if strokePosition > 25 {
            strokePosition = 25
        }
        
        currentWidth = strokePosition
        delegate?.strokeWidthSet(strokePosition)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.touchEnded()
    }
}
