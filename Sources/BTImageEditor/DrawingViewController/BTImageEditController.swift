//
//  BTImageEditController.swift
//  BTImageEditor
//
//  Created by Ensar Batuhan Ünverdi on 2.11.2024.
//

import UIKit
import EmojiPicker

public final class BTImageEditController: UIViewController {
    
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
    //MARK: - Drawing Property Variables
    private var drawPaths: [DrawPath] = []
    private var undoDrawPaths: [DrawPath] = []
    private var currentWidth: CGFloat = 4
    private var currentDrawColor: UIColor = .red
    
    //MARK: - Mosaic Property Variables
    private var mosaicPaths: [MosaicPath] = []
    private var undoMosaicPaths: [MosaicPath] = []
    private var mosaicLineWidth: CGFloat = 25
    private var mosaicImage: UIImage?
    private var mosaicImageLayer: CALayer?
    private var mosaicImageLayerMaskLayer: CAShapeLayer?
    
    //MARK: - Stickers Property Variables
    private var stickers: [UIView] = []
    private lazy var stickersContainer = UIView()
    
    private var selectedTool: BTImageEditController.EditTool? = .draw
    private var tools: [UIView] = []
    
    private var trashViewSize = CGSize(width: 160, height: 80)
    private var angle: CGFloat = 0
    private var penButtonInteractionEnabled: Bool = false
    
    public var editFinishBlock: ((UIImage) -> Void)?
    
    private var originalFrame: CGRect = .zero
    private var originalImage: UIImage!
    private var editImage: UIImage!
    
    var drawableObjects: [Drawable] = [] {
        didSet {
            if drawableObjects.isEmpty {
                undoButton.alpha = 0
                clearAllButton.alpha = 0
            }
        }
    }
    
    private var safeAreaInsetBottom: CGFloat {
        view.safeAreaInsets.bottom
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    public override var shouldAutorotate: Bool {
        return false
    }
    
    private var isDrawingActive: Bool = true {
        didSet {
            if isDrawingActive {
                drawingActiveState()
            } else {
                drawingNotActiveState()
            }
        }
    }
    
    private lazy var mainScrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .black
        view.minimumZoomScale = 1
        view.maximumZoomScale = 5
        view.delegate = self
        
        return view
    }()
    
    private lazy var trashView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        view.isHidden = true
        
