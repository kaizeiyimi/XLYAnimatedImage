//
//  XLYAnimatedImageUIKitExtensions.swift
//  XLYAnimatedImage
//
//  Created by kaizei on 16/1/14.
//  Copyright © 2016年 kaizei. All rights reserved.
//

import UIKit


extension UIImageView {
    static private var kAnimatedImagePlayerKey = "kaizei.yimi.kAnimatedImagePlayerKey"
    
    public func xly_setAnimatedImage(image: AnimatedImage, replay: Bool = false) -> AnimatedImagePlayer {
        if let player = xly_animatedImagePlayer {
            player.setImage(image, replay: replay)
        } else {
            let player = AnimatedImagePlayer(image: image) {[weak self] (image, index) -> Void in
                self?.image = image
            }
            xly_animatedImagePlayer = player
        }
        return xly_animatedImagePlayer!
    }
    
    public var xly_animatedImagePlayer: AnimatedImagePlayer? {
        get { return objc_getAssociatedObject(self, &UIImageView.kAnimatedImagePlayerKey) as? AnimatedImagePlayer }
        set { objc_setAssociatedObject(self, &UIImageView.kAnimatedImagePlayerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
