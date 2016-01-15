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
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var speedStepper: UIStepper!
    @IBOutlet weak var skipSwitch: UISwitch!
    
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var linkFrameIntervalLabel: UILabel!
    
    
    let animatedGIFImage0 = AnimatedGIFImage(data: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("niconiconi@2x", ofType: "gif")!)!)
    let animatedGIFImage1 = AnimatedGIFImage(data: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("guo", ofType: "gif")!)!, scale: 1)
    var replay = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.xly_setAnimatedImage(animatedGIFImage0).onTimeElapse = {[unowned self] time in
            self.timeSlider.value = Float(time / self.imageView.xly_currentAnimatedImagePlayer!.totalTime)
        }
    }
    
    @IBAction func changeTime(sender: UISlider) {
        if let total = imageView.xly_currentAnimatedImagePlayer?.totalTime {
            imageView.xly_currentAnimatedImagePlayer?.moveToTime(total * Double(sender.value))
        }
    }
    
    @IBAction func changeImage(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            imageView.xly_setAnimatedImage(animatedGIFImage0, replay: replay)
        } else if sender.selectedSegmentIndex == 1 {
            imageView.xly_setAnimatedImage(animatedGIFImage1, replay: replay)
        }
        
        imageView.xly_currentAnimatedImagePlayer?.speed = speedStepper.value
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
    
    @IBAction func changeSpeed(sender: UIStepper) {
        imageView.xly_currentAnimatedImagePlayer?.speed = sender.value
        speedLabel.text = NSString(format: "%.01f", sender.value) as String
    }
    
    @IBAction func togglePause(sender: UITapGestureRecognizer) {
        if let player = imageView.xly_currentAnimatedImagePlayer {
            player.paused = !player.paused
        }
    }
    @IBAction func toggleSkipFrame(sender: AnyObject) {
        if let player = imageView.xly_currentAnimatedImagePlayer {
            player.skipFrames = !player.skipFrames
        }
    }

    @IBAction func toggleReplayIfSame(sender: AnyObject) {
        replay = !replay
    }
    
    @IBAction func changeLinkFrameInterval(sender: UIStepper) {
        imageView.xly_currentAnimatedImagePlayer?.displayLinkFrameInterval = Int(sender.value)
        linkFrameIntervalLabel.text = "\(Int(sender.value))"
    }
    
}