        return view
    }()
    
    private lazy var trashImageView = UIImageView(image: UIImage(systemName: "trash"), highlightedImage: UIImage(systemName: "trash.fill"))
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        
        return view
    }()
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView(image: originalImage)
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.backgroundColor = .black
        
        return view
    }()
    
    private lazy var drawingImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = true
        
        return view
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 10
        button.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1.00)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Done", for: .normal)
        button.addTarget(self, action: #selector(doneButtonAction), for: .touchUpInside)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.5
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byClipping
        button.titleEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        return button
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 10
        button.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1.00)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Save", for: .normal)
        button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(dismissButtonAction), for: .touchUpInside)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.5
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byClipping
        button.titleEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        return button
    }()
    
    private lazy var undoButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 20
        button.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1.00)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "arrow.uturn.backward"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(undoButtonClick), for: .touchUpInside)
        button.imageView?.contentMode = .center
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        
        return button
    }()
    
    private lazy var textButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 20
        button.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1.00)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "character.cursor.ibeam"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(addTextButtonClick), for: .touchUpInside)
        button.imageView?.contentMode = .center
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        return button
    }()
    
    private lazy var emojiButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 20
        button.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1.00)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "face.smiling.inverse"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(emojiButtonClick), for: .touchUpInside)
        button.imageView?.contentMode = .center
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        return button
    }()
    
    private lazy var inputContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    public lazy var clearAllButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1.00)
        button.setTitle("Clear All", for: .normal)
        button.tintColor = UIColor.white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(clearAllButtonAction), for: .touchUpInside)
        button.layer.cornerRadius = 10
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.5
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byClipping
        button.titleEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        return button
    }()
    
    private lazy var normalThickness: UIButton = {
        let button = UIButton()
        button.isHidden = true
        if isDrawingActive {
            button.isHidden = false
            button.layer.backgroundColor = UIColor(white: 0.7, alpha: 0.5).cgColor
        }
        button.layer.cornerRadius = 20
        button.setImage(UIImage(systemName: "scribble"), for: .normal)
        button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 22, weight: .regular), forImageIn: .normal)
        button.tintColor = UIColor(red: 0.04, green: 0.55, blue: 0.59, alpha: 1.00)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(thicknessButtonPressed(_:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(thinWidth), for: .touchUpInside)
        
        return button
    }()
    
    private lazy var halfThickness: UIButton = {
        let button = UIButton()
        button.isHidden = isDrawingActive ? false : true
        button.layer.cornerRadius = 20
        button.setImage(UIImage(systemName: "scribble"), for: .normal)
        button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 22, weight: .bold), forImageIn: .normal)
        button.tintColor = UIColor(red: 0.04, green: 0.55, blue: 0.59, alpha: 1.00)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(thicknessButtonPressed(_:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(mediumWidth), for: .touchUpInside)
        
        return button
    }()
    
    private lazy var veryThickness: UIButton = {
        let button = UIButton()
        button.isHidden = isDrawingActive ? false : true
        button.layer.cornerRadius = 20
        button.setImage(UIImage(systemName: "scribble"), for: .normal)
        button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 22, weight: .heavy), forImageIn: .normal)
        button.tintColor = UIColor(red: 0.04, green: 0.55, blue: 0.59, alpha: 1.00)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(thicknessButtonPressed(_:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(thickWidth), for: .touchUpInside)
        
        return button
    }()
    
    private lazy var mosaicButton: UIButton = {
        let button = UIButton()
        button.isHidden = isDrawingActive ? false : true
        button.layer.cornerRadius = 20
        button.setImage(UIImage(systemName: "scribble.variable"), for: .normal)
        button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 22, weight: .regular), forImageIn: .normal)
        button.tintColor = UIColor(red: 0.04, green: 0.55, blue: 0.59, alpha: 1.00)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(thicknessButtonPressed(_:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(setEditTool), for: .touchUpInside)
        
        return button
    }()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = .clear
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 5
        
        return stackView
    }()
    
    private lazy var inputContainerBottomConstraint: NSLayoutConstraint = {
        return NSLayoutConstraint(item: self.inputContainerView,
                                  attribute: .bottomMargin,
                                  relatedBy: .equal,
                                  toItem: self.view.safeAreaLayoutGuide,
                                  attribute: .bottom,
                                  multiplier: 1,
                                  constant: -8)
    }()
    
    private lazy var colorPickerView: DrawingColorPickerView = {
        let view = DrawingColorPickerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        
        return view
    }()
    
    private let tapGesture: UITapGestureRecognizer = {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.cancelsTouchesInView = false
        tapGesture.addTarget(self, action: #selector(dismissKeyboard))
        
        return tapGesture
    }()
    
    private var panGesture: UIPanGestureRecognizer!
    
    public init(originalImage: UIImage?) {
        self.originalImage = originalImage
        self.editImage = originalImage
        
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        prepareViewDidLoad()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mainScrollView.frame = view.bounds
        resetContainerViewFrame()
        
        trashView.frame = CGRect(x: (view.frame.width - trashViewSize.width) / 2, y: view.frame.height - trashViewSize.height - 40, width: trashViewSize.width, height: trashViewSize.height)
        trashImageView.frame = CGRect(x: (trashViewSize.width - 25) / 2, y: 15, width: 25, height: 25)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    private func setToolView(show: Bool) {
        UIView.animate(withDuration: 0.25) {
            show ? self.setToolsAlphaToOne() : self.setToolsAlphaToZero()
        }
    }
}

extension BTImageEditController {
    private func prepareViewDidLoad() {
        setupMosaicView()
        configureSubviews()
        setupStackView()
        setupButtons()
        configureSuperview()
        setupConstraints()
        setupColorPickerView()
        setupTrashView()
        setupStickers()
        setupTools()
        setupPanGesture()
    }
}

extension BTImageEditController {
    private func setupPanGesture() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(drawAction(_ :)))
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        mainScrollView.panGestureRecognizer.require(toFail: panGesture)
    }
}

extension BTImageEditController {
    private func setupTools() {
        tools.append(backButton)
        tools.append(doneButton)
        tools.append(emojiButton)
        tools.append(undoButton)
        tools.append(textButton)
        tools.append(inputContainerView)
        tools.append(clearAllButton)
    }
}

extension BTImageEditController {
    private func setupStickers() {
        stickers.forEach { view in
            self.stickersContainer.addSubview(view)
            if let textView = view as? TextStickerView {
                textView.frame = textView.originFrame
                self.configTextSticker(textView)
            } else if let imageView = view as? ImageStickerView {
                imageView.frame = imageView.originFrame
                self.configImageSticker(imageView)
            }
        }
    }
}

extension BTImageEditController {
    private func setupTrashView() {
        view.addSubview(trashView)
        trashView.addSubview(trashImageView)
        
        let trashViewLabel = UILabel(frame: CGRect(x: 0, y: trashViewSize.height - 34, width: trashViewSize.width, height: 34))
        trashViewLabel.font = UIFont.systemFont(ofSize: 12)
        trashViewLabel.textAlignment = .center
        trashViewLabel.textColor = .white
        trashViewLabel.text = "Drag to trash"
        trashViewLabel.numberOfLines = 2
        trashViewLabel.lineBreakMode = .byCharWrapping
        trashView.addSubview(trashViewLabel)
    }
}

extension BTImageEditController {
    private func setupColorPickerView() {
        colorPickerView.layoutView()
        colorPickerView.pickerView.alpha = 1
        colorPickerView.penButton.backgroundColor = currentDrawColor
        colorPickerView.penButton.tintColor = .white
    }
}

extension BTImageEditController {
    private func setupMosaicView() {
        mosaicImage = editImage.mosaicImage()
        
        mosaicImageLayer = CALayer()
        mosaicImageLayer?.contents = mosaicImage?.cgImage
        imageView.layer.addSublayer(mosaicImageLayer!)
        
        mosaicImageLayerMaskLayer = CAShapeLayer()
        mosaicImageLayerMaskLayer?.strokeColor = UIColor.blue.cgColor
        mosaicImageLayerMaskLayer?.fillColor = nil
        mosaicImageLayerMaskLayer?.lineCap = .round
        mosaicImageLayerMaskLayer?.lineJoin = .round
        imageView.layer.addSublayer(mosaicImageLayerMaskLayer!)
        
        mosaicImageLayer?.mask = mosaicImageLayerMaskLayer
    }
}

