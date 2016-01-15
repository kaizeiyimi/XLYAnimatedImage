//
//  ViewController.swift
//  AnimatedImageDemo
//
//  Created by kaizei on 16/1/12.
//  Copyright © 2016年 kaizei. All rights reserved.
//

import UIKit
import XLYAnimatedImage

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var replayIfSameSwitch: UISwitch!
    
    @IBOutlet weak var framesLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var linkFrameIntervalLabel: UILabel!
    
    
    let animatedGIFImage0 = AnimatedGIFImage(data: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("shot@2x", ofType: "gif")!)!, scale: 2)
    let animatedGIFImage1 = AnimatedGIFImage(data: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("cat@2x", ofType: "gif")!)!, scale: 2)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        segmentedControl.selectedSegmentIndex = UISegmentedControlNoSegment
        
        imageView.xly_setAnimatedImage(animatedGIFImage0).onTimeElapse = {[unowned self] time in
            self.timeSlider.value = Float(time / self.imageView.xly_animatedImagePlayer!.totalTime)
            self.timeLabel.text = NSString(format: "%.02f/%.02f", time, self.imageView.xly_animatedImagePlayer!.totalTime) as String
        }
        framesLabel.text = "\(animatedGIFImage0.frameCount)"
    }
    
    @IBAction func changeTime(sender: UISlider) {
        if let total = imageView.xly_animatedImagePlayer?.totalTime {
            imageView.xly_animatedImagePlayer?.moveToTime(total * Double(sender.value))
        }
    }
    
    @IBAction func changeImage(sender: UISegmentedControl) {
        let image = sender.selectedSegmentIndex == 0 ? animatedGIFImage0 : animatedGIFImage1
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

