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
    
    public func xly_setAnimatedImage(image: AnimatedImage, restartIfSame: Bool = false) {
        let lastPlayer = xly_currentAnimatedImagePlayer
        if lastPlayer?.image === image {
            restartIfSame ? lastPlayer?.moveToTime(0) : nil
        } else if lastPlayer?.image !== image {
            var handler = xly_currentAnimatedImagePlayer?.handler
            if handler == nil {
                handler = {[weak self] (image: UIImage, index: Int) -> Void in
                    self?.image = image
                }
            }
            let player = AnimatedImagePlayer(image: image, handler: handler!)
            player.onTimeElapse = lastPlayer?.onTimeElapse
            objc_setAssociatedObject(self, &UIImageView.kAnimatedImagePlayerKey, player, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var xly_currentAnimatedImagePlayer: AnimatedImagePlayer? {
        return objc_getAssociatedObject(self, &UIImageView.kAnimatedImagePlayerKey) as? AnimatedImagePlayer
    }
}
