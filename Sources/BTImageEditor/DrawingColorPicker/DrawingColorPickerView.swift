//
//  DrawingColorPickerView.swift
//  BTImageEditor
//
//  Created by Ensar Batuhan Ünverdi on 2.11.2024.
//

import UIKit

@MainActor
protocol DrawingColorPickerViewDelegate: AnyObject {
    func colorPicked(_ color: CGColor)
    func strokeWidthSet(_ width: CGFloat)
    func setIsActiveTo(_ isActive: Bool)
    func colorChanged()
    func showDrawingViewController()
}

extension DrawingColorPickerViewDelegate {
    func strokeWidthSet(_ width: CGFloat) {
        print("DrawingColorPickerViewDelegate strokeWidthSet function default implementation")
    }
    
    func setIsActiveTo(_ isActive: Bool) {
        print("DrawingColorPickerViewDelegate setIsActiveTo function default implementation")
    }
    
    func colorChanged() {
        print("DrawingColorPickerViewDelegate colorChanged function default implementation")
    }
    
    func showDrawingViewController() {
        print("DrawingColorPickerViewDelegate showDrawingViewController function default implementation")
    }
}

final class DrawingColorPickerView: UIView {
    
    weak var delegate: DrawingColorPickerViewDelegate?
    weak var penDelegate: DrawingThicknessPenProtocol?
    
    var isActive: Bool = false {
        didSet {
            delegate?.setIsActiveTo(isActive)
        }
    }
        
    public lazy var penButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "pencil"), for: .normal)
        button.tintColor = UITraitCollection.current.userInterfaceStyle == .dark ? .white : .black
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(penButtonPressed), for: .touchUpInside)
        button.layer.cornerRadius = 20
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.imageView?.contentMode = .center
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        return button
    }()
    
    private(set) lazy var pickerView: DrawingColorPickerBarView = {
        let view = DrawingColorPickerBarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        view.delegate = self
        
        return view
    }()
    
    private lazy var pinView: DrawingColorPickerPinView = {
        let view = DrawingColorPickerPinView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setColor(UIColor.black.cgColor)
        view.alpha = 0
        
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    // MARK: - Functions
    func layoutView() {
        layoutIfNeeded()
        
        addSubview(penButton)
        addSubview(pickerView)
        addSubview(pinView)
        bringSubviewToFront(pinView)
        
        NSLayoutConstraint.activate([
            penButton.heightAnchor.constraint(equalToConstant: 40),
            penButton.widthAnchor.constraint(equalToConstant: 40),
            penButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            penButton.topAnchor.constraint(equalTo: topAnchor),
   
            pinView.heightAnchor.constraint(equalToConstant: 34),
            pinView.widthAnchor.constraint(equalToConstant: 34),
            pinView.centerXAnchor.constraint(equalTo: centerXAnchor),
            pinView.topAnchor.constraint(equalTo: topAnchor),
            
            pickerView.topAnchor.constraint(equalTo: penButton.bottomAnchor, constant: 4),
            pickerView.widthAnchor.constraint(equalToConstant: frame.width - 32),
            pickerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            pickerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        layoutIfNeeded()
        
        pickerView.addColorLayer()
    }
    
    @objc public func penButtonPressed() {
        self.isActive.toggle()
        delegate?.showDrawingViewController()
    }
}

// MARK: - BarViewDelegate
extension DrawingColorPickerView: DrawingColorPickerBarViewDelegate {
    func strokeWidthSet(_ widht: CGFloat) {
        pinView.setWidth(widht)
        delegate?.strokeWidthSet(widht)
    }
    
    func touchBegan() {
        UIView.animate(withDuration: 0.15) { [weak self] in
            guard let self = self else { return }
            self.pinView.alpha = 1
            self.penButton.alpha = 0
        }
    }
    
    func touchEnded() {
        UIView.animate(withDuration: 0.15) { [weak self] in
            guard let self = self else { return }
            self.pinView.alpha = 0
            self.penButton.alpha = 1
        }
    }
    
    func colorPicked(_ color: CGColor) {
        penButton.layer.backgroundColor = UIColor(cgColor: color).cgColor
        pinView.setColor(color)
        delegate?.colorPicked(color)
    }
}
