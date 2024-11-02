//
//  InputTextViewController.swift
//  BTImageEditor
//
//  Created by Ensar Batuhan Ünverdi on 2.11.2024.
//

import UIKit

@MainActor
protocol TextViewControllerProtocol: AnyObject {
    func cancelButtonPressed()
}

final class InputTextViewController: UIViewController {
    
    private let image: UIImage?
    private var text: String
    private var cancelButton: UIButton!
    private var doneButton: UIButton!
    private var textView: UITextView!
    private var currentTextColor: UIColor = .white
    private var collectionView: UICollectionView!
    
    /// text, textColor, bgColor
    var endInput: ((String, UIFont, UIColor, UIColor) -> Void)?
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    weak var delegate: TextViewControllerProtocol?
    
    init(image: UIImage?, text: String? = nil, textColor: UIColor? = nil, bgColor: UIColor? = nil) {
        self.image = image
        self.text = text ?? ""
        if let textColor = textColor {
            currentTextColor = textColor
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("BTImageEditor: init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIApplication.keyboardWillShowNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textView.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        var insets = UIEdgeInsets.zero
        if #available(iOS 11.0, *) {
            insets = self.view.safeAreaInsets
        }
        
        let buttonYAxis = insets.top + 20
        cancelButton.frame = CGRect(x: 15, y: buttonYAxis, width: 90, height: 40)
        doneButton.frame = CGRect(x: view.bounds.width - 20 - 90, y: buttonYAxis, width: 90, height: 40)
        
        textView.frame = CGRect(x: 20, y: cancelButton.frame.maxY + 20, width: view.bounds.width - 40, height: 150)
        if let index = ImageEditorConfiguration.shared.textColors.firstIndex(where: { $0 == self.currentTextColor }) {
            collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: false)
        }
        
    }
    
    func setupUI() {
        setupView()
        setupButtons()
        setupTextView()
        setupCollectionView()
    }
    
    @objc func cancelButtonClick() {
        delegate?.cancelButtonPressed()
        dismiss(animated: true, completion: nil)
    }
    
    @objc func doneButtonClick() {
        let content = textView.text.trimmingCharacters(in: .newlines)
        endInput?(content, textView.font ?? UIFont.systemFont(ofSize: TextStickerView.fontSize), currentTextColor, .clear)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func keyboardWillShow(_ notify: Notification) {
        let rect = notify.userInfo?[UIApplication.keyboardFrameEndUserInfoKey] as? CGRect
        let keyboardHeight = rect?.height ?? 366
        let duration: TimeInterval = notify.userInfo?[UIApplication.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        
        UIView.animate(withDuration: max(duration, 0.25)) {
            self.collectionView.frame = CGRect(x: 0, y: self.view.frame.height - keyboardHeight - 50, width: self.view.frame.width, height: 50)
        }
    }
}

extension InputTextViewController {
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 30, height: 30)
        layout.minimumLineSpacing = 15
        layout.minimumInteritemSpacing = 15
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 10, left: 30, bottom: 10, right: 30)
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: view.frame.height - 50, width: view.frame.width, height: 50), collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        view.addSubview(collectionView)
        
        collectionView.register(DrawColorCell.self, forCellWithReuseIdentifier: DrawColorCell.identifier)
    }
    
    private func setupTextView() {
        textView = UITextView(frame: .zero)
        textView.keyboardAppearance = .dark
        textView.returnKeyType = .done
        textView.indicatorStyle = .white
        textView.delegate = self
        textView.backgroundColor = .clear
        textView.tintColor = .white
        textView.textColor = currentTextColor
        textView.text = text
        textView.font = UIFont.boldSystemFont(ofSize: TextStickerView.fontSize)
        view.addSubview(textView)
    }
    
    private func setupButtons() {
        cancelButton = UIButton(type: .custom)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonClick), for: .touchUpInside)
        view.addSubview(cancelButton)
        
        doneButton = UIButton(type: .custom)
        doneButton.setTitle("Done", for: .normal)
        doneButton.addTarget(self, action: #selector(doneButtonClick), for: .touchUpInside)
        view.addSubview(doneButton)
    }
    
    private func setupView() {
        view.backgroundColor = .black
    }
}

extension InputTextViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            doneButtonClick()
            return false
        }
        return true
    }
}

extension InputTextViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ImageEditorConfiguration.shared.textColors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DrawColorCell.identifier, for: indexPath) as! DrawColorCell
        
        let colors = ImageEditorConfiguration.shared.textColors[indexPath.row]
        cell.color = colors
        if colors == currentTextColor {
            cell.backgroundWhiteView.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1)
        } else {
            cell.backgroundWhiteView.layer.transform = CATransform3DIdentity
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        currentTextColor = ImageEditorConfiguration.shared.textColors[indexPath.row]
        textView.textColor = currentTextColor
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        collectionView.reloadData()
    }
}

