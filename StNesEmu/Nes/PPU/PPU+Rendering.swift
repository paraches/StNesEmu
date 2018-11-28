//
//  PPU+Rendering.swift
//  StNesEmu
//
//  Created by paraches on 2018/11/23.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

extension PPU {
    func buildTile(tileX: Byte, tileY: Byte, offset: Word) -> Tile {
        let blockId = getBlockId(tileX: tileX, tileY: tileY)
        let spriteId = getSpriteId(tileX: tileX, tileY: tileY, offset: offset)
        let attr = getAttribute(tileX: tileX, tileY: tileY, offset: offset)
        let paletteId = (attr >> (blockId * 2)) & 0x03
        let sprite = buildSprite(spriteId: spriteId, offset: backgroundTableOffset)
        return Tile(sprite: sprite, paletteId: paletteId, scrollX: scrollX, scrollY: scrollY)
    }

    func buildBackground() {
        let clampedTileY = tileY % 30
        let tableIdOffset = ((tileY / 30) % 2) != 0 ? 2 : 0
        for x: Byte in 0..<33 {
            let tileX = x + scrollTileX
            let clampedTileX = tileX % 32
            let nameTableId = Word((tileX / 32) % 2) + Word(tableIdOffset)
            let offsetAddrByNameTable = nameTableId * 0x400
            let tile = buildTile(tileX: clampedTileX, tileY: clampedTileY, offset: offsetAddrByNameTable)
            background.append(tile)
        }
    }

    func buildSprites() {
        for i in stride(from: 0, to: SPRITE_NUMBER - 1, by: 4) {
            let y: Byte = spriteRAM.read(Word(i))
            if Int(y) - 8 < 0 || Int(y) - 8 >= 240 { continue }
            let spriteId: Byte = spriteRAM.read(Word(i + 1))
            let attr: Byte = spriteRAM.read(Word(i + 2))
            let x: Byte = spriteRAM.read(Word(i + 3))
            let sprite = buildSprite(spriteId: spriteId, offset: spriteTableOffset)
            let spriteWithAttribute = SpriteWithAttribute(sprite: sprite, x: x, y: y, attr: attr, spriteId: spriteId)
            sprites.append(spriteWithAttribute)
        }
    }

    func buildSprite(spriteId: Byte, offset: Word) -> Sprite {
        var sprite: Sprite = [[UInt8]](repeating: [UInt8](repeating: 0, count: 8), count: 8)
        for i in 0..<16 {
            for j in 0..<8 {
                let addr = Word(spriteId) * 16 + Word(i) + offset
                let ram = readCharacterRAM(addr)
                if (ram & 0x80 >> j) != 0 {
                    sprite[i % 8][j] += 0x01 << (i / 8)
                }
            }
        }
        return sprite
    }

    func getBlockId(tileX: Byte, tileY: Byte) -> Byte {
        return ((tileX % 4) / 2) + ((tileY % 4) / 2) * 2
    }
    
    func getAttribute(tileX: Byte, tileY: Byte, offset: Word) -> Byte {
        let addr = Word(tileX / 4) + Word((tileY / 4) * 8) + 0x03C0 + offset
        return vRAM.read(mirrorDownSpriteAddr(addr))
    }
    
    func getSpriteId(tileX: Byte, tileY: Byte, offset: Word) -> Byte {
        let tileNumber = Word(tileY) * 32 + Word(tileX)
        let spriteAddr = mirrorDownSpriteAddr(tileNumber + offset)
        return vRAM.read(spriteAddr)
    }
    
    func mirrorDownSpriteAddr(_ addr: Word) -> Word {
        if !config.isHorizontalMirror { return addr }
        if (addr >= 0x0400 && addr < 0x0800 || addr >= 0x0C00) {
            return addr - 0x0400
        }
        return addr
    }
    
}
