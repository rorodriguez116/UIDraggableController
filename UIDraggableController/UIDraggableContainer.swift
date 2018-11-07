//
//  BaseSlidingViewController.swift
//  SlideOutMenu
//
//  Created by Rolando Rodriguez on 10/16/18.
//  Copyright © 2018 TheAppFactory. All rights reserved.
//

import UIKit

public enum ViewControllerPosition {
    case top
    case bottom
    case left
    case right
    case center
    case none
}

public enum TransitionFlow {
    case right
    case left
    
    static func get(translation: CGPoint) -> TransitionFlow {
        return translation.x < 0 ? .right : .left
    }
}

open class UIDraggableController: UIViewController {
    
    fileprivate let velocityOpenThreshold: CGFloat = 500

    fileprivate let redView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .red
        return view
    }()
    
    fileprivate let blueView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .blue
        return view
    }()
    
    fileprivate let greenView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .green
        return view
    }()
    
    
    fileprivate let darkCoverView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0, alpha: 0.7)
        v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    fileprivate var redViewLeadingConstraint: NSLayoutConstraint!
    fileprivate var  leftVCWidth: CGFloat!
    fileprivate var  rightVCWidth: CGFloat!
    fileprivate var isMenuOpened: Bool = false
    fileprivate var showingPosition: ViewControllerPosition = .center
    fileprivate var warningLabel: UILabel! = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.text = "FatalError: You're seeing this message because you haven't properly configure DraggableUI's ViewControllers"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.numberOfLines = 6
        label.textAlignment = .center
        return label
    }()
    
    public var centerController: UIViewController?
    public var leftController: UIViewController?
    public var rightController: UIViewController?
    public var preferredMenuSide: ViewControllerPosition = .none
    public var rightViewControllerDidShow: (() -> ())?
    public var rightViewControllerWillShow: (() -> ())?
    public var leftViewControllerDidShow: (() -> ())?
    public var leftViewControllerWillShow: (() -> ())?
    public var rightViewControllerDidDisappear: (() -> ())?
    public var rightViewControllerWillDisappear: (() -> ())?
    public var leftViewControllerWillDisappear: (() -> ())?
    public var leftViewControllerDidDisappear: (() -> ())?
    public var onPanToLeftViewController: ((UIPanGestureRecognizer) -> ())?
    public var onPanToRightViewController: ((UIPanGestureRecognizer) -> ())?


    override open func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        configureRecognizer()
        configureWarningLabel()
    }
    
    fileprivate func configureRecognizer(){
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        panGesture.delegate = self 
        self.view.addGestureRecognizer(panGesture)
    }
    
    fileprivate func configureWarningLabel(){
        view.addSubview(warningLabel)
        warningLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -100).isActive = true
        warningLabel.heightAnchor.constraint(equalToConstant: 300).isActive = true
        warningLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        warningLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    @objc fileprivate func handlePan(gesture: UIPanGestureRecognizer){
        let translation = gesture.translation(in: self.view)
        var x = translation.x 
        
        x = showingPosition == .left ? x + leftVCWidth : x
        x = showingPosition == .right ? x - rightVCWidth : x

        x = min(x, leftVCWidth)
        x = min(x, rightVCWidth)

        x = x > 0 ? max(0, x) : min(0, x)
        if x > 0 {
            onPanToLeftViewController?(gesture)
        } else {
            onPanToRightViewController?(gesture)
        }
        
        redViewLeadingConstraint.constant = x
        if preferredMenuSide != .none {
            darkCoverView.alpha = preferredMenuSide == .left ? (x / leftVCWidth) : (-x / rightVCWidth)
        }

        if gesture.state == .ended {
            handleEnded(gesture: gesture)
        }
    }
    fileprivate func handleForLeftPosition(_ velocity: CGPoint, _ translation: CGPoint) {
        if abs(velocity.x) > velocityOpenThreshold {
            showCenterVC()
            return
        }
        
        shouldShowLeftVC(translation)
    }
    
    fileprivate func handleForRightPosition(_ velocity: CGPoint, _ translation: CGPoint){
        if abs(velocity.x) > velocityOpenThreshold {
            showCenterVC()
            return
        }
        
        shouldShowRightVC(translation)
    }

    
    fileprivate func handleForCenterPosition(_ velocity: CGPoint, _ translation: CGPoint) {
        
        if TransitionFlow.get(translation: translation) == .right {
            if abs(velocity.x) > velocityOpenThreshold {
                showRightVC()
                return
            }
            shouldShowRightVC(translation)
        } else {
            if abs(velocity.x) > velocityOpenThreshold {
                showLeftVC()
                return
            }
            shouldShowLeftVC(translation)
        }
    }
    
    
    fileprivate func shouldShowRightVC(_ translation: CGPoint){
        if abs(translation.x) > rightVCWidth / 2 {
            showRightVC()
        } else {
            showCenterVC()
        }
    }
    
    fileprivate func shouldShowLeftVC(_ translation: CGPoint){
        if abs(translation.x) > leftVCWidth / 2 {
            showLeftVC()
        } else {
            showCenterVC()
        }
    }
    
    
    fileprivate func handleEnded(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch showingPosition {
        case .left: handleForLeftPosition(velocity, translation)
        case .right: handleForRightPosition(velocity, translation)
        case .center: handleForCenterPosition(velocity, translation)

        default:
            print("Showing either top or bottom VC, not supported yet")
        }
    }
    
    open func showLeftVC(performCompletionBlock: Bool = true) {
        isShowingViewController(at: .left)
        redViewLeadingConstraint.constant = leftVCWidth
        performAnimations {
            self.leftViewControllerDidShow?()
        }
        if performCompletionBlock {
            leftViewControllerWillShow?()
        }
    }
    
    public func showCenterVC() {
        redViewLeadingConstraint.constant = 0
        isShowingViewController(at: .center)
        performAnimations {
            self.leftViewControllerDidDisappear?()
            self.rightViewControllerDidDisappear?()
        }
        self.leftViewControllerWillDisappear?()
        self.rightViewControllerWillDisappear?()
    }
    
    public func showRightVC(performWillShow: Bool = true){
        isShowingViewController(at: .right)
        redViewLeadingConstraint.constant = -rightVCWidth
        performAnimations {
            self.rightViewControllerDidShow?()
        }
        
        if performWillShow {
            self.rightViewControllerWillShow?()
        }
    }
    
    
    fileprivate func isShowingViewController(at position: ViewControllerPosition){
        self.showingPosition = position
    }
    
    
    fileprivate func performAnimations(completion: (() -> ())? = nil) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            self.darkCoverView.alpha = self.showingPosition == self.preferredMenuSide ? 1 : 0
        }, completion: { (completed) in
            completion?()
        })
    }
    
    public func setupViewControllers(left: UIViewController?, leftWidth: CGFloat? = 300, center: UIViewController!, right: UIViewController?, rightWidth: CGFloat? = 300) {
        leftVCWidth = leftWidth
        rightVCWidth = rightWidth
        configure(centerViewController: center)
        configure(leftViewController: left)
        configureRight(rightViewController: right)
        warningLabel.removeFromSuperview()
        warningLabel = nil
    }
    
    fileprivate func configure(centerViewController: UIViewController!){
        guard let controller = centerViewController, let centerView = centerViewController.view else {fatalError("Can't configure DragableUI without a center view controller, make sure this property isn't nil")}
        
        centerView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(redView)
        
        NSLayoutConstraint.activate([
            redView.topAnchor.constraint(equalTo: self.view.topAnchor),
            redView.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            redView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        redViewLeadingConstraint = redView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        redViewLeadingConstraint.isActive = true

        redView.addSubview(centerView)
        redView.addSubview(darkCoverView)
        
        
        NSLayoutConstraint.activate([
            centerView.topAnchor.constraint(equalTo: redView.topAnchor),
            centerView.leadingAnchor.constraint(equalTo: redView.leadingAnchor),
            centerView.bottomAnchor.constraint(equalTo: redView.bottomAnchor),
            centerView.trailingAnchor.constraint(equalTo: redView.trailingAnchor),
            
            darkCoverView.topAnchor.constraint(equalTo: redView.topAnchor),
            darkCoverView.leadingAnchor.constraint(equalTo: redView.leadingAnchor),
            darkCoverView.bottomAnchor.constraint(equalTo: redView.bottomAnchor),
            darkCoverView.trailingAnchor.constraint(equalTo: redView.trailingAnchor),
            
            ])
        
        addChild(controller)
    }
    
    fileprivate func configure(leftViewController: UIViewController?){
        guard let controller = leftViewController, let leftView = controller.view else {return}
        
        leftView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(blueView)

        NSLayoutConstraint.activate([
            blueView.topAnchor.constraint(equalTo: self.view.topAnchor),
            blueView.trailingAnchor.constraint(equalTo: self.redView.safeAreaLayoutGuide.leadingAnchor),
            blueView.bottomAnchor.constraint(equalTo: self.redView.bottomAnchor),
            blueView.widthAnchor.constraint(equalToConstant: leftVCWidth)
            ])
        
        blueView.addSubview(leftView)
        NSLayoutConstraint.activate([
            leftView.topAnchor.constraint(equalTo: blueView.topAnchor),
            leftView.trailingAnchor.constraint(equalTo: blueView.trailingAnchor),
            leftView.bottomAnchor.constraint(equalTo: blueView.bottomAnchor),
            leftView.leadingAnchor.constraint(equalTo: blueView.leadingAnchor)
        ])
        
        addChild(controller)
    }
    
    fileprivate func configureRight(rightViewController: UIViewController?){
        guard let controller = rightViewController, let rightView = controller.view else {return}
        
        rightView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(greenView)
        
        NSLayoutConstraint.activate([
            greenView.topAnchor.constraint(equalTo: self.view.topAnchor),
            greenView.leadingAnchor.constraint(equalTo: self.redView.safeAreaLayoutGuide.trailingAnchor),
            greenView.bottomAnchor.constraint(equalTo: self.redView.bottomAnchor),
            greenView.widthAnchor.constraint(equalToConstant: rightVCWidth)
        ])
        
        greenView.addSubview(rightView)
        
        NSLayoutConstraint.activate([
            rightView.topAnchor.constraint(equalTo: greenView.topAnchor),
            rightView.trailingAnchor.constraint(equalTo: greenView.trailingAnchor),
            rightView.bottomAnchor.constraint(equalTo: greenView.bottomAnchor),
            rightView.leadingAnchor.constraint(equalTo: greenView.leadingAnchor)
        ])
        
        addChild(controller)
    }
}

extension UIViewController {
    
    open var draggableController: UIDraggableController? {
        get {
            var parentViewController = self.parent
            while (parentViewController != nil) {
                if let swipeNavigationController = parentViewController as? UIDraggableController {
                    return swipeNavigationController
                }
                parentViewController = parentViewController?.parent
            }
            return nil
        }
    }
}

extension UIDraggableController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {return false}
        let translation = pan.translation(in: self.view)
        return (showingPosition == .right && translation.x < 0) ? false : true
    }
}