extension BTImageEditController {
    private func configureSubviews() {
        view.addSubview(mainScrollView)
        view.addSubview(doneButton)
        view.addSubview(backButton)
        view.addSubview(undoButton)
        view.addSubview(emojiButton)
        view.addSubview(textButton)
        view.addSubview(clearAllButton)
        view.addSubview(colorPickerView)
        view.addSubview(stackView)
        view.addSubview(inputContainerView)
        
        containerView.addSubview(imageView)
        containerView.addSubview(drawingImageView)
        containerView.addSubview(stickersContainer)
        mainScrollView.addSubview(containerView)
        
    }
}

extension BTImageEditController {
    private func setupStackView() {
        stackView.addArrangedSubview(normalThickness)
        stackView.addArrangedSubview(halfThickness)
        stackView.addArrangedSubview(veryThickness)
        stackView.addArrangedSubview(mosaicButton)
    }
}

extension BTImageEditController {
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 90),
            
            doneButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            doneButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            doneButton.widthAnchor.constraint(equalToConstant: 40),
            
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15),
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            
            undoButton.widthAnchor.constraint(equalToConstant: 40),
            undoButton.heightAnchor.constraint(equalToConstant: 40),
            undoButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            undoButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -65),
            
            textButton.widthAnchor.constraint(equalToConstant: 40),
            textButton.heightAnchor.constraint(equalToConstant: 40),
            textButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            textButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -90),
            
            emojiButton.widthAnchor.constraint(equalToConstant: 40),
            emojiButton.heightAnchor.constraint(equalToConstant: 40),
            emojiButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            emojiButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -40),
            
            clearAllButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            clearAllButton.leadingAnchor.constraint(equalTo: doneButton.trailingAnchor, constant: 20),
            
            normalThickness.heightAnchor.constraint(equalToConstant: 40),
            normalThickness.widthAnchor.constraint(equalToConstant: 80),
            
            halfThickness.heightAnchor.constraint(equalToConstant: 40),
            halfThickness.widthAnchor.constraint(equalToConstant: 80),
            
            veryThickness.heightAnchor.constraint(equalToConstant: 40),
            veryThickness.widthAnchor.constraint(equalToConstant: 80),
            
            mosaicButton.heightAnchor.constraint(equalToConstant: 40),
            mosaicButton.widthAnchor.constraint(equalToConstant: 80),
            
            inputContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            inputContainerBottomConstraint,
            
            colorPickerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            colorPickerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15),
            colorPickerView.heightAnchor.constraint(equalToConstant: 240),
            colorPickerView.widthAnchor.constraint(equalToConstant: 50)
        ])
    }
}

extension BTImageEditController {
    private func configureSuperview() {
        view.backgroundColor = .black
        view.addGestureRecognizer(tapGesture)
        view.bringSubviewToFront(colorPickerView)
        hidesBottomBarWhenPushed = true
        modalPresentationCapturesStatusBarAppearance = true
    }
}

extension BTImageEditController {
    private func setupButtons() {
        //Cancel Button Initial Configuration
        backButton.alpha = 0.0
        backButton.isUserInteractionEnabled = false
        
        //Input Container View Initial Configuration
        inputContainerView.alpha = 0.0
        inputContainerView.isUserInteractionEnabled = false
        
        //Undo Button Initial Configuration
        undoButton.alpha = 0.0
        undoButton.isUserInteractionEnabled = false
        
        //Emoji Button Initial Configuraiton
        emojiButton.alpha = 0.0
        emojiButton.isUserInteractionEnabled = false
        
        //Text Button Initial Configuration
        textButton.alpha = 0.0
        textButton.isUserInteractionEnabled = false
        
        //Clear All Button Initial Configuration
        clearAllButton.alpha = 0.0
        clearAllButton.isUserInteractionEnabled = false
    }
}

extension BTImageEditController {
    private func drawingActiveState() {
        stickersContainer.subviews.forEach { view in
            (view as? StickerViewAdditional)?.gesIsEnabled = false
        }
        
        stackView.alpha = 1
        stackView.isUserInteractionEnabled = true
        
        backButton.alpha = 0
        backButton.isUserInteractionEnabled = false
        
        doneButton.alpha = 1
        doneButton.isUserInteractionEnabled = true
        
        UIView.animate(withDuration: 0.5) {
            self.emojiButton.transform = .identity
            self.emojiButton.alpha = 0
            self.emojiButton.isUserInteractionEnabled = false
            
            self.textButton.transform = .identity
            self.textButton.alpha = 0
            self.textButton.isUserInteractionEnabled = false
            
            self.undoButton.transform = .identity
            self.undoButton.isUserInteractionEnabled = false
            
            if !self.undoDrawPaths.isEmpty || !self.mosaicPaths.isEmpty {
                self.undoButton.alpha = 1
            } else {
                self.undoButton.alpha = 0
            }
        }
        penButtonInteractionEnabled = false
        colorPickerView.penButton.backgroundColor = currentDrawColor
    }
}

