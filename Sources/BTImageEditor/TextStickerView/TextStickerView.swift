//
//  TextStickerView.swift
//  BTImageEditor
//
//  Created by Ensar Batuhan Ünverdi on 2.11.2024.
//

import UIKit

final class TextStickerView: BaseStickerView<TextStickerState> {
    static let fontSize: CGFloat = 30
    
    override var borderView: UIView {
        return priBorderView
    }
    
    private lazy var priBorderView: UIView = {
        let view = UIView()
        view.layer.borderWidth = StickerLayout.borderWidth
        return view
    }()
    
    private(set) lazy var label: UILabel = {
        let label = UILabel()
        label.text = text
        label.font = textFont ?? UIFont.boldSystemFont(ofSize: TextStickerView.fontSize)
        label.textColor = textColor
        label.backgroundColor = bgColor
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        return label
    }()
    
    var text: String {
        didSet {
            label.text = text
        }
    }
    
    var textColor: UIColor {
        didSet {
            label.textColor = textColor
        }
    }

    var textFont: UIFont? {
        didSet {
            label.font = textFont
        }
    }
    
    var bgColor: UIColor {
        didSet {
            label.backgroundColor = bgColor
        }
    }
    
    override var state: TextStickerState {
        return TextStickerState(
            text: text,
            textColor: textColor,
            font: textFont,
            bgColor: bgColor,
            originScale: originScale,
            originAngle: originAngle,
            originFrame: originFrame,
            gesScale: gesScale,
            gesRotation: gesRotation,
            totalTranslationPoint: totalTranslationPoint
        )
    }
    
    deinit {
        print("BTImageEditor: TextStickerView deinit")
    }
    
    convenience init(from state: TextStickerState) {
        self.init(
            text: state.text,
            textColor: state.textColor,
            font: state.textFont,
            bgColor: state.bgColor,
            originScale: state.originScale,
            originAngle: state.originAngle,
            originFrame: state.originFrame,
            gesScale: state.gesScale,
            gesRotation: state.gesRotation,
            totalTranslationPoint: state.totalTranslationPoint,
            showBorder: false
        )
    }
    
    init(
        text: String,
        textColor: UIColor,
        font: UIFont? = nil,
        bgColor: UIColor,
        originScale: CGFloat,
        originAngle: CGFloat,
        originFrame: CGRect,
        gesScale: CGFloat = 1,
        gesRotation: CGFloat = 0,
        totalTranslationPoint: CGPoint = .zero,
        showBorder: Bool = true
    ) {
        self.text = text
        self.textColor = textColor
        self.textFont = font
        self.bgColor = bgColor
        super.init(
            originScale: originScale,
            originAngle: originAngle,
            originFrame: originFrame,
            gesScale: gesScale,
            gesRotation: gesRotation,
            totalTranslationPoint: totalTranslationPoint,
            showBorder: showBorder
        )
        
        addSubview(borderView)
        borderView.addSubview(label)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("BTImageEditor: init(coder:) has not been implemented")
    }
    
    override func setupUIFrameWhenFirstLayout() {
        borderView.frame = bounds.insetBy(dx: StickerLayout.edgeInset, dy: StickerLayout.edgeInset)
        label.frame = borderView.bounds.insetBy(dx: StickerLayout.edgeInset, dy: StickerLayout.edgeInset)
    }
    
    override func tapAction(_ ges: UITapGestureRecognizer) {
        guard gesIsEnabled else { return }
        delegate?.sticker(self, editText: text)
        super.tapAction(ges)
    }
    
    func changeSize(to newSize: CGSize) {
        transform = transform.scaledBy(x: 1 / originScale, y: 1 / originScale)
        transform = transform.scaledBy(x: 1 / gesScale, y: 1 / gesScale)
        transform = transform.rotated(by: -gesRotation)
        transform = transform.rotated(by: -originAngle / 180 * .pi)
        
        let center = CGPoint(x: self.frame.midX, y: self.frame.midY)
        var frame = self.frame
        frame.origin.x = center.x - newSize.width / 2
        frame.origin.y = center.y - newSize.height / 2
        frame.size = newSize
        self.frame = frame
        
        let oc = CGPoint(x: originFrame.midX, y: originFrame.midY)
        var originFrame = originFrame
        originFrame.origin.x = oc.x - newSize.width / 2
        originFrame.origin.y = oc.y - newSize.height / 2
        originFrame.size = newSize
        self.originFrame = originFrame
        
        borderView.frame = bounds.insetBy(dx: StickerLayout.edgeInset, dy: StickerLayout.edgeInset)
        label.frame = borderView.bounds.insetBy(dx: StickerLayout.edgeInset, dy: StickerLayout.edgeInset)
        
        transform = transform.scaledBy(x: originScale, y: originScale)
        transform = transform.scaledBy(x: gesScale, y: gesScale)
        transform = transform.rotated(by: gesRotation)
        transform = transform.rotated(by: originAngle / 180 * .pi)
    }
    
    static func calculateSize(text: String, width: CGFloat, font: UIFont? = nil) -> CGSize {
        let diff = StickerLayout.edgeInset * 2
        let size = text.boundingRect(font: font ?? UIFont.boldSystemFont(ofSize:TextStickerView.fontSize), limitSize: CGSize(width: width - diff, height: CGFloat.greatestFiniteMagnitude))
        return CGSize(width: size.width + diff * 2, height: size.height + diff * 2)
    }
}


