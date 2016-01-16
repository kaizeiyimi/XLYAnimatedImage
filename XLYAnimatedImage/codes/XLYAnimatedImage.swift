//
//  XLYAnimatedImage.swift
//  XLYAnimatedImage
//
//  Created by kaizei on 16/1/12.
//  Copyright © 2016年 kaizei. All rights reserved.
//

import UIKit
import ImageIO
import MobileCoreServices

private let kMinDurationPerFrame = 0.01, kDefaultDurationPerFrame = 0.1

/// stolen from SDWebImage's decoder. just change OC to swift.
private func decodeCGImage(image: CGImage?) -> CGImage? {
    guard let image = image else { return nil }
    var result: CGImage?
    autoreleasepool {
        let width = CGImageGetWidth(image), height = CGImageGetHeight(image)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo = CGImageGetBitmapInfo(image).rawValue
        let infoMask = bitmapInfo & CGBitmapInfo.AlphaInfoMask.rawValue
        let anyNonAlpha = (infoMask == CGImageAlphaInfo.None.rawValue ||
            infoMask == CGImageAlphaInfo.NoneSkipFirst.rawValue ||
            infoMask == CGImageAlphaInfo.NoneSkipLast.rawValue)
        
        if infoMask == CGImageAlphaInfo.None.rawValue && CGColorSpaceGetNumberOfComponents(colorSpace) > 1 {
            bitmapInfo &= ~CGBitmapInfo.AlphaInfoMask.rawValue
            bitmapInfo |= CGImageAlphaInfo.NoneSkipFirst.rawValue
        } else if !anyNonAlpha && CGColorSpaceGetNumberOfComponents(colorSpace) == 3 {
            bitmapInfo &= ~CGBitmapInfo.AlphaInfoMask.rawValue
            bitmapInfo |= CGImageAlphaInfo.PremultipliedFirst.rawValue
        }
        
        let context = CGBitmapContextCreate(nil, CGImageGetWidth(image), CGImageGetHeight(image), CGImageGetBitsPerComponent(image), 0, colorSpace, bitmapInfo)
        
        CGContextDrawImage(context, CGRect(x: 0, y: 0, width: width, height: height), image)
        result = CGBitmapContextCreateImage(context)
    }
    return result
}


// MARK: - image
public protocol AnimatedImage: class {
    var scale: CGFloat { get }
    var frameCount: Int { get }
    var totalTime: NSTimeInterval { get }
    var durations: [NSTimeInterval] { get }
    var firtImage: UIImage { get }
    func imageAtIndex(index: Int) -> UIImage?
}

extension AnimatedImage {
    public var frameCount: Int { return durations.count }
}


// MARK: - GIF
public class AnimatedGIFImage: AnimatedImage {
    struct InvalidDataError: ErrorType {
        let description = "Data is not a valid GIF data."
    }
    
    static func getGIFSourceDurations(source: CGImageSource) throws -> [NSTimeInterval] {
        let count = CGImageSourceGetCount(source)
        guard let type = CGImageSourceGetType(source) where type == kUTTypeGIF && count > 1 else {
                throw InvalidDataError()
        }
        
        func getDelay(source: CGImageSource, index: Int) -> NSTimeInterval {
            var delay: NSTimeInterval = kDefaultDurationPerFrame
            let propertiesDict = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
            if (propertiesDict != nil) {
                let gifDictionaryPropertyKey = unsafeBitCast(kCGImagePropertyGIFDictionary, UnsafePointer<Void>.self)
                let gifProperties = CFDictionaryGetValue(propertiesDict, gifDictionaryPropertyKey)
                if (gifProperties != nil) {
                    let gifPropertiesDict = unsafeBitCast(gifProperties, CFDictionary.self)
                    let unclampedDelayTimePropertyKey = unsafeBitCast(kCGImagePropertyGIFUnclampedDelayTime, UnsafePointer<Void>.self)
                    var number = CFDictionaryGetValue(gifPropertiesDict, unclampedDelayTimePropertyKey)
                    if number != nil && unsafeBitCast(number, NSNumber.self).doubleValue >= kMinDurationPerFrame {
                        delay = unsafeBitCast(number, NSNumber.self).doubleValue
                    } else if number == nil {
                        let delayTimePropertyKey = unsafeBitCast(kCGImagePropertyGIFDelayTime, UnsafePointer<Void>.self)
                        number = CFDictionaryGetValue(gifPropertiesDict, delayTimePropertyKey)
                        if number != nil && unsafeBitCast(number, NSNumber.self).doubleValue >= kMinDurationPerFrame {
                            delay = unsafeBitCast(number, NSNumber.self).doubleValue
                        }
                    }
                }
            }
            return delay
        }
        
        return (0..<count).map{ getDelay(source, index: $0) }
    }
    