extension BTImageEditController {
    private func drawingNotActiveState() {
        stickersContainer.subviews.forEach { view in
            (view as? StickerViewAdditional)?.gesIsEnabled = true
        }
        
        stackView.alpha = 0
        stackView.isUserInteractionEnabled = false
        
        backButton.alpha = 1
        backButton.isUserInteractionEnabled = true
        
        doneButton.alpha = 0
        doneButton.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.5) {
            self.emojiButton.transform = self.emojiButton.transform.translatedBy(x: -self.emojiButton.frame.width, y: 0)
            self.emojiButton.alpha = 1
            self.emojiButton.isUserInteractionEnabled = true
            
            self.textButton.transform = self.textButton.transform.translatedBy(x: -self.textButton.frame.width, y: 0)
            self.textButton.alpha = 1
            self.textButton.isUserInteractionEnabled = true
            
            self.undoButton.transform = self.undoButton.transform.translatedBy(x: (-self.undoButton.frame.width) + (-self.textButton.frame.width) + (-self.emojiButton.frame.width) + 5, y: 0)
            self.undoButton.isUserInteractionEnabled = true
            
            if !self.undoDrawPaths.isEmpty || !self.mosaicPaths.isEmpty {
                self.undoButton.alpha = 1
            } else {
                self.undoButton.alpha = 0
            }
        }
        penButtonInteractionEnabled = true
        colorPickerView.penButton.backgroundColor = .white
    }
}

extension BTImageEditController {
    private func resetContainerViewFrame() {
        mainScrollView.setZoomScale(1, animated: true)
        imageView.image = editImage
        
        let editSize = CGRect(origin: .zero, size: originalImage.size).size
        let scrollViewSize = mainScrollView.frame.size
        let ratio = min(scrollViewSize.width / editSize.width, scrollViewSize.height / editSize.height)
        let width = ratio * editSize.width * mainScrollView.zoomScale
        let height = ratio * editSize.height * mainScrollView.zoomScale
        
        containerView.frame = CGRect(x: max(0, (scrollViewSize.width - width) / 2), y: max(0, (scrollViewSize.height - height) / 2), width: width, height: height)
        mainScrollView.contentSize = containerView.frame.size
        containerView.layer.mask = nil
        
        let scaleImageOrigin = CGPoint(x: -CGRect(origin: .zero, size: originalImage.size).origin.x * ratio, y: -CGRect(origin: .zero, size: originalImage.size).origin.y * ratio)
        let scaleImageSize = CGSize(width: originalImage.size.width * ratio, height: originalImage.size.height * ratio)
        
        imageView.frame = CGRect(origin: scaleImageOrigin, size: scaleImageSize)
        mosaicImageLayer?.frame = imageView.bounds
        mosaicImageLayerMaskLayer?.frame = imageView.bounds
        drawingImageView.frame = imageView.frame
        stickersContainer.frame = imageView.frame
    }
}

extension BTImageEditController {
    private func setToolsAlphaToZero() {
        self.backButton.alpha = 0
        self.backButton.isUserInteractionEnabled = false
        
        self.textButton.alpha = 0
        self.textButton.isUserInteractionEnabled = false
        
        self.emojiButton.alpha = 0
        self.emojiButton.isUserInteractionEnabled = false
        
        self.colorPickerView.alpha = 0
        self.colorPickerView.isUserInteractionEnabled = false
        
        self.inputContainerView.alpha = 0
        self.inputContainerView.isUserInteractionEnabled = false
        
        if !self.drawableObjects.isEmpty {
            self.undoButton.alpha = 0
            self.undoButton.isUserInteractionEnabled = false
            
            self.clearAllButton.alpha = 0
            self.clearAllButton.isUserInteractionEnabled = false
        }
    }
}

extension BTImageEditController {
    private func setToolsAlphaToOne() {
        self.backButton.alpha = 1
        self.backButton.isUserInteractionEnabled = true
        
        self.textButton.alpha = 1
        self.textButton.isUserInteractionEnabled = true
        
        self.emojiButton.alpha = 1
        self.emojiButton.isUserInteractionEnabled = true
        
        self.colorPickerView.alpha = 1
        self.colorPickerView.isUserInteractionEnabled = true
        
        if !self.drawableObjects.isEmpty {
            self.undoButton.alpha = 1
            self.undoButton.isUserInteractionEnabled = true
            
            self.clearAllButton.alpha = 1
            self.clearAllButton.isUserInteractionEnabled = true
        }
    }
}

