//
//  ImageBitmapCreator.swift
//  StNesEmu
//
//  Created by paraches on 2018/11/25.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation
import Cocoa

class ImageBitmapCreator: NSObject {
    struct PixelData {
        var r: UInt8
        var g: UInt8
        var b: UInt8
        var a: UInt8 = 0xFF
    }
    static let sizeOfPixelData = MemoryLayout<PixelData>.size
    
    static private let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    static private let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    
    static public func imageFromRGBA32Bitmap(pixels: [PixelData], width: Int, height: Int) -> CGImage? {
        let bitsPerComponent: Int = 8
        let bitsPerPixel: Int = 32
        
        var data = pixels
        if let providerRef = CGDataProvider(data: NSData(bytes: &data, length: data.count * sizeOfPixelData)) {
            let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bitsPerPixel: bitsPerPixel,
                bytesPerRow: width * sizeOfPixelData,
                space: rgbColorSpace,
                bitmapInfo: bitmapInfo,
                provider: providerRef,
                decode: nil,
                shouldInterpolate: true,
                intent: CGColorRenderingIntent.defaultIntent
            )
            return image
        }
        return nil
    }
}
