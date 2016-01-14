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
    
    
    let animatedGIFImage0 = AnimatedGIFImage(data: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("niconiconi@2x", ofType: "gif")!)!)
    let animatedGIFImage1 = AnimatedGIFImage(data: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("guo", ofType: "gif")!)!)
    var restartIfSame = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.xly_setAnimatedImage(animatedGIFImage0)
        imageView.xly_animatedImagePlayer?.onTimeElapse = {[unowned self] time in
            self.timeSlider.value = Float(time / self.imageView.xly_animatedImagePlayer!.totalTime)
        }
    }
    
    @IBAction func changeTime(sender: UISlider) {
        if let total = imageView.xly_animatedImagePlayer?.totalTime {
            imageView.xly_animatedImagePlayer?.moveToTime(total * Double(sender.value))
        }
    }
    
    @IBAction func changeImage(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            imageView.xly_setAnimatedImage(animatedGIFImage0, restartIfSame: restartIfSame)
        } else if sender.selectedSegmentIndex == 1 {
            imageView.xly_setAnimatedImage(animatedGIFImage1, restartIfSame: restartIfSame)
        }
        
        imageView.xly_animatedImagePlayer?.speed = speedStepper.value
        imageView.xly_animatedImagePlayer?.onTimeElapse = {[unowned self] time in
            self.timeSlider.value = Float(time / self.imageView.xly_animatedImagePlayer!.totalTime)
        }
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
    
    @IBAction func changeSpeed(sender: UIStepper) {
        imageView.xly_animatedImagePlayer?.speed = sender.value
        speedLabel.text = NSString(format: "%.01f", sender.value) as String
    }
    
    @IBAction func togglePause(sender: UITapGestureRecognizer) {
        if let player = imageView.xly_animatedImagePlayer {
            player.paused = !player.paused
        }
    }

    @IBAction func toggleRestartIfSame(sender: AnyObject) {
        restartIfSame = !restartIfSame
    }
}