extension BTImageEditController {
    private func drawLine() {
        let originalRatio = min(mainScrollView.frame.width / originalImage.size.width, mainScrollView.frame.height / originalImage.size.height)
        let ratio = min(mainScrollView.frame.width / CGRect(origin: .zero, size: originalImage.size).width, mainScrollView.frame.height / CGRect(origin: .zero, size: originalImage.size).height)
        let scale = ratio / originalRatio
        var size = drawingImageView.frame.size
        size.width /= scale
        size.height /= scale
        
        var toImageScale = 600 / size.width
        if editImage.size.width / editImage.size.height > 1 {
            toImageScale = 600 / size.height
        }
        size.width *= toImageScale
        size.height *= toImageScale
        
        UIGraphicsBeginImageContextWithOptions(size, false, editImage.scale)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setAllowsAntialiasing(true)
        context?.setShouldAntialias(true)
        for path in drawPaths {
            path.drawPath()
        }
        drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
}

extension BTImageEditController {
    @discardableResult
    private func generateNewMosaicImage(inputImage: UIImage? = nil, inputMosaicImage: UIImage? = nil) -> UIImage? {
        let renderRect = CGRect(origin: .zero, size: originalImage.size)
        
        UIGraphicsBeginImageContextWithOptions(originalImage.size, false, originalImage.scale)
        if inputImage != nil {
            inputImage?.draw(in: renderRect)
        } else {
            var drawImage: UIImage?
            drawImage = originalImage
            drawImage?.draw(at: .zero)
            drawImage?.draw(in: renderRect)
        }
        let context = UIGraphicsGetCurrentContext()
        
        mosaicPaths.forEach { path in
            context?.move(to: path.startPoint)
            path.linePoints.forEach { point in
                context?.addLine(to: point)
            }
            context?.setLineWidth(path.path.lineWidth / path.ratio)
            context?.setLineCap(.round)
            context?.setLineJoin(.round)
            context?.setBlendMode(.clear)
            context?.strokePath()
        }
        
        var midImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let midCgImage = midImage?.cgImage else {
            return nil
        }
        
        midImage = UIImage(cgImage: midCgImage, scale: editImage.scale, orientation: .up)
        
        UIGraphicsBeginImageContextWithOptions(originalImage.size, false, originalImage.scale)
        originalImage.draw(in: renderRect)
        (inputMosaicImage ?? mosaicImage)?.draw(in: renderRect)
        midImage?.draw(at: .zero)
        
        let currentImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cgiImage = currentImage?.cgImage else {
            return nil
        }
        let image = UIImage(cgImage: cgiImage, scale: editImage.scale, orientation: .up)
        
        if inputImage != nil {
            return image
        }
        
        editImage = image
        imageView.image = image
        mosaicImageLayerMaskLayer?.path = nil
        
        return image
    }
}

extension BTImageEditController {
    @objc private func drawAction(_ pan: UIPanGestureRecognizer) {
        guard isDrawingActive else { return }
        if mosaicButton.isSelected {
            let point = pan.location(in: imageView)
            if pan.state == .began {
                UIView.animate(withDuration: 0.4) {
                    self.doneButton.alpha = 0
                    self.doneButton.isUserInteractionEnabled = false
                    
                    for button in self.stackView.arrangedSubviews {
                        button.alpha = 0
                    }
                    
                    self.clearAllButton.alpha = 0
                    self.clearAllButton.isUserInteractionEnabled = false
                    
                    self.colorPickerView.alpha = 0
                    self.colorPickerView.isUserInteractionEnabled = false
                    
                    self.undoButton.alpha = 0
                    self.undoButton.isUserInteractionEnabled = false
                }
                let ratio = min(mainScrollView.frame.width / CGRect(origin: .zero, size: originalImage.size).size.width, mainScrollView.frame.height / CGRect(origin: .zero, size: originalImage.size).size.height)
                
                let pathWidth = mosaicLineWidth / mainScrollView.zoomScale
                let path = MosaicPath(pathWidth: pathWidth, ratio: ratio, startPoint: point)
                
                mosaicImageLayerMaskLayer?.lineWidth = pathWidth
                mosaicImageLayerMaskLayer?.path = path.path.cgPath
                mosaicPaths.append(path)
                drawableObjects.append(Drawable(data: path))
                undoMosaicPaths = mosaicPaths
            } else if pan.state == .changed {
                let path = mosaicPaths.last
                path?.addLine(to: point)
                mosaicImageLayerMaskLayer?.path = path?.path.cgPath
            } else if pan.state == .cancelled || pan.state == .ended {
                
                UIView.animate(withDuration: 0.4) {
                    self.doneButton.alpha = 1
                    self.doneButton.isUserInteractionEnabled = true
                    
                    for button in self.stackView.arrangedSubviews {
                        button.alpha = 1
                    }
                    
                    if !self.drawableObjects.isEmpty {
                        self.undoButton.alpha = 1
                        self.undoButton.isUserInteractionEnabled = true
                        
                        self.clearAllButton.alpha = 1
                        self.clearAllButton.isUserInteractionEnabled = true
                        
                        self.colorPickerView.alpha = 1
                        self.colorPickerView.isUserInteractionEnabled = true
                    }
                }
                generateNewMosaicImage()
            }
        } else {
            let point = pan.location(in: drawingImageView)
            if pan.state == .began {
                let originalRatio = min(mainScrollView.frame.width / originalImage.size.width, mainScrollView.frame.height / originalImage.size.height)
                let ratio = min(mainScrollView.frame.width / CGRect(origin: .zero, size: originalImage.size).width, mainScrollView.frame.height / CGRect(origin: .zero, size: originalImage.size).height)
                let scale = ratio / originalRatio
                
                var size = drawingImageView.frame.size
                size.width /= scale
                size.height /= scale
                UIView.animate(withDuration: 0.4) {
                    self.doneButton.alpha = 0
                    self.doneButton.isUserInteractionEnabled = false
                    
                    for button in self.stackView.arrangedSubviews {
                        button.alpha = 0
                    }
                    
                    self.clearAllButton.alpha = 0
                    self.clearAllButton.isUserInteractionEnabled = false
                    
                    self.colorPickerView.alpha = 0
                    self.colorPickerView.isUserInteractionEnabled = false
                    
                    self.undoButton.alpha = 0
                    self.undoButton.isUserInteractionEnabled = false
                }
                
                var toImageScale = 600 / size.width
                if editImage.size.width / editImage.size.height > 1 {
                    toImageScale = 600 / size.height
                }
                
                let path = DrawPath(pathColor: self.currentDrawColor, pathWidth: self.currentWidth / mainScrollView.zoomScale, ratio: ratio / originalRatio / toImageScale, startPoint: point)
                drawPaths.append(path)
                drawableObjects.append(Drawable(data: path))
                undoDrawPaths = drawPaths
            } else if pan.state == .changed {
                let path = drawPaths.last
                path?.addLine(to: point)
                drawLine()
               
            } else if pan.state == .cancelled || pan.state == .ended {
                
                UIView.animate(withDuration: 0.4) {
                    self.doneButton.alpha = 1
                    self.doneButton.isUserInteractionEnabled = true
                    
                    for button in self.stackView.arrangedSubviews {
                        button.alpha = 1
                    }
                    
                    if !self.drawableObjects.isEmpty {
                        self.undoButton.alpha = 1
                        self.undoButton.isUserInteractionEnabled = true
                        
                        self.clearAllButton.alpha = 1
                        self.clearAllButton.isUserInteractionEnabled = true
                        
                        self.colorPickerView.alpha = 1
                        self.colorPickerView.isUserInteractionEnabled = true
                    }
                }
            }
        }
    }
}

extension BTImageEditController {
    private func buildImage() -> UIImage {
        let imageSize = originalImage.size
        
        UIGraphicsBeginImageContextWithOptions(editImage.size, false, editImage.scale)
        editImage.draw(at: .zero)
        
        drawingImageView.image?.draw(in: CGRect(origin: .zero, size: imageSize))
        
        if !stickersContainer.subviews.isEmpty, let context = UIGraphicsGetCurrentContext() {
            let scale = self.originalImage.size.width / stickersContainer.frame.width
            stickersContainer.subviews.forEach { view in
                (view as? StickerViewAdditional)?.resetState()
            }
            context.concatenate(CGAffineTransform(scaleX: scale, y: scale))
            stickersContainer.layer.render(in: context)
            context.concatenate(CGAffineTransform(scaleX: 1 / scale, y: 1 / scale))
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cgiImage = image?.cgImage else {
            return editImage
        }
        
        return UIImage(cgImage: cgiImage, scale: editImage.scale, orientation: .up)
    }
}

extension BTImageEditController {
    @objc private func showInputTextVC(_ text: String? = nil, textColor: UIColor? = nil, font: UIFont? = nil, bgColor: UIColor? = nil, completion: @escaping (String, UIFont, UIColor, UIColor) -> Void) {
        var bgImage: UIImage?
        var rect = mainScrollView.convert(view.frame, to: containerView)
        rect.origin.x += mainScrollView.contentOffset.x / mainScrollView.zoomScale
        rect.origin.y += mainScrollView.contentOffset.y / mainScrollView.zoomScale
        let scale = originalImage.size.width / imageView.frame.width
        rect.origin.x *= scale
        rect.origin.y *= scale
        rect.size.width *= scale
        rect.size.height *= scale
        
        let inputTextVC = InputTextViewController(image: bgImage, text: text, textColor: textColor, bgColor: bgColor)
        inputTextVC.delegate = self
        
        inputTextVC.endInput = { text, font, textColor, bgColor in
            completion(text, font, textColor, bgColor)
            UIView.animate(withDuration: 0.25) { [weak self] in
                guard let self = self else { return }
                self.inputContainerView.backgroundColor = .clear
                self.inputContainerBottomConstraint.constant = -8
                self.view.layoutIfNeeded()
            }
        }
        
        inputTextVC.modalPresentationStyle = .fullScreen
        showDetailViewController(inputTextVC, sender: nil)
    }
}

extension BTImageEditController {
    @objc private func dismissButtonAction() {
        var textStickers: [(TextStickerState, Int)] = []
        var imageStickers: [(ImageStickerState, Int)] = []
        for (index, view) in stickersContainer.subviews.enumerated() {
            if let textSticker = view as? TextStickerView, let _ = textSticker.label.text {
                textStickers.append((textSticker.state, index))
            } else if let imageSticker = view as? ImageStickerView {
                imageStickers.append((imageSticker.state, index))
            }
        }
        var hasEdit = true
        if drawPaths.isEmpty, mosaicPaths.isEmpty, imageStickers.isEmpty, textStickers.isEmpty {
            hasEdit = false
        }
        
        var resourceImage = originalImage
        if hasEdit {
            resourceImage = buildImage()
        }
        dismiss(animated: true) {
            self.editFinishBlock?(resourceImage!)
        }
    }
}

extension BTImageEditController {
    @objc private func emojiButtonClick() {
        let viewController = EmojiPickerViewController()
        viewController.delegate = self
        viewController.sourceView = self.inputContainerView
        viewController.arrowDirection = .down
        viewController.customHeight = UIScreen.main.bounds.height / 2.25
        present(viewController, animated: true)
    }
}

extension BTImageEditController {
    @objc private func undoButtonClick() {
        if let lastObject = drawableObjects.last {
            if let _ = lastObject.data as? UIView {
                drawableObjects.removeLast()
                if let lastStickerView = stickersContainer.subviews.last {
                    lastStickerView.removeFromSuperview()
                }
            } else if let _ = lastObject.data as? DrawPath {
                drawableObjects.removeLast()
                drawPaths.removeLast()
                drawLine()
            } else if let _ = lastObject.data as? MosaicPath {
                drawableObjects.removeLast()
                mosaicPaths.removeLast()
                generateNewMosaicImage()
            }
        }
    }
}

extension BTImageEditController {
    private func getStickerOriginFrame(_ size: CGSize) -> CGRect {
        let scale = mainScrollView.zoomScale
        let xPosition = (mainScrollView.contentOffset.x - containerView.frame.minX) / scale
        let yPosition = (mainScrollView.contentOffset.y - containerView.frame.minY) / scale
        let width = view.frame.width / scale
        let height = view.frame.height / scale
        
        let rect = containerView.convert(CGRect(x: xPosition, y: yPosition, width: width, height: height), to: stickersContainer)
        let originFrame = CGRect(x: rect.minX + (rect.width - size.width) / 2, y: rect.minY + (rect.height - size.height) / 2, width: size.width, height: size.height)
        return originFrame
    }
}

extension BTImageEditController {
    private func addTextStickersView(_ text: String, textColor: UIColor, font: UIFont? = nil, bgColor: UIColor) {
        guard !text.isEmpty else { return }
        let scale = mainScrollView.zoomScale
        let size = TextStickerView.calculateSize(text: text, width: view.frame.width, font: font)
        let originFrame = getStickerOriginFrame(size)
        
        let textSticker = TextStickerView(text: text, textColor: textColor, font: font, bgColor: bgColor, originScale: 1 / scale, originAngle: 0 , originFrame: originFrame)
        stickersContainer.addSubview(textSticker)
        drawableObjects.append(Drawable(data: textSticker))
        self.undoButton.alpha = 1
        self.clearAllButton.alpha = 1
        textSticker.frame = originFrame
        view.layoutIfNeeded()
        
        configTextSticker(textSticker)
    }
}

extension BTImageEditController {
    private func addImageStickerView(_ image: UIImage) {
        let scale = mainScrollView.zoomScale
        let size = ImageStickerView.calculateSize(image: image, width: view.frame.width)
        let originFrame = getStickerOriginFrame(size)
        
        let imageSticker = ImageStickerView(image: image, originScale: 1 / scale, originAngle: 0, originFrame: originFrame)
        stickersContainer.addSubview(imageSticker)
        drawableObjects.append(Drawable(data: imageSticker))
        self.undoButton.alpha = 1
        self.clearAllButton.alpha = 1
        imageSticker.frame = originFrame
        view.layoutIfNeeded()
        
        configImageSticker(imageSticker)
    }
}

extension BTImageEditController {
    @objc private func dismissKeyboard() {
        self.view.endEditing(true)
    }
}

extension BTImageEditController {
    @objc private func addTextButtonClick() {
        showInputTextVC { [weak self] text, _, textColor, bgColor in
            guard let self = self else { return }
            self.addTextStickersView(text, textColor: textColor, bgColor: bgColor)
        }
    }
}

extension BTImageEditController {
    @objc private func doneButtonAction() {
        self.isDrawingActive = false
        self.penButtonInteractionEnabled = true
        self.colorPickerView.pickerView.alpha = 0
        self.colorPickerView.penButton.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1.00)
    }
}

extension BTImageEditController {
    @objc private func clearAllButtonAction() {
        mosaicPaths.removeAll()
        generateNewMosaicImage()
        stickersContainer.subviews.forEach { view in
            view.removeFromSuperview()
        }
        drawPaths.removeAll()
        drawLine()
        drawableObjects.removeAll()
    }
}

extension BTImageEditController {
    @objc private func setEditTool() {
        self.selectedTool = .mosaic
    }
}

extension BTImageEditController {
    @objc private func thicknessButtonPressed(_ sender: UIButton) {
        if sender.isSelected { return }
        
        let buttons: [UIButton] = [normalThickness, halfThickness, veryThickness, mosaicButton]
        UIView.animate(withDuration: 0.4) {
            for button in buttons {
                button.isSelected = button == sender
                button.layer.backgroundColor = button.isSelected ? UIColor(white: 0.7, alpha: 0.5).cgColor : UIColor.clear.cgColor
            }
        }
    }
}

extension BTImageEditController {
    private func configImageSticker(_ imageSticker: ImageStickerView) {
        imageSticker.delegate = self
        mainScrollView.pinchGestureRecognizer?.require(toFail: imageSticker.pinchGesture)
        mainScrollView.panGestureRecognizer.require(toFail: imageSticker.panGesture)
        panGesture.require(toFail: imageSticker.panGesture)
    }
}

extension BTImageEditController {
    private func configTextSticker(_ textSticker: TextStickerView) {
        textSticker.delegate = self
        mainScrollView.pinchGestureRecognizer?.require(toFail: textSticker.pinchGesture)
        mainScrollView.panGestureRecognizer.require(toFail: textSticker.panGesture)
        panGesture.require(toFail: textSticker.panGesture)
    }
}

extension BTImageEditController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = (scrollView.frame.width > scrollView.contentSize.width) ? (scrollView.frame.width - scrollView.contentSize.width) * 0.5 : 0
        let offsetY = (scrollView.frame.height > scrollView.contentSize.height) ? (scrollView.frame.height - scrollView.contentSize.height) * 0.5 : 0
        containerView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
    }
}