    public let scale: CGFloat
    public let totalTime: NSTimeInterval
    public let durations: [NSTimeInterval]
    public let firtImage: UIImage
    
    private let source: CGImageSource?
    
    public init(data:NSData, scale: CGFloat = UIScreen.mainScreen().scale) {
        source = CGImageSourceCreateWithData(data, nil)
        if let source = source, gifDurations = try? AnimatedGIFImage.getGIFSourceDurations(source) {
            totalTime = gifDurations.reduce(0){ $0 + $1 }
            durations = gifDurations.map{ $0 }
            if let image = decodeCGImage(CGImageSourceCreateImageAtIndex(source, 0, nil)) {
                 firtImage = UIImage(CGImage: image, scale: scale, orientation: .Up)
            } else {
                firtImage = UIImage()
            }
        } else {
            totalTime = kDefaultDurationPerFrame
            durations = [kDefaultDurationPerFrame]
            firtImage = UIImage(data: data, scale: scale) ?? UIImage()
        }
        self.scale = scale
    }
 
    public func imageAtIndex(index: Int) -> UIImage? {
        if let source = source, image = decodeCGImage(CGImageSourceCreateImageAtIndex(source, index % frameCount, nil)) {
            return UIImage(CGImage: image, scale: scale, orientation: .Up)
        }
        return nil
    }
}

// MARK: - imageArray
public class AnimatedFrameImage: AnimatedImage {
    public let scale: CGFloat
    public let totalTime: NSTimeInterval
    public let durations: [NSTimeInterval]
    public var firtImage: UIImage { return images[0] }
    
    private var images: [UIImage]
    
    public convenience init(animatedUIImage image: UIImage) {
        if let images = image.images {
            self.init(images: images, durations: Array<NSTimeInterval>(count: images.count, repeatedValue: image.duration))
        } else {
            self.init(images: [], durations: [])
        }
    }
        
    public init(images: [UIImage], var durations: [NSTimeInterval]) {
        if images.count == 0 && durations.count == 0 {
            self.images = [UIImage()]
            self.durations = [kDefaultDurationPerFrame]
            self.totalTime = kDefaultDurationPerFrame
            scale = self.images[0].scale
        } else {
            if durations.count < images.count {
                durations.appendContentsOf(Array<NSTimeInterval>(count: images.count - durations.count, repeatedValue: kDefaultDurationPerFrame))
            }
            let validImages = zip(images, durations).map { (image: $0, duration: $1 < kMinDurationPerFrame ? kDefaultDurationPerFrame : $1) }
            self.images = validImages.map { $0.image }
            self.durations = validImages.map { $0.duration }
            self.totalTime = self.durations.reduce(0){ $0 + $1 }
            self.scale = self.images[0].scale
        }
    }
    
    public func imageAtIndex(index: Int) -> UIImage? {
        let origin = images[index % frameCount]
        if let decoded = decodeCGImage(origin.CGImage) {
            return UIImage(CGImage: decoded, scale: scale, orientation: .Up)
        } else {
            return origin
        }
    }
}

