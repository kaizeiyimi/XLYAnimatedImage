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
    
    static private let preloadCount = 2 // preload 2 frames is enough now.
    
    public var speed: Double = 1
    public var paused: Bool {
        get { return link.paused }
        set {
            if let image = self.image where image.frameCount >= 2 {
                link.paused = newValue
            }
        }
    }
    
    public var skipFrames = true
    public var displayLinkFrameInterval: Int {
        get { return link.frameInterval }
        set { link.frameInterval = newValue }
    }
    
    public var onTimeElapse: (NSTimeInterval -> Void)?
    
    public private(set) var frameIndex: Int = 0
    public private(set) var time: NSTimeInterval = 0 {
        didSet {
            onTimeElapse?(time)
        }
    }
    
    public private(set) var currentImage: UIImage!
    
    public var image: AnimatedImage? {
        didSet {
            if image !== oldValue {
                OSSpinLockLock(&spinLock)
                operationQueue.cancelAllOperations()
                cache.removeAll()
                OSSpinLockUnlock(&spinLock)
                moveToTime(0)
                if let image = image {
                    display(image: image.firtImage, index: 0)
                    link.paused = image.frameCount < 2
                    currentImage = image.firtImage
                } else {
                    stop()
                }
            } else {
                if let image = currentImage {
                    display(image: image, index: frameIndex)
                }
            }
        }
    }
    var display: (image: UIImage, index: Int) -> Void
    var stop: () -> Void
    
    private var link: CADisplayLink!
    
    private var spinLock = OS_SPINLOCK_INIT
    private var cache: [Int: ImageState] = [:]
    private var miss = true
    
    private let operationQueue = NSOperationQueue()
    
    public init(runloopMode: String = NSRunLoopCommonModes,
        display: (image: UIImage, index: Int) -> Void,
        stop: () -> Void) {
        
        self.display = display
        self.stop = stop
        link = CADisplayLink(target: WeakWrapper(self), selector: #selector(self.linkFired(_:)))
        link.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: runloopMode)
        link.frameInterval = 1
        link.paused = true
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.clearCache(_:)), name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.clearCache(_:)), name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    deinit {
        link.invalidate()
        if image != nil { stop() }
        operationQueue.cancelAllOperations()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: Public
    public func moveToFrameAtIndex(index: Int) {
        guard let image = image where image.frameCount >= 2 else {
            self.frameIndex = 0
            self.time = 0
            return
        }
        
        frameIndex = index % image.frameCount
        self.time = image.durations[0...frameIndex].reduce(0) { $0 + $1 }
        miss = true
        update(self.time, loadImmediately: true)
    }
    
    public func moveToTime(time: NSTimeInterval) {
        guard let image = image where image.frameCount >= 2 else {
            self.frameIndex = 0
            self.time = 0
            return
        }
        
        let time = time - floor(time / image.totalTime) * image.totalTime
        
        var index = 0, temp = 0.0
        for i in 0..<image.frameCount {
            temp += image.durations[i]
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
    
    public func setImage(image: AnimatedImage?, replay: Bool = false) {
        self.image = image
        if replay { moveToTime(0) }
    }
    
    public func replaceHandlers(display display: (image: UIImage, index: Int) -> Void, stop: () -> Void) {
        self.display = display
        self.stop = stop
    }
    
    // MARK: private
    @objc private func clearCache(notify: NSNotification) {
        OSSpinLockLock(&spinLock)
        if let frameCount = image?.frameCount {
            let kept = (1...AnimatedImagePlayer.preloadCount).map {
                (($0 + frameIndex) % frameCount, cache[($0 + frameIndex) % frameCount])
            }
            cache.removeAll(keepCapacity: true)
            kept.forEach { cache[$0.0] = $0.1 }
        } else {
            cache.removeAll()
        }
        OSSpinLockUnlock(&spinLock)
    }
    
    @objc private func linkFired(link: CADisplayLink) {
        guard let image = image where image.frameCount >= 2 else {
            link.paused = true
            self.frameIndex = 0
            self.time = 0
            return
        }
        let nextTime = time - floor(time / image.totalTime) * image.totalTime + link.duration * Double(link.frameInterval) * speed
        update(nextTime)
    }
    
    private func update(nextTime: NSTimeInterval, loadImmediately: Bool = false) {
        guard let image = image else { return }
        
        // load image at index. only fetch from cache
        let showImageAtIndex = {[unowned self] (index: Int) -> Void in
            OSSpinLockLock(&self.spinLock)
            let state = self.cache[index]
            OSSpinLockUnlock(&self.spinLock)
            if let state = state {
                self.miss = false
                if case .Image(let image) = state {
                    self.currentImage = image
                    self.display(image: image, index: index)
                }
            } else {
                self.miss = true
            }
        }
        
        if skipFrames {
            var index = 0, temp = 0.0
            for i in 0..<image.frameCount {
                temp += image.durations[i]
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
            let frameEndTime = image.durations[0...frameIndex].reduce(0){ $0 + $1 }
            let shouldShowNext = (nextTime >= frameEndTime) || (nextTime < frameEndTime - image.durations[frameIndex])
            if !shouldShowNext && miss {
                time = nextTime
                showImageAtIndex(frameIndex)
            } else if !shouldShowNext && !miss {
                time = nextTime
            } else if shouldShowNext && miss {
                showImageAtIndex(frameIndex)
            } else if shouldShowNext && !miss {
                let nextDuration = image.durations[(frameIndex + 1) % image.frameCount]
                time = min(nextTime, frameEndTime + nextDuration)
                frameIndex = (frameIndex + 1) % image.frameCount
                if frameIndex == 0 { time = min(nextTime, image.durations[0]) }
                showImageAtIndex(frameIndex)
            }
        }
        
        // preload
        if cache.count < image.frameCount && (operationQueue.operationCount == 0 || loadImmediately) {
            if loadImmediately {
                operationQueue.cancelAllOperations()
            }
            
            let operation = NSBlockOperation()
            operation.addExecutionBlock
                {[weak self, unowned operation, frameCount = image.frameCount, current = frameIndex,
                    max = (frameIndex + AnimatedImagePlayer.preloadCount) % image.frameCount] in
                    guard let this = self else { return }
                    
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
                        OSSpinLockLock(&this.spinLock)
                        let state = this.cache[index]
                        OSSpinLockUnlock(&this.spinLock)
                        if state == nil {
                            let image = image.imageAtIndex(index)
                            OSSpinLockLock(&this.spinLock)
                            if !operation.cancelled {
                                this.cache[index] = image == nil ? .None : .Image(image: image!)
                            }
                            OSSpinLockUnlock(&this.spinLock)
                            
                        }
                    }
                    
                    if loadImmediately && !operation.cancelled {
                        dispatch_async(dispatch_get_main_queue()) {[weak self] in
                            if let this = self where this.frameIndex == current {
                                showImageAtIndex(current)
                            }
                        }
                    }
                }
            
            operationQueue.addOperation(operation)
        }
    }

}


final private class WeakWrapper: NSObject {
    weak var target: AnyObject?
    init(_ target: AnyObject) {
        self.target = target
    }
    
    override func forwardingTargetForSelector(aSelector: Selector) -> AnyObject? {
        return target
    }
}