extension BTImageEditController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if colorPickerView.bounds.contains(touch.location(in: colorPickerView)) {
            return false
        }
        return true
    }
}

extension BTImageEditController {
    @objc private func thinWidth() {
        self.currentWidth = 4
        self.selectedTool = .draw
    }
    
    @objc private func mediumWidth() {
        self.currentWidth = 7
        self.selectedTool = .draw
    }
    
    @objc private func thickWidth() {
        self.currentWidth = 11
        self.selectedTool = .draw
    }
}

extension BTImageEditController: @preconcurrency EmojiPickerDelegate {
    public func didGetEmoji(emoji: String) {
        guard let image = emoji.image() else { return }
        addImageStickerView(image)
    }
}

extension BTImageEditController: StickerViewDelegate {
    func stickerBeginOperation(_ sticker: UIView) {
        setToolView(show: false)
        trashView.layer.removeAllAnimations()
        trashView.isHidden = false
        var frame = trashView.frame
        let diff = view.frame.height - frame.minY
        frame.origin.y += diff
        trashView.frame = frame
        frame.origin.y -= diff
        UIView.animate(withDuration: 0.25) {
            self.trashView.frame = frame
        }
        
        stickersContainer.subviews.forEach { view in
            if view !== sticker {
                (view as? StickerViewAdditional)?.resetState()
                (view as? StickerViewAdditional)?.gesIsEnabled = false
            }
        }
    }
    
