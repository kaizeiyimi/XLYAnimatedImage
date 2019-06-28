//
//  XLYAnimatedImagePlayer.swift
//  XLYAnimatedImage
//
//  Created by kaizei on 16/1/13.
//  Copyright © 2016年 kaizei. All rights reserved.
//

import UIKit


open class AnimatedImagePlayer {
    
    open var preloadCount = 2 // preload 2 frames is enough now.
    
    open var speed: Double = 1
    open var paused: Bool {
        get { return link.isPaused }
        set {
            if let image = self.image , image.frameCount >= 2 {
                link.isPaused = newValue
            }
        }
    }
    
    open var skipFramesEnabled = true
    open var displayLinkFrameInterval: Int {
        get { return link.frameInterval }
        set { link.frameInterval = newValue }
    }
    
    open var onTimeElapse: ((TimeInterval) -> Void)?
    
    open private(set) var frameIndex: Int = 0
    open private(set) var time: TimeInterval = 0 {
        didSet {
            onTimeElapse?(time)
        }
    }
    
    open private(set) var currentImage: UIImage!
    
    open var image: AnimatedImage? {
        didSet {
            if image !== oldValue {
                OSSpinLockLock(&spinLock)
                operationQueue.cancelAllOperations()
                cache.removeAll()
                OSSpinLockUnlock(&spinLock)
                move(toTime: 0)
                if let image = image {
                    display(image.firtImage, 0)
                    link.isPaused = image.frameCount < 2
                    currentImage = image.firtImage
                } else {
                    stop()
                }
            } else {
                if let image = currentImage {
                    display(image, frameIndex)
                }
            }
        }
    }
    var display: (_ image: UIImage, _ index: Int) -> Void
    var stop: () -> Void
    
    private let link: CADisplayLink
    
    private var spinLock = OS_SPINLOCK_INIT
    private var cache: [Int: UIImage?] = [:]
    private var miss = true
    
    private let operationQueue = OperationQueue()
    
    public init(runloopMode: RunLoop.Mode = .common,
        display: @escaping (_ image: UIImage, _ index: Int) -> Void,
        stop: @escaping () -> Void) {
        
        self.display = display
        self.stop = stop
        let wrapper = WeakWrapper()
        link = CADisplayLink(target: wrapper, selector: #selector(self.linkFired(_:)))
        wrapper.target = self
        link.add(to: RunLoop.main, forMode: runloopMode)
        link.frameInterval = 1
        link.isPaused = true
        NotificationCenter.default.addObserver(self, selector: #selector(self.clearCache(_:)), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.clearCache(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    deinit {
        link.invalidate()
        if image != nil { stop() }
        operationQueue.cancelAllOperations()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Public
    open func move(toFrame index: Int) {
        guard let image = image , image.frameCount >= 2 else {
            self.frameIndex = 0
            self.time = 0
            return
        }
        
        frameIndex = index % image.frameCount
        self.time = image.durations[0...frameIndex].reduce(0) { $0 + $1 }
        miss = true
        update(forNextTime: self.time, loadImmediately: true)
    }
    
    open func move(toTime time: TimeInterval) {
        guard let image = image , image.frameCount >= 2 else {
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
        update(forNextTime: self.time, loadImmediately: true)
    }
    
    open func setImage(_ image: AnimatedImage?, replay: Bool = false) {
        self.image = image
        if replay { move(toTime: 0) }
    }
    
    open func replaceHandlers(display: @escaping (_ image: UIImage, _ index: Int) -> Void, stop: @escaping () -> Void) {
        self.display = display
        self.stop = stop
    }
    
    // MARK: private
    @objc private func clearCache(_ notify: Notification) {
        OSSpinLockLock(&spinLock)
        if let frameCount = image?.frameCount {
            let kept = (1...preloadCount).map {
                (($0 + frameIndex) % frameCount, cache[($0 + frameIndex) % frameCount])
            }
            cache.removeAll(keepingCapacity: true)
            kept.forEach { cache[$0.0] = $0.1 }
        } else {
            cache.removeAll()
        }
        OSSpinLockUnlock(&spinLock)
    }
    
    @objc private func linkFired(_ link: CADisplayLink) {
        guard let image = image , image.frameCount >= 2 else {
            link.isPaused = true
            self.frameIndex = 0
            self.time = 0
            return
        }
        let nextTime = time - floor(time / image.totalTime) * image.totalTime + link.duration * Double(link.frameInterval) * speed
        update(forNextTime: nextTime)
    }
    
    private func update(forNextTime nextTime: TimeInterval, loadImmediately: Bool = false) {
        guard let image = image else { return }
        
        // load image at index. only fetch from cache
        let showImageAtIndex = {[unowned self] (index: Int) -> Void in
            OSSpinLockLock(&self.spinLock)
            let state = self.cache[index]
            OSSpinLockUnlock(&self.spinLock)
            if let state = state {
                self.miss = false
                if let image = state {
                    self.currentImage = image
                    self.display(image, index)
                }
            } else {
                self.miss = true
            }
        }
        
        if skipFramesEnabled {
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
        OSSpinLockLock(&self.spinLock)
        let cacheCount = cache.count
        OSSpinLockUnlock(&self.spinLock)
        if cacheCount < image.frameCount && (operationQueue.operationCount == 0 || loadImmediately) {
            if loadImmediately {
                operationQueue.cancelAllOperations()
            }
            
            let operation = BlockOperation()
            operation.addExecutionBlock
                {[weak self, unowned operation, frameCount = image.frameCount, current = frameIndex,
                    max = (frameIndex + preloadCount) % image.frameCount] in
                    guard let this = self else { return }
                    
                    if operation.isCancelled { return }
                    let indies = NSMutableIndexSet()
                    if current < max {
                        indies.add(in: NSMakeRange(current, max - current + 1))
                    } else {
                        indies.add(in: NSMakeRange(current, frameCount - current))
                        indies.add(in: NSMakeRange(0, max + 1))
                    }
                    
                    if operation.isCancelled { return }
                    for index in indies {
                        if operation.isCancelled { return }
                        OSSpinLockLock(&this.spinLock)
                        let state = this.cache[index]
                        OSSpinLockUnlock(&this.spinLock)
                        if state == nil {
                            let image = image.image(at: index)
                            OSSpinLockLock(&this.spinLock)
                            if !operation.isCancelled {
                                this.cache[index] = Optional<UIImage?>.some(image)
                            }
                            OSSpinLockUnlock(&this.spinLock)
                            
                        }
                    }
                    
                    if loadImmediately && !operation.isCancelled {
                        DispatchQueue.main.async {[weak self] in
                            if let this = self , this.frameIndex == current {
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
    
    override init() {}
    
    override func forwardingTarget(for aSelector: Selector) -> Any? {
        return target
    }
}
