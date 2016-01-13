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


// MARK: - image
public protocol AnimatedImage: class {
    var scale: CGFloat { get }
    var frameCount: Int { get }
    var totalTime: NSTimeInterval { get }
    var durations: [NSTimeInterval] { get }
    func imageAtIndex(index: Int) -> UIImage?
}


public class GIFImage: AnimatedImage {
    public struct InvalidDataError: ErrorType {
        public let description = "Data is not a valid GIF data."
    }
    
    static func getGIFSourceDurations(source: CGImageSource) throws -> [NSTimeInterval] {
        let count = CGImageSourceGetCount(source)
        guard let type = CGImageSourceGetType(source) where type == kUTTypeGIF && count > 1 else {
                throw InvalidDataError()
        }
        
        func getDelay(source: CGImageSource, index: Int) -> NSTimeInterval {
            var delay: NSTimeInterval = 1
            let propertiesDict = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
            if (propertiesDict != nil) {
                let gifDictionaryPropertyKey = unsafeBitCast(kCGImagePropertyGIFDictionary, UnsafePointer<Void>.self)
                let gifProperties = CFDictionaryGetValue(propertiesDict, gifDictionaryPropertyKey)
                if (gifProperties != nil) {
                    let gifPropertiesDict = unsafeBitCast(gifProperties, CFDictionary.self)
                    let unclampedDelayTimePropertyKey = unsafeBitCast(kCGImagePropertyGIFUnclampedDelayTime, UnsafePointer<Void>.self)
                    var number = unsafeBitCast(CFDictionaryGetValue(gifPropertiesDict, unclampedDelayTimePropertyKey), NSNumber.self)
                    if (number.doubleValue == 0) {
                        let delayTimePropertyKey = unsafeBitCast(kCGImagePropertyGIFDelayTime, UnsafePointer<Void>.self)
                        number = unsafeBitCast(CFDictionaryGetValue(gifPropertiesDict, delayTimePropertyKey), NSNumber.self)
                    }
                    if (number.doubleValue > 0) {
                        delay = number.doubleValue
                    }
                }
            }
            return delay
        }
        
        return (0..<count).map{ getDelay(source, index: $0) }
    }
    
    public let scale: CGFloat
    public var frameCount: Int { return durations.count }
    public let totalTime: NSTimeInterval
    public let durations: [NSTimeInterval]
    
    private let source: CGImageSource?
    private var singleImage: UIImage?   // for invalid gif
    
    public init(data:NSData, scale: CGFloat = UIScreen.mainScreen().scale) {
        source = CGImageSourceCreateWithData(data, nil)
        if let source = source, gifDurations = try? GIFImage.getGIFSourceDurations(source) {
                totalTime = gifDurations.reduce(0){ $0 + $1 }
                durations = gifDurations.map{ $0 }
        } else {
            totalTime = 1
            durations = [1]
            singleImage = UIImage(data: data, scale: scale)
        }
        self.scale = scale
    }
 
    public func imageAtIndex(index: Int) -> UIImage? {
        if let source = source, image = decodeCGImage(CGImageSourceCreateImageAtIndex(source, index, nil)) {
            return UIImage(CGImage: image, scale: scale, orientation: .Up)
        }
        return nil
    }
}


/// stolen from SDWebImage's decoder. just change OC to swift.
private func decodeCGImage(image: CGImage?) -> CGImage? {
    guard let image = image else { return nil }
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
    return CGBitmapContextCreateImage(context)
}