    func stickerOnOperation(_ sticker: UIView, panGesture: UIPanGestureRecognizer) {
        let point = panGesture.location(in: view)
        if trashView.frame.contains(point) {
            trashView.backgroundColor = .red
            trashImageView.isHighlighted = true
            if sticker.alpha == 1 {
                sticker.layer.removeAllAnimations()
                UIView.animate(withDuration: 0.25) {
                    sticker.alpha = 0.5
                }
            }
        } else {
            trashView.backgroundColor = .systemGray
            trashImageView.isHighlighted = false
            if sticker.alpha != 1 {
                sticker.layer.removeAllAnimations()
                UIView.animate(withDuration: 0.25) {
                    sticker.alpha = 1
                }
            }
        }
    }
    
    func stickerEndOperation(_ sticker: UIView, panGesture: UIPanGestureRecognizer) {
        setToolView(show: true)
        trashView.layer.removeAllAnimations()
        trashView.isHidden = true
        
        let point = panGesture.location(in: view)
        if trashView.frame.contains(point) {
            (sticker as? StickerViewAdditional)?.moveToTrashView()
            self.drawableObjects.removeLast()
        }
        
        stickersContainer.subviews.forEach { view in
            (view as? StickerViewAdditional)?.gesIsEnabled = true
        }
        
        defer {
            self.undoButton.alpha = self.drawableObjects.isEmpty ? 0 : 1
            self.clearAllButton.alpha = self.drawableObjects.isEmpty ? 0 : 1
        }
    }
    
