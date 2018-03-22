//
//  TYCImagePreviewController.swift
//  Poweather
//
//  Created by Ting-Yang Chen on 1/28/18.
//  Copyright © 2018 Ting Yang Chen. All rights reserved.
//

import UIKit
import AVFoundation

fileprivate enum TYCImagePreviewType {
    case image
    case video
}

open class TYCImagePreviewController: UIViewController {
    
    private var presentingWindow: UIWindow?
    
    fileprivate let minimumBackgroundAlpha: CGFloat = 0.25
    fileprivate let maximumBackgroundAlpha: CGFloat = 1.0
    fileprivate let type: TYCImagePreviewType
    fileprivate let image: UIImage?
    fileprivate let videoURL: URL?
    fileprivate var imageView: UIImageView!
    fileprivate var videoPreviewView: UIView!
    fileprivate var initialCenter = CGPoint()
    fileprivate var avPlayer: AVPlayer! = nil
    fileprivate var avPlayerLayer: AVPlayerLayer! = nil
    fileprivate var panGestureRecognizer: UIPanGestureRecognizer! = nil
    
    public convenience init(image: UIImage) {
        self.init(imageOrVideoURL: image, type: .image)
    }
    
    public convenience init(videoURL: URL) {
        self.init(imageOrVideoURL: videoURL, type: .video)
    }
    
    fileprivate init(imageOrVideoURL: Any, type: TYCImagePreviewType) {
        
        self.type = type
        if type == .image {
            self.image = imageOrVideoURL as? UIImage
            self.videoURL = nil
        } else {
            self.image = nil
            self.videoURL = imageOrVideoURL as? URL
        }
        
        super.init(nibName: nil, bundle: nil)
        
        // Set modal style so the view will be presented on current context.
        self.modalPresentationStyle = .overCurrentContext
        self.modalTransitionStyle = .crossDissolve
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.black.withAlphaComponent(self.maximumBackgroundAlpha)
        
        // Init views.
        self.imageView = UIImageView()
        self.videoPreviewView = UIView(frame: self.view.bounds)
        
        if self.type == .image, let image = self.image {
            
            // Set up image view.
            self.view.addSubview(self.imageView)
            self.imageView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": self.imageView]))
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": self.imageView]))
            
            // Configure.
            self.imageView.image = image
            self.imageView.contentMode = .scaleAspectFit
            self.imageView.isUserInteractionEnabled = true
            
            // Add pan gesture.
            self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.pan(gestureRecognizer:)))
            self.imageView.addGestureRecognizer(self.panGestureRecognizer)
            
        } else if self.type == .video, let videoURL = self.videoURL {
            
            // Set up video preview.
            self.view.addSubview(self.videoPreviewView)
            self.videoPreviewView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": self.videoPreviewView]))
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": self.videoPreviewView]))
            
            // Configure.
            self.videoPreviewView.backgroundColor = UIColor.clear
            self.videoPreviewView.isUserInteractionEnabled = true
            
            // Add pan gesture.
            self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.pan(gestureRecognizer:)))
            self.videoPreviewView.addGestureRecognizer(self.panGestureRecognizer)
            
            // Set up player.
            self.avPlayer = AVPlayer(url: videoURL)
            self.avPlayerLayer = AVPlayerLayer(player: self.avPlayer)
            self.avPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
            self.avPlayer.volume = 1.0
            self.avPlayer.actionAtItemEnd = .none
            
            self.avPlayerLayer.frame = self.videoPreviewView.layer.bounds
            self.videoPreviewView.layer.insertSublayer(self.avPlayerLayer, at: 0)
            
            // Make it replay when the video reaches an end.
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.playerItemDidReachEnd(notification:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.avPlayer.currentItem)
            
        }
        
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Start playing video if this is a video preview.
        if self.type == .video {
            self.avPlayer.play()
        }
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Stop playing video if this is a video preview.
        if self.type == .video {
            self.avPlayer.pause()
        }
        // Remove presenting window.
        self.presentingWindow?.isHidden = true
        self.presentingWindow = nil
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update the player frame when view size changes.
        if self.type == .video {
            self.avPlayerLayer.frame = self.videoPreviewView.layer.bounds
        }
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // Cancel the pan tracking before screen rotation happens.
        self.panGestureRecognizer.isEnabled = false
        self.panGestureRecognizer.isEnabled = true
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    public func show(animated: Bool) {
        // Use this blank view controller to present alert.
        let blankViewController = TYCBlankViewController()
        blankViewController.view.backgroundColor = UIColor.clear
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = blankViewController
        window.backgroundColor = UIColor.clear
        window.windowLevel = UIWindowLevelAlert + 1
        window.makeKeyAndVisible()
        window.rootViewController?.present(self, animated: animated, completion: {
            
        })
        self.presentingWindow = window
    }
    
    // MARK: - Gesture Handler.
    
    @objc fileprivate func pan(gestureRecognizer : UIPanGestureRecognizer) {
        
        // Check if we have a view to move.
        guard let view = gestureRecognizer.view else {
            return
        }
        
        // Get the changes in the X and Y directions relative to
        // the superview's coordinate space
        let translation = gestureRecognizer.translation(in: view.superview)
        
        // Save initial center.
        if gestureRecognizer.state == .began {
            self.initialCenter = view.center
        }
        
        // if not cancelling, move the image view anyway. We will check if we need to move it back afterward.
        if gestureRecognizer.state != .cancelled {
            
            // Add the X and Y translation to the view's original position.
            let newCenter = CGPoint(x: self.initialCenter.x + translation.x, y: self.initialCenter.y + translation.y)
            view.center = newCenter
            
            // Change the background color.
            var multiplier = 1 - (abs(translation.y) / (self.view.bounds.height / 2))
            if multiplier < 0 { multiplier = 0 }
            let newAlpha = (multiplier * (self.maximumBackgroundAlpha - self.minimumBackgroundAlpha)) + self.minimumBackgroundAlpha
            self.view.backgroundColor = UIColor.black.withAlphaComponent(newAlpha)
            
        } else {
            // Bounce back.
            UIView.animate(withDuration: 0.25, animations: {
                view.center = self.initialCenter
                self.view.backgroundColor = UIColor.black.withAlphaComponent(self.maximumBackgroundAlpha)
            })
        }
        
        if gestureRecognizer.state == .ended {
            let movedFactor = translation.y / (self.view.bounds.height / 2)
            if abs(movedFactor) > 0.3 {
                
                let multiplier: CGFloat = movedFactor > 0 ? 1 : -1
                let newCenter = CGPoint(x: self.initialCenter.x, y: self.initialCenter.y + (self.view.bounds.height * multiplier) )
                
                // Animation before dismiss.
                UIView.animate(withDuration: 0.25, animations: {
                    view.center = newCenter
                    self.view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
                }, completion: { (finished) in
                    self.dismiss(animated: false, completion: {
                        
                    })
                })
                
            } else {
                // Bounce back.
                UIView.animate(withDuration: 0.25, animations: {
                    view.center = self.initialCenter
                    self.view.backgroundColor = UIColor.black.withAlphaComponent(self.maximumBackgroundAlpha)
                })
            }
        }
        
    }
    
    // MARK: - Notification Handler.
    
    @objc fileprivate func playerItemDidReachEnd(notification: Notification) {
        if let item = notification.object as? AVPlayerItem {
            item.seek(to: kCMTimeZero)
        }
    }
    
}

class TYCBlankViewController: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIApplication.shared.statusBarStyle
    }
}
