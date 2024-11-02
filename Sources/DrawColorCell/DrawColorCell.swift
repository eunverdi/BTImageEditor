//
//  DrawColorCell.swift
//  BTImageEditor
//
//  Created by Ensar Batuhan Ünverdi on 2.11.2024.
//

import UIKit

class DrawColorCell: UICollectionViewCell {
    
    static let identifier: String = String(describing: DrawColorCell.self)
    
    var backgroundWhiteView: UIView!
    var colorView: UIView!
    
    var color: UIColor! {
        didSet {
            self.colorView.backgroundColor = color
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundWhiteView = UIView()
        backgroundWhiteView.backgroundColor = .white
        backgroundWhiteView.layer.cornerRadius = 10
        backgroundWhiteView.layer.masksToBounds = true
        backgroundWhiteView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        backgroundWhiteView.center = CGPoint(x: bounds.midX, y: bounds.midY)
        contentView.addSubview(backgroundWhiteView)
        
        colorView = UIView()
        colorView.layer.cornerRadius = 8
        colorView.layer.masksToBounds = true
        colorView.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
        colorView.center = CGPoint(x: bounds.midX, y: bounds.midY)
        contentView.addSubview(colorView)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
