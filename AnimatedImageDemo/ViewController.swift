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
    
    let gifImage = GIFImage(data: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("guo", ofType: "gif")!)!)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.setAnimatedImage(gifImage)
    }
    

    @IBAction func add(sender: AnyObject) {
        imageView2.setAnimatedImage(gifImage)
    }

}

