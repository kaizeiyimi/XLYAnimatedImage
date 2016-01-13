//
//  XLYAnimatedImagePlayer.swift
//  XLYAnimatedImage
//
//  Created by kaizei on 16/1/13.
//  Copyright © 2016年 kaizei. All rights reserved.
//

import UIKit

extension UIImageView {
    static private var kAnimatedImagePlayerKey = "kAnimatedImagePlayerKey"
    
    public func setAnimatedImage(image: AnimatedImage) {
        let player = AnimatedImagePlayer(image: image) {[weak self] (image, index, duration) -> Void in
            self?.image = image
        }
        objc_setAssociatedObject(self, &UIImageView.kAnimatedImagePlayerKey, player, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}


public class AnimatedImagePlayer {
    
    public let scale: CGFloat
    public var paused: Bool = false
    
    public var frameCount: Int { return image.frameCount }
    public var totalTime: NSTimeInterval { return image.totalTime }
    public var durations: [NSTimeInterval] { return image.durations }
    
    public private(set) var frameIndex: Int = 0
    public private(set) var time: NSTimeInterval = 0
    
    private var handler: (image: UIImage?, index: Int, duration: NSTimeInterval) -> Void
    private let image: AnimatedImage
    private var link: CADisplayLink!
    
    public init(scale: CGFloat = UIScreen.mainScreen().scale,
        runloopMode: String = NSRunLoopCommonModes,
        image: AnimatedImage,
        handler: (image: UIImage?, index: Int, duration: NSTimeInterval) -> Void) {
            self.handler = handler
            self.scale = scale
            self.image = image
            link = CADisplayLink(target: WeakWrapper(self), selector: "linkFired:")
            link.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: runloopMode)
            link.paused = paused
    }
    
    deinit {
        link.invalidate()
    }
    
    @objc private func linkFired(link: CADisplayLink) {
        let nextTime = time - floor(time / totalTime) * totalTime + link.duration
        update(nextTime)
    }
    
    private func update(nextTime: NSTimeInterval) {
        time = nextTime
        var index = 0
        for var temp: NSTimeInterval = 0, i = 0; i < frameCount; ++i {
            temp += durations[i]
            if nextTime < temp {
                index = i
                break
            }
        }
        // TODO: async load image if needed. maybe cancel loading
        if index != frameIndex {
            frameIndex = index
            handler(image: image.imageAtIndex(index), index: index, duration: durations[index])
        }
    }
    
    public func moveToFrameAtIndex(index: Int) {
        let time = durations[0...index].reduce(0) { $0 + $1 }
        update(time)
    }
    
    public func moveToTime(time: NSTimeInterval) {
        update(time)
    }

}


private class WeakWrapper: NSObject {
    weak var target: AnyObject?
    init(_ target: AnyObject) {
        self.target = target
    }
    
    override func forwardingTargetForSelector(aSelector: Selector) -> AnyObject? {
        return target
    }
}
