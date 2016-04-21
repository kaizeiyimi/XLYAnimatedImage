//
//  XLYAnimatedImageUIKitExtensions.swift
//  XLYAnimatedImage
//
//  Created by kaizei on 16/1/14.
//  Copyright © 2016年 kaizei. All rights reserved.
//

import UIKit


extension UIImageView {
    private struct AssociatedKeys {
        static var kAnimatedImagePlayerKey = "kaizei.yimi.kAnimatedImagePlayerKey"
    }
    
    public func xly_setAnimatedImage(image: AnimatedImage?, replay: Bool = false) {
        xly_animatedImagePlayer.setImage(image, replay: replay)
    }
    
    public var xly_animatedImagePlayer: AnimatedImagePlayer! {
        get {
            if let player = objc_getAssociatedObject(self, &AssociatedKeys.kAnimatedImagePlayerKey) as? AnimatedImagePlayer {
                return player
            }
            let player = AnimatedImagePlayer(
                display: {[weak self] image, index in
                    self?.image = image
                },
                stop: {[weak self] in
                    self?.image = nil
            })
            self.xly_animatedImagePlayer = player
            return player
        }
        set { objc_setAssociatedObject(self, &AssociatedKeys.kAnimatedImagePlayerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
