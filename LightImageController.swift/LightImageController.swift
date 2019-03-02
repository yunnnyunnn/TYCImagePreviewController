//
//  LightImageController.swift
//  Poweather
//
//  Created by Ting-Yang Chen on 1/28/18.
//  Copyright © 2018 Ting Yang Chen. All rights reserved.
//

import UIKit
import AVFoundation

fileprivate enum LIMediaType {
    case image
    case video
}

open class LightImageController: UIViewController {
    
    private var presentingWindow: UIWindow?
    
    fileprivate let minimumBackgroundAlpha: CGFloat = 0.25
    fileprivate let maximumBackgroundAlpha: CGFloat = 1.0
    fileprivate let type: LIMediaType
    fileprivate let image: UIImage?
    fileprivate let videoURL: URL?
    fileprivate var imageView: UIImageView!
    fileprivate var videoPreviewView: UIView!
    fileprivate var initialCenter = CGPoint()
    fileprivate var avPlayer: AVPlayer! = nil
    fileprivate var avPlayerLayer: AVPlayerLayer! = nil
    fileprivate var panGestureRecognizer: UIPanGestureRecognizer! = nil
    fileprivate var doubleTapGestureRecognizer: UITapGestureRecognizer! = nil
    fileprivate var scrollView: UIScrollView! = nil

    public convenience init(image: UIImage) {
        self.init(imageOrVideoURL: image, type: .image)
    }
    
    public convenience init(videoURL: URL) {
        self.init(imageOrVideoURL: videoURL, type: .video)
    }
    
    fileprivate init(imageOrVideoURL: Any, type: LIMediaType) {
        
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
        
        // Set up scroll view.
        self.scrollView = UIScrollView()
        self.scrollView.delegate = self
        self.scrollView.maximumZoomScale = 6.0
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        self.view.addSubview(self.scrollView)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": self.scrollView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": self.scrollView]))
        
        // Add pan gesture.
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.pan(gestureRecognizer:)))
        self.scrollView.addGestureRecognizer(self.panGestureRecognizer)

        // Add double tap gesture.
        self.doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tap(gestureRecognizer:)))
        self.doubleTapGestureRecognizer.numberOfTapsRequired = 2
        self.scrollView.addGestureRecognizer(self.doubleTapGestureRecognizer)


        if self.type == .image, let image = self.image {
            
            // Configure image view.
            self.imageView.image = image
            self.imageView.contentMode = .scaleAspectFit
            self.imageView.isUserInteractionEnabled = false
            self.imageView.frame = CGRect(origin: .zero, size: self.scrollView.bounds.size)
            self.scrollView.addSubview(self.imageView)
            
        } else if self.type == .video, let videoURL = self.videoURL {
            
            // Configure.
            self.videoPreviewView.backgroundColor = UIColor.clear
            self.videoPreviewView.isUserInteractionEnabled = false
            
            // Set up player.
            self.avPlayer = AVPlayer(url: videoURL)
            self.avPlayerLayer = AVPlayerLayer(player: self.avPlayer)
            self.avPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
            self.avPlayer.volume = 1.0
            self.avPlayer.actionAtItemEnd = .none
            
            self.avPlayerLayer.frame = self.videoPreviewView.layer.bounds
            self.videoPreviewView.layer.insertSublayer(self.avPlayerLayer, at: 0)
            
            self.scrollView.addSubview(self.videoPreviewView)
            
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
            self.videoPreviewView.frame = CGRect(origin: .zero, size: self.scrollView.bounds.size)
            self.avPlayerLayer.frame = self.videoPreviewView.layer.bounds
        } else {
            self.imageView.frame = CGRect(origin: .zero, size: self.scrollView.bounds.size)
        }
        // Setting the zoom scale back after layout helps position the media back to center.
        self.scrollView.setZoomScale(1.0, animated: false)
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // Cancel the pan tracking before screen rotation happens.
        self.panGestureRecognizer.isEnabled = false
        self.panGestureRecognizer.isEnabled = true
        // Setting the zoom scale back before layout helps position the media back to center.
        self.scrollView.setZoomScale(1.0, animated: false)
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
        let blankViewController = LIBlankViewController()
        blankViewController.view.backgroundColor = UIColor.clear
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = blankViewController
        window.backgroundColor = UIColor.clear
        window.windowLevel = UIWindow.Level.alert + 1
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
    
    @objc fileprivate func tap(gestureRecognizer : UIPanGestureRecognizer) {
        // Doulbe tap to zoom.
        if self.scrollView.zoomScale == 1.0 {
            self.scrollView.zoom(to: self.zoomRectForScale(scale: 4.0,
                                                           center: gestureRecognizer.location(in: gestureRecognizer.view)),
                                 animated: true)
        } else {
            self.scrollView.setZoomScale(1.0, animated: true)
        }
    }
    
    fileprivate func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width  = imageView.frame.size.width  / scale
        let newCenter = self.imageView.convert(center, from: self.scrollView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
    // MARK: - Notification Handler.
    
    @objc fileprivate func playerItemDidReachEnd(notification: Notification) {
        if let item = notification.object as? AVPlayerItem {
            item.seek(to: CMTime.zero)
        }
    }
    
}

extension LightImageController: UIScrollViewDelegate {
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if self.type == .video {
            return self.videoPreviewView
        } else {
            return self.imageView
        }
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.panGestureRecognizer.isEnabled = (scrollView.zoomScale == 1.0)
    }
}

class LIBlankViewController: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIApplication.shared.statusBarStyle
    }
}
