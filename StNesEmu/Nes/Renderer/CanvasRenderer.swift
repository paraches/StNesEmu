//
//  CanvasRenderer.swift
//  StNesEmu
//
//  Created by paraches on 2018/11/25.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation
import Cocoa

class CanvasRenderer: NSObject {
    var nesView: NSImageView
    var fpsView: NSTextField
    var fps: Int = 0
    
    var background: [PPU.Tile]?
    var imageData = Array(repeating: ImageBitmapCreator.PixelData(r: 0, g: 0, b: 0, a: 0xFF), count: 240 * 256)
    
    init(nesView: NSImageView, fpsView: NSTextField) {
        self.nesView = nesView
        self.fpsView = fpsView
        
        super.init()
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            DispatchQueue.main.async {
                self.fpsView.stringValue = "\(self.fps) fps"
                self.fps = 0
            }
        })
    }
    
    func shouldPixelHide(_ x: Int, _ y: Int) -> Bool {
        guard let background = self.background else { return true }
        
        let tileX = x >> 3
        let tileY = x >> 3
        let backgroundIndex = tileY * 32 + tileX
        if backgroundIndex < background.count {
            let sprite = background[backgroundIndex].sprite
            return !((sprite[y % 8][x % 8] % 4) == 0)
        }
        else {
            return true
        }
    }
    
    func render(_ data: PPU.RenderingData) {
        fps += 1
        
        if let background = data.background {
            renderBackground(background, data.palette)
        }
        
        if let sprites = data.sprites {
            renderSprites(sprites, data.palette)
        }
        
        if let image = ImageBitmapCreator.imageFromRGBA32Bitmap(pixels: imageData, width: 256, height: 240) {
            DispatchQueue.main.async {
                self.nesView.image = NSImage(cgImage: image, size: CGSize.zero)
            }
        }
        else {
            print("image is nil")
        }
    }
    
    func renderBackground(_ background: [PPU.Tile], _ palette: Palette.PaletteRAM) {
        self.background = background
        for i in 0..<background.count {
            let x = (i % 33) * 8
            let y = (i / 33) * 8
            renderTile(tile: background[i], tileX: x, tileY: y, palette: palette)
        }
    }
    
    func renderSprites(_ sprites: [PPU.SpriteWithAttribute], _ palette: Palette.PaletteRAM) {
        for sprite in sprites {
            renderSprite(sprite, palette)
        }
    }
    
    func renderTile(tile: PPU.Tile, tileX: Int, tileY: Int, palette: Palette.PaletteRAM) {
        let offsetX = Int(tile.scrollX % 8)
        let offsetY = Int(tile.scrollY % 8)
        
        for i in 0..<8 {
            for j in 0..<8 {
                let paletteIndex = Int(tile.paletteId) * 4 + Int(tile.sprite[i][j])
                let colorId = Int(palette[paletteIndex])
                if colorId >= Colors.Table.count { continue }
                let color = Colors.Table[colorId]
                let x = tileX + j - offsetX
                let y = tileY + i - offsetY
                if (x >= 0 && 0xFF >= x && y >= 0 && y < 240) {
                    let index = (x + (y * 256))
                    imageData[index].r = color[0]
                    imageData[index].g = color[1]
                    imageData[index].b = color[2]
                }
            }
        }
    }
    
    func renderSprite(_ sprite: PPU.SpriteWithAttribute, _ palette: Palette.PaletteRAM) {
        let isVerticalReverse = sprite.attr[.MSB]
        let isHorizontalReverse = sprite.attr[6]
        let isLowPriority = sprite.attr[5]
        let paletteId = sprite.attr & 0x03
        for i in 0..<8 {
            for j in 0..<8 {
                let x = Int(sprite.x) + (isHorizontalReverse ? 7 - j : j)
                let y = Int(sprite.y) + (isVerticalReverse ? 7 - i : i)
                if isLowPriority && self.shouldPixelHide(x, y) || !(0 <= y && y < 240) {
                    continue
                }
                if sprite.sprite[i][j] != 0 {
                    let colorId = Int(palette[Int(paletteId) * 4 + Int(sprite.sprite[i][j]) + 0x10])
                    let color = Colors.Table[colorId]
                    let index = (x + (y * 256))
                    if index < imageData.count {
                        imageData[index].r = color[0]
                        imageData[index].g = color[1]
                        imageData[index].b = color[2]
                    }
                }
            }
        }
    }
}
