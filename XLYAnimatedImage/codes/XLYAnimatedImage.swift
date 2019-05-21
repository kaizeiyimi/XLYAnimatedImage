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

private let kMinDurationPerFrame: TimeInterval = 0.01, kDefaultDurationPerFrame: TimeInterval = 0.1

// MARK: - image
public protocol AnimatedImage: class {
    var scale: CGFloat { get }
    var frameCount: Int { get }
    var totalTime: TimeInterval { get }
    var durations: [TimeInterval] { get }
    var firtImage: UIImage { get }
    func image(at index: Int) -> UIImage?
}

extension AnimatedImage {
    public var frameCount: Int { return durations.count }
}


// MARK: - mainly for GIF. 

/**
    ios device bug, count for apng will always be 1 bug simulator is ok.
    Now only support GIF, other will has only the first frame. (will try other way to decode apng)
*/
open class AnimatedDataImage: AnimatedImage {

    public let scale: CGFloat
    public let totalTime: TimeInterval
    public let durations: [TimeInterval]
    public let firtImage: UIImage
    
    private let source: CGImageSource?
    
    public init?(data:Data, scale: CGFloat = UIScreen.main.scale) {
        self.scale = scale
        source = CGImageSourceCreateWithData(data as CFData, nil)
        if let source = source, let gifDurations = try? getSourceDurations(source) {
            totalTime = gifDurations.reduce(0){ $0 + $1 }
            durations = gifDurations.map{ $0 }
            if let image = decodeCGImage(CGImageSourceCreateImageAtIndex(source, 0, nil)) {
                 firtImage = UIImage(cgImage: image, scale: scale, orientation: .up)
            } else {
                firtImage = UIImage()
            }
        } else {
            totalTime = 0
            durations = [0]
            if let image = UIImage(data: data, scale: scale) {
                firtImage = image
            } else {
                firtImage = UIImage()
                return nil
            }
        }
    }
 
    open func image(at index: Int) -> UIImage? {
        if let source = source, let image = decodeCGImage(CGImageSourceCreateImageAtIndex(source, index % frameCount, nil)) {
            return UIImage(cgImage: image, scale: scale, orientation: .up)
        }
        return nil
    }
}

// MARK: - imageArray
open class AnimatedFrameImage: AnimatedImage {
    public let scale: CGFloat
    public let totalTime: TimeInterval
    public let durations: [TimeInterval]
    public var firtImage: UIImage { return images[0] }
    
    private var images: [UIImage]
    
    public convenience init?(animatedUIImage image: UIImage) {
        if let images = image.images , images.count > 0 {
            self.init(images: images, durations: [TimeInterval](repeating: image.duration, count: images.count))
        } else {
            self.init(images: [image], durations: [image.duration])
        }
    }
        
    public init?(images: [UIImage], durations: [TimeInterval]) {
        var durations = durations
        if images.count == 0 && durations.count == 0 {
            (self.scale, self.totalTime, self.durations, self.images) = (0, 0, [], [])
            return nil
        } else {
            if durations.count < images.count {
                durations.append(contentsOf: Array<TimeInterval>(repeating: kDefaultDurationPerFrame, count: images.count - durations.count))
            }
            let validImages = zip(images, durations).map { (image: $0, duration: $1 < kMinDurationPerFrame ? kDefaultDurationPerFrame : $1) }
            self.images = validImages.map { $0.image }
            if validImages.count >= 2 {
                self.durations = validImages.map { $0.duration }
                self.totalTime = self.durations.reduce(0){ $0 + $1 }
            } else {
                self.durations = [0]
                self.totalTime = 0
            }
            self.scale = self.images[0].scale
        }
    }
    
    open func image(at index: Int) -> UIImage? {
        let origin = images[index % frameCount]
        if let decoded = decodeCGImage(origin.cgImage) {
            return UIImage(cgImage: decoded, scale: scale, orientation: .up)
        } else {
            return origin
        }
    }
}


// MARK: - helper methods

private struct InvalidAnimateDataError: Error {
    let description = "Data is not a valid animated image data or frame count not > 2."
}

/// stolen from SDWebImage's decoder. just change OC to swift.
private func decodeCGImage(_ image: CGImage?) -> CGImage? {
    guard let image = image else { return nil }
    var result: CGImage?
    autoreleasepool {
        let width = image.width, height = image.height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo = image.bitmapInfo.rawValue
        let infoMask = bitmapInfo & CGBitmapInfo.alphaInfoMask.rawValue
        let anyNonAlpha = (infoMask == CGImageAlphaInfo.none.rawValue ||
            infoMask == CGImageAlphaInfo.noneSkipFirst.rawValue ||
            infoMask == CGImageAlphaInfo.noneSkipLast.rawValue)
        
        if infoMask == CGImageAlphaInfo.none.rawValue && colorSpace.numberOfComponents > 1 {
            bitmapInfo &= ~CGBitmapInfo.alphaInfoMask.rawValue
            bitmapInfo |= CGImageAlphaInfo.noneSkipFirst.rawValue
        } else if !anyNonAlpha && colorSpace.numberOfComponents == 3 {
            bitmapInfo &= ~CGBitmapInfo.alphaInfoMask.rawValue
            bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue
        }
        
        let context = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: image.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo)
        
        context!.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        result = context!.makeImage()
    }
    return result
}

private func getSourceDurations(_ source: CGImageSource) throws -> [TimeInterval] {
    let count = CGImageSourceGetCount(source)
    guard let type = CGImageSourceGetType(source) , type == kUTTypeGIF && count > 1 else {
        throw InvalidAnimateDataError()
    }
    return (0..<count).map{ getGIFDelay(source: source, index: $0) }
}

private func getGIFDelay(source: CGImageSource, index: Int) -> TimeInterval {
    var delay: TimeInterval = kDefaultDurationPerFrame
    let propertiesDict = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
    if (propertiesDict != nil) {
        let dictionaryPropertyKey = unsafeBitCast(kCGImagePropertyGIFDictionary, to: UnsafeRawPointer.self)
        let properties = CFDictionaryGetValue(propertiesDict, dictionaryPropertyKey)
        if (properties != nil) {
            let propertiesDict = unsafeBitCast(properties, to: CFDictionary.self)
            let unclampedDelayTimePropertyKey = unsafeBitCast(kCGImagePropertyGIFUnclampedDelayTime, to: UnsafeRawPointer.self)
            var number = CFDictionaryGetValue(propertiesDict, unclampedDelayTimePropertyKey)
            if number != nil && unsafeBitCast(number, to: NSNumber.self).doubleValue >= kMinDurationPerFrame {
                delay = unsafeBitCast(number, to: NSNumber.self).doubleValue
            } else if number == nil {
                let delayTimePropertyKey = unsafeBitCast(kCGImagePropertyGIFDelayTime, to: UnsafeRawPointer.self)
                number = CFDictionaryGetValue(propertiesDict, delayTimePropertyKey)
                if number != nil && unsafeBitCast(number, to: NSNumber.self).doubleValue >= kMinDurationPerFrame {
                    delay = unsafeBitCast(number, to: NSNumber.self).doubleValue
                }
            }
        }
    }
    return delay
}
