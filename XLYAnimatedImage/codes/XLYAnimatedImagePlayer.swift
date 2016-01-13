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

private enum ImageState {
    case Image(image: UIImage)
    case None
}

public class AnimatedImagePlayer {
    
    public let scale: CGFloat
    public var paused: Bool = false {
        didSet {
            link?.paused = paused
        }
    }
    
    public var frameCount: Int { return image.frameCount }
    public var totalTime: NSTimeInterval { return image.totalTime }
    public var durations: [NSTimeInterval] { return image.durations }
    
    public private(set) var frameIndex: Int = 0
    public private(set) var time: NSTimeInterval = 0
    
    private var handler: (image: UIImage, index: Int, duration: NSTimeInterval) -> Void
    private let image: AnimatedImage
    private var link: CADisplayLink!
    
    private var spinLock = OS_SPINLOCK_INIT
    private var buffer: [Int: ImageState] = [:]
    private var miss = true
    
    private let operationQueue = NSOperationQueue()
    
    public init(scale: CGFloat = UIScreen.mainScreen().scale,
        runloopMode: String = NSRunLoopCommonModes,
        image: AnimatedImage,
        handler: (image: UIImage, index: Int, duration: NSTimeInterval) -> Void) {
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
        update(nextTime, lastDuration: link.duration)
    }
    
    private func update(nextTime: NSTimeInterval, lastDuration: NSTimeInterval = 0) {
        var index = 0
        for var temp: NSTimeInterval = 0, i = 0; i < frameCount; ++i {
            temp += durations[i]
            if nextTime < temp {
                index = i
                break
            }
        }
        
        if (index != frameIndex && !miss) || (index == frameIndex && miss) {
            OSSpinLockLock(&spinLock)
            let state = buffer[index]
            OSSpinLockUnlock(&spinLock)
            time = nextTime
            frameIndex = index
            if let state = state {
                miss = false
                if case .Image(let image) = state {
                    handler(image: image, index: index, duration: durations[index])
                }
            } else {
                miss = true
            }
        } else if index == frameIndex && !miss {
            time = nextTime
        }
        
        if buffer.count < frameCount && operationQueue.operationCount == 0 {
            operationQueue.addOperationWithBlock {[weak self, max = (frameIndex + 1) % frameCount] () -> Void in
                if let this = self {
                    for index in 0...max {
                        OSSpinLockLock(&this.spinLock)
                        let state = this.buffer[index]
                        OSSpinLockUnlock(&this.spinLock)
                        if state == nil {
                            let image = this.image.imageAtIndex(index)
                            OSSpinLockLock(&this.spinLock)
                            this.buffer[index] = image == nil ? .None : .Image(image: image!)
                            OSSpinLockUnlock(&this.spinLock)
                        }
                    }
                }
            }
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
