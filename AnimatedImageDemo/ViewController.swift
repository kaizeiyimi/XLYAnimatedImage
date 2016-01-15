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
    case GIFImage
    case FrameImages
    
    var description: String {
        switch self {
        case .GIFImage: return "GIF"
        case .FrameImages: return "Frames"
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
    private var images: [AnimatedImage]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let type = type else { return }
        switch type {
        case .GIFImage:
            // default scale is screen's scale.
            let animatedGIFImage0 = AnimatedGIFImage(data: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("shot@2x", ofType: "gif")!)!, scale: 2)
            let animatedGIFImage1 = AnimatedGIFImage(data: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("cat@2x", ofType: "gif")!)!, scale: 2)
            images = [animatedGIFImage0, animatedGIFImage1]
        case .FrameImages:
            segmentedControl.removeSegmentAtIndex(1, animated: false)
//            images = [AnimatedFrameImage(images: (0...9).map({ UIImage(named: "qiaoba\($0)")! }), durations: (0...9).map({_ in 0.1}))]
            // equals to the above line
            let image = UIImage.animatedImageWithImages((0...9).map({ UIImage(named: "qiaoba\($0)")! }), duration: 0.1)!
            images = [AnimatedFrameImage(animatedUIImage: image)]
        }
        segmentedControl.selectedSegmentIndex = UISegmentedControlNoSegment
        
        imageView.xly_setAnimatedImage(images[0]).onTimeElapse = {[unowned self] time in
            self.timeSlider.value = Float(time / self.imageView.xly_animatedImagePlayer!.totalTime)
            self.timeLabel.text = NSString(format: "%.02f/%.02f", time, self.imageView.xly_animatedImagePlayer!.totalTime) as String
        }
        framesLabel.text = "\(images[0].frameCount)"
    }
    
    @IBAction func changeTime(sender: UISlider) {
        if let total = imageView.xly_animatedImagePlayer?.totalTime {
            imageView.xly_animatedImagePlayer?.moveToTime(total * Double(sender.value))
        }
    }
    
    @IBAction func changeImage(sender: UISegmentedControl) {
        let image = sender.selectedSegmentIndex == 0 ? images[0] : images[1]
        imageView.xly_setAnimatedImage(image, replay: replayIfSameSwitch.on)
        framesLabel.text = "\(image.frameCount)"
    }
    
    @IBAction func panOnSpeedSlider(sender: UIPanGestureRecognizer) {
        guard timeSlider.tracking else { return }
        switch sender.state {
        case .Began:
            imageView.xly_animatedImagePlayer?.paused = true
        case .Cancelled, .Ended, .Failed:
            imageView.xly_animatedImagePlayer?.paused = false
        default:
            break
        }
    }
    
    @IBAction func togglePause(sender: UITapGestureRecognizer) {
        let player = imageView.xly_animatedImagePlayer!
        player.paused = !player.paused
    }
    
    @IBAction func changeSpeed(sender: UIStepper) {
        imageView.xly_animatedImagePlayer?.speed = sender.value
        speedLabel.text = NSString(format: "%.01f", sender.value) as String
    }
    
    @IBAction func changeLinkFrameInterval(sender: UIStepper) {
        imageView.xly_animatedImagePlayer?.displayLinkFrameInterval = lrint(sender.value)
        linkFrameIntervalLabel.text = "\(Int(sender.value))"
    }
    
    @IBAction func toggleSkipFrame(sender: AnyObject) {
        let player = imageView.xly_animatedImagePlayer!
        player.skipFrames = !player.skipFrames
    }

}

