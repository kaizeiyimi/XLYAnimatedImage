//
//  XLYAnimatedImagePlayer.swift
//  XLYAnimatedImage
//
//  Created by kaizei on 16/1/13.
//  Copyright © 2016年 kaizei. All rights reserved.
//

import UIKit


private enum ImageState {
    case Image(image: UIImage)
    case None
}

public class AnimatedImagePlayer {
    
    static private let preloadCount = 2
    
    public let scale: CGFloat
    public var speed: Double = 1
    public var paused: Bool = false {
        didSet {
            link?.paused = paused
        }
    }
    
    public var skipFrames = true
    public var displayLinkFrameInterval: Int {
        get { return link.frameInterval }
        set { link.frameInterval = newValue }
    }
    public var frameCount: Int { return image.frameCount }
    public var totalTime: NSTimeInterval { return image.totalTime }
    public var durations: [NSTimeInterval] { return image.durations }
    
    public var onTimeElapse: (NSTimeInterval -> Void)?
    
    public private(set) var frameIndex: Int = 0
    public private(set) var time: NSTimeInterval = 0 {
        didSet {
            onTimeElapse?(time)
        }
    }
    
    let image: AnimatedImage
    let handler: (image: UIImage, index: Int) -> Void
    
    private var link: CADisplayLink!
    
    private var spinLock = OS_SPINLOCK_INIT
    private var cache: [Int: ImageState] = [:]
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
            link.frameInterval = 1
            link.paused = paused
            handler(image: image.firtImage, index: 0)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "clearCache:", name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "clearCache:", name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    deinit {
        link.invalidate()
        operationQueue.cancelAllOperations()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @objc private func clearCache(notify: NSNotification) {
        OSSpinLockLock(&spinLock)
        let kept = (1...AnimatedImagePlayer.preloadCount).map {
            (($0 + frameIndex) % frameCount, cache[($0 + frameIndex) % frameCount])
        }
        cache.removeAll(keepCapacity: true)
        kept.forEach { cache[$0.0] = $0.1 }
        OSSpinLockUnlock(&spinLock)
    }
    
    @objc private func linkFired(link: CADisplayLink) {
        let nextTime = time - floor(time / totalTime) * totalTime + link.duration * Double(link.frameInterval) * speed
        update(nextTime)
    }
    
    private func update(nextTime: NSTimeInterval, loadImmediately: Bool = false) {
        // load image at index. only fetch from cache
        func showImageAtIndex(index: Int) {
            OSSpinLockLock(&spinLock)
            let state = cache[index]
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
        
        // decode image at index. decode and save to cache
        func decodeImageAtIndex(index: Int) {
            OSSpinLockLock(&spinLock)
            let state = cache[index]
            OSSpinLockUnlock(&spinLock)
            if state == nil {
                let image = self.image.imageAtIndex(index)
                OSSpinLockLock(&spinLock)
                cache[index] = image == nil ? .None : .Image(image: image!)
                OSSpinLockUnlock(&spinLock)
            }
        }
        
        if skipFrames {
            var index = 0
            for var temp: NSTimeInterval = 0, i = 0; i < frameCount; ++i {
                temp += durations[i]
                if nextTime < temp {
                    index = i
                    break
                }
            }
            if (index != frameIndex && !miss) || (index == frameIndex && miss) {
                time = nextTime
                frameIndex = index
                showImageAtIndex(index)
            } else if index == frameIndex && !miss {
                time = nextTime
            } else if index != frameIndex && miss {
                showImageAtIndex(frameIndex)
            }
        } else {
            let frameEndTime = durations[0...frameIndex].reduce(0){ $0 + $1 }
            let shouldShowNext = (nextTime >= frameEndTime) || (nextTime < frameEndTime - durations[frameIndex])
            if !shouldShowNext && miss {
                time = nextTime
                showImageAtIndex(frameIndex)
            } else if !shouldShowNext && !miss {
                time = nextTime
            } else if shouldShowNext && miss {
                print("bingo!")
                showImageAtIndex(frameIndex)
            } else if shouldShowNext && !miss {
                let nextDuration = durations[(frameIndex + 1) % frameCount]
                time = min(nextTime, frameEndTime + nextDuration)
                frameIndex = (frameIndex + 1) % frameCount
                showImageAtIndex(frameIndex)
            }
        }
        
        // preload
        if cache.count < frameCount && (operationQueue.operationCount == 0 || loadImmediately) {
            if loadImmediately {
                operationQueue.cancelAllOperations()
            }
            
            let operation = NSBlockOperation()
            operation.addExecutionBlock
                {[weak self, unowned operation, frameCount = frameCount, current = frameIndex,
                    max = (frameIndex + AnimatedImagePlayer.preloadCount) % frameCount] in
                    if let _ = self {
                        if operation.cancelled { return }
                        let indies = NSMutableIndexSet()
                        if current < max {
                            indies.addIndexesInRange(NSMakeRange(current, max - current + 1))
                        } else {
                            indies.addIndexesInRange(NSMakeRange(current, frameCount - current))
                            indies.addIndexesInRange(NSMakeRange(0, max + 1))
                        }
                        if operation.cancelled { return }
                        for index in indies {
                            if operation.cancelled { return }
                            decodeImageAtIndex(index)
                        }
                        if loadImmediately && !operation.cancelled {
                            dispatch_async(dispatch_get_main_queue()) {[weak self] in
                                if self?.frameIndex == current {
                                    showImageAtIndex(current)
                                }
                            }
                        }
                    }
                }
            
            operationQueue.addOperation(operation)
        }
    }
    
    public func moveToFrameAtIndex(index: Int) {
        frameIndex = index % frameCount
        self.time = durations[0...frameIndex].reduce(0) { $0 + $1 }
        miss = true
        update(self.time, loadImmediately: true)
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
        update(self.time, loadImmediately: true)
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
