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
        let lastPlayer = xly_currentAnimatedImagePlayer
        if lastPlayer?.image === image {
            replay ? lastPlayer?.moveToTime(0) : nil
        } else if lastPlayer?.image !== image {
            var handler = xly_currentAnimatedImagePlayer?.handler   // for now, ?? cannot operate on closure
            if handler == nil {
                handler = {[weak self] (image: UIImage, index: Int) -> Void in
                    self?.image = image
                }
            }
            let player = AnimatedImagePlayer(image: image, handler: handler!)
            player.onTimeElapse = lastPlayer?.onTimeElapse
            xly_currentAnimatedImagePlayer = player
        }
        
        return xly_currentAnimatedImagePlayer!
    }
    
    public var xly_currentAnimatedImagePlayer: AnimatedImagePlayer? {
        get { return objc_getAssociatedObject(self, &UIImageView.kAnimatedImagePlayerKey) as? AnimatedImagePlayer }
        set { objc_setAssociatedObject(self, &UIImageView.kAnimatedImagePlayerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