    func stickerDidTap(_ sticker: UIView) {
        stickersContainer.subviews.forEach { view in
            if view !== sticker {
                (view as? StickerViewAdditional)?.resetState()
            }
        }
    }
    
    func sticker(_ textSticker: TextStickerView, editText text: String) {
        showInputTextVC(text, textColor: textSticker.textColor, font: textSticker.textFont, bgColor: textSticker.backgroundColor) { [weak self] text, font, textColor, bgColor in
            guard let self = self else { return }
            if text.isEmpty {
                textSticker.moveToTrashView()
            } else {
                guard textSticker.text != text || textSticker.textColor != textColor || textSticker.backgroundColor != bgColor else {
                    return
                }
                textSticker.text = text
                textSticker.textColor = textColor
                textSticker.backgroundColor = bgColor
                textSticker.textFont = font
                let newSize = TextStickerView.calculateSize(text: text, width: self.view.frame.width, font: font)
                textSticker.changeSize(to: newSize)
            }
        }
    }
}

extension BTImageEditController: DrawingColorPickerViewDelegate {
    func colorPicked(_ color: CGColor) {
        let color = UIColor(cgColor: color)
        self.currentDrawColor = color
    }
    
    func setIsActiveTo(_ isActive: Bool) {
        if penButtonInteractionEnabled {
            self.isDrawingActive = true
            self.colorPickerView.pickerView.alpha = 1
        }
    }
}

extension BTImageEditController: TextViewControllerProtocol {
    func cancelButtonPressed() {
        UIView.animate(withDuration: 0.25) { [weak self] in
            guard let self = self else { return }
            self.inputContainerView.backgroundColor = .clear
            self.inputContainerBottomConstraint.constant = -8
            self.view.layoutIfNeeded()
        }
    }
}

extension BTImageEditController {
    @objc enum EditTool: Int {
        case draw
        case imageSticker
        case textSticker
        case mosaic
    }
}
