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
    @IBOutlet weak var imageView2: UIImageView!
    
    let animatedGIFImage = AnimatedGIFImage(data: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("niconiconi@2x", ofType: "gif")!)!)
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        imageView.setAnimatedImage(AnimatedGIFImage)
    }
    

    @IBAction func add(sender: AnyObject) {
//        imageView.player?.moveToTime(30)
//        imageView.player!.paused = !imageView.player!.paused
//        let animatedGIFImage = AnimatedGIFImage(data: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("niconiconi@2x", ofType: "gif")!)!)
        imageView.xly_setAnimatedImage(animatedGIFImage, restartIfSame: true)
    }

}

