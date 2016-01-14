//
//  XLYAnimatedImagePlayer.swift
//  XLYAnimatedImage
//
//  Created by kaizei on 16/1/13.
//  Copyright © 2016年 kaizei. All rights reserved.
//

import UIKit

extension UIImageView {
    static private var kAnimatedImagePlayerKey = "kaizei.yimi.kAnimatedImagePlayerKey"
    
    public func xly_setAnimatedImage(image: AnimatedImage, restartIfSame: Bool = false) {
        if xly_animatedImagePlayer?.image !== image || restartIfSame {
            let player = AnimatedImagePlayer(image: image) {[weak self] (image, index) -> Void in
                self?.image = image
            }
            objc_setAssociatedObject(self, &UIImageView.kAnimatedImagePlayerKey, player, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var xly_animatedImagePlayer: AnimatedImagePlayer? {
        return objc_getAssociatedObject(self, &UIImageView.kAnimatedImagePlayerKey) as? AnimatedImagePlayer
    }
}

private enum ImageState {
    case Image(image: UIImage)
    case None
}

public class AnimatedImagePlayer {
    
    public let scale: CGFloat
    public var speed: Double = 1
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
    
    private var handler: (image: UIImage, index: Int) -> Void
    private let image: AnimatedImage
    private var link: CADisplayLink!
    
    private var spinLock = OS_SPINLOCK_INIT
    private var buffer: [Int: ImageState] = [:]
    private var miss = true
    
    private let operationQueue = NSOperationQueue()
    
    public init(scale: CGFloat = UIScreen.mainScreen().scale,
        runloopMode: String = NSRunLoopCommonModes,
        image: AnimatedImage,
        handler: (image: UIImage, index: Int) -> Void) {
            self.handler = handler
            self.scale = scale
            self.image = image
            link = CADisplayLink(target: WeakWrapper(self), selector: "linkFired:")
            link.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: runloopMode)
            link.paused = paused
            handler(image: image.firtImage, index: 0)
    }
    
    deinit {
        link.invalidate()
    }
    
    @objc private func linkFired(link: CADisplayLink) {
        let nextTime = time - floor(time / totalTime) * totalTime + link.duration * speed
        // next index
        var index = 0
        for var temp: NSTimeInterval = 0, i = 0; i < frameCount; ++i {
            temp += durations[i]
            if nextTime < temp {
                index = i
                break
            }
        }
        
        func loadImageAtIndex(index: Int) {
            OSSpinLockLock(&spinLock)
            let state = buffer[index]
            OSSpinLockUnlock(&spinLock)
            if let state = state {
                miss = false
                if case .Image(let image) = state {
                    handler(image: image, index: index)
                }
            } else {
                miss = true
            }
        }
        
        // update   jump frame
        if (index != frameIndex && !miss) || (index == frameIndex && miss) {
            time = nextTime
            frameIndex = index
            loadImageAtIndex(index)
        } else if index == frameIndex && !miss {
            time = nextTime
        } else if index != frameIndex && miss {
            loadImageAtIndex(frameIndex)
        }
        
        // preload
        if buffer.count < frameCount && operationQueue.operationCount == 0 {
            operationQueue.addOperationWithBlock
                {[weak self, frameCount = frameCount, current = frameIndex, max = (frameIndex + 2) % frameCount] in
                    if let this = self {
                        let indies = NSMutableIndexSet()
                        if current < max {
                            indies.addIndexesInRange(NSMakeRange(current, max - current + 1))
                        } else {
                            indies.addIndexesInRange(NSMakeRange(current, frameCount - current))
                            indies.addIndexesInRange(NSMakeRange(0, max + 1))
                        }
                        for index in indies {
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
        frameIndex = index % frameCount
        self.time = durations[0...frameIndex].reduce(0) { $0 + $1 }
        miss = true
    }
    
    public func moveToTime(var time: NSTimeInterval) {
        time = time - floor(time / totalTime) * totalTime
        var index = 0
        for var temp: NSTimeInterval = 0, i = 0; i < frameCount; ++i {
            temp += durations[i]
            if time < temp {
                index = i
                break
            }
        }
        self.frameIndex = index
        self.time = time
        miss = true
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
