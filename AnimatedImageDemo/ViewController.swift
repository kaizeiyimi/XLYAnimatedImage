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
    @IBOutlet weak var speedStepper: UIStepper!
    @IBOutlet weak var linkIntervalStepper: UIStepper!
    @IBOutlet weak var skipSwitch: UISwitch!
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
            self.timeSlider.value = Float(time / self.imageView.xly_currentAnimatedImagePlayer!.totalTime)
            self.timeLabel.text = NSString(format: "%.02f/%.02f", time, self.imageView.xly_currentAnimatedImagePlayer!.totalTime) as String
        }
        framesLabel.text = "\(animatedGIFImage0.frameCount)"
    }
    
    @IBAction func changeTime(sender: UISlider) {
        if let total = imageView.xly_currentAnimatedImagePlayer?.totalTime {
            imageView.xly_currentAnimatedImagePlayer?.moveToTime(total * Double(sender.value))
        }
    }
    
    @IBAction func changeImage(sender: UISegmentedControl) {
        let image = sender.selectedSegmentIndex == 0 ? animatedGIFImage0 : animatedGIFImage1
        imageView.xly_setAnimatedImage(image, replay: replayIfSameSwitch.on)
        framesLabel.text = "\(image.frameCount)"
        
        imageView.xly_currentAnimatedImagePlayer?.speed = speedStepper.value
        imageView.xly_currentAnimatedImagePlayer?.displayLinkFrameInterval = lrint(linkIntervalStepper.value)
        imageView.xly_currentAnimatedImagePlayer?.skipFrames = skipSwitch.on
    }
    
    
    @IBAction func panOnSpeedSlider(sender: UIPanGestureRecognizer) {
        guard timeSlider.tracking else { return }
        switch sender.state {
        case .Began:
            imageView.xly_currentAnimatedImagePlayer?.paused = true
        case .Cancelled, .Ended, .Failed:
            imageView.xly_currentAnimatedImagePlayer?.paused = false
        default:
            break
        }
    }
    
    @IBAction func togglePause(sender: UITapGestureRecognizer) {
        let player = imageView.xly_currentAnimatedImagePlayer!
        player.paused = !player.paused
    }
    
    @IBAction func changeSpeed(sender: UIStepper) {
        imageView.xly_currentAnimatedImagePlayer?.speed = sender.value
        speedLabel.text = NSString(format: "%.01f", sender.value) as String
    }
    
    @IBAction func changeLinkFrameInterval(sender: UIStepper) {
        imageView.xly_currentAnimatedImagePlayer?.displayLinkFrameInterval = lrint(sender.value)
        linkFrameIntervalLabel.text = "\(Int(sender.value))"
    }
    
    @IBAction func toggleSkipFrame(sender: AnyObject) {
        let player = imageView.xly_currentAnimatedImagePlayer!
        player.skipFrames = !player.skipFrames
    }

}

