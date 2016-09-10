//
//  ViewController.swift
//  AnimatedImageDemo
//
//  Created by kaizei on 16/1/12.
//  Copyright © 2016年 kaizei. All rights reserved.
//

import UIKit
import XLYAnimatedImage

enum PlayType {
    case gifImage
    case frameImages
    case staticImage
    
    var description: String {
        switch self {
        case .gifImage: return "GIF"
        case .frameImages: return "Frames"
        case .staticImage: return "Static"
        }
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var replayIfSameSwitch: UISwitch!
    
    @IBOutlet weak var framesLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var linkFrameIntervalLabel: UILabel!
    
    var type: PlayType!
    private var images: [AnimatedImage?]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let type = type else { return }
        switch type {
        case .gifImage:
            // default scale is screen's scale.
            let AnimatedDataImage0 = AnimatedDataImage(data: try! Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "shot@2x", ofType: "gif")!)), scale: 2)
            let AnimatedDataImage1 = AnimatedDataImage(data: try! Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "cat@2x", ofType: "gif")!)), scale: 2)
            images = [AnimatedDataImage0, AnimatedDataImage1]
            imageView.contentMode = .center
            
        case .frameImages:
            segmentedControl.removeSegment(at: 1, animated: false)
            let image = UIImage.animatedImage(with: (0...9).map({ UIImage(named: "qiaoba\($0)")! }), duration: 0.1)!
            images = [AnimatedFrameImage(animatedUIImage: image)]
            imageView.contentMode = .scaleAspectFit
        
        case .staticImage:
            segmentedControl.removeSegment(at: 1, animated: false)
            let image = AnimatedDataImage(data: try! Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "zuoluo", ofType: "jpg")!)), scale: 2)
            images = [image]
            imageView.contentMode = .scaleAspectFill
        }
        
        segmentedControl.selectedSegmentIndex = UISegmentedControlNoSegment
        
        imageView.xly_animatedImagePlayer.onTimeElapse = {[weak self] time in
            guard let image = self?.imageView.xly_animatedImagePlayer.image else {
                self?.timeSlider.value = 0
                self?.timeLabel.text = "0.00"
                self?.framesLabel.text = "0"
                return
            }
            self?.timeSlider.value = Float(time / image.totalTime)
            self?.timeLabel.text = NSString(format: "%.02f/%.02f", time, image.totalTime) as String
        }
        
        imageView.xly_setAnimatedImage(images[0])
        framesLabel.text = "\(images[0]?.frameCount ?? 0)"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        imageView.xly_animatedImagePlayer.paused = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        imageView.xly_animatedImagePlayer.paused = true
    }
    
    @IBAction func changeTime(_ sender: UISlider) {
        if let total = imageView.xly_animatedImagePlayer.image?.totalTime {
            imageView.xly_animatedImagePlayer.move(toTime: total * Double(sender.value))
        }
    }
    
    @IBAction func changeImage(_ sender: UISegmentedControl) {
        let image = sender.selectedSegmentIndex == 0 ? images[0] : images[1]
        imageView.xly_setAnimatedImage(image, replay: replayIfSameSwitch.isOn)
        framesLabel.text = "\(image?.frameCount ?? 0)"
    }
    
    @IBAction func panOnSpeedSlider(_ sender: UIPanGestureRecognizer) {
        guard timeSlider.isTracking else { return }
        switch sender.state {
        case .began:
            imageView.xly_animatedImagePlayer.paused = true
        case .cancelled, .ended, .failed:
            imageView.xly_animatedImagePlayer.paused = false
        default:
            break
        }
    }
    
    @IBAction func togglePause(_ sender: UITapGestureRecognizer) {
        let player = imageView.xly_animatedImagePlayer
        player.paused = !player.paused
    }
    
    @IBAction func changeSpeed(_ sender: UIStepper) {
        imageView.xly_animatedImagePlayer.speed = sender.value
        speedLabel.text = NSString(format: "%.01f", sender.value) as String
    }
    
    @IBAction func changeLinkFrameInterval(_ sender: UIStepper) {
        imageView.xly_animatedImagePlayer.displayLinkFrameInterval = lrint(sender.value)
        linkFrameIntervalLabel.text = "\(Int(sender.value))"
    }
    
    @IBAction func toggleSkipFrame(_ sender: AnyObject) {
        let player = imageView.xly_animatedImagePlayer
        player.skipFramesEnabled = !player.skipFramesEnabled
    }

}

