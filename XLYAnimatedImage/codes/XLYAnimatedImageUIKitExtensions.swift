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
    
    public func xly_setAnimatedImage(image: AnimatedImage?, replay: Bool = false) {
        xly_animatedImagePlayer.setImage(image, replay: replay)
    }
    
    public var xly_animatedImagePlayer: AnimatedImagePlayer! {
        get {
            if let player = objc_getAssociatedObject(self, &UIImageView.kAnimatedImagePlayerKey) as? AnimatedImagePlayer {
                return player
            }
            let player = AnimatedImagePlayer {[weak self] (image, index) -> Void in
                self?.image = image
            }
            self.xly_animatedImagePlayer = player
            return player
        }
        set { objc_setAssociatedObject(self, &UIImageView.kAnimatedImagePlayerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
