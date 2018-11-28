//
//  PPU.swift
//  StNesEmu
//
//  Created by paraches on 2018/11/23.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

class PPU: NSObject {
    struct PPUConfig {
        let isHorizontalMirror: Bool
    }
    
    typealias Sprite = [[UInt8]]
    
    struct SpriteWithAttribute {
        let sprite: Sprite
        let x: Byte
        let y: Byte
        let attr: Byte
        let spriteId: Byte
    }
    
    struct Tile {
        let sprite: Sprite
        let paletteId: Byte
        let scrollX: Byte
        let scrollY: Byte
    }
    
    struct RenderingData {
        let palette: Palette.PaletteRAM
        let background: [Tile]?
        let sprites: [SpriteWithAttribute]?
    }
    
    let SPRITE_NUMBER = 0x0100
    
    var registers = [Byte](repeating: 0, count: 0x08)
    var cycle: Int = 0
    var line: Int = 0
    var isValidVRAMAddr = false
    var isLowerVRAMAddr = false
    var isHorizontalScroll = true
    var spriteRAMAddr: Byte = 0
    var vRAMAddr: Word = 0x0000
    var vRAM = RAM(memory: [Byte](repeating: 0x00, count: 0x2000))
    var vRAMReadBuf: Byte = 0
    var spriteRAM = RAM(memory: [Byte](repeating: 0xFF, count: 0x0100))
    var background: [Tile] = [Tile]()
    var sprites = [SpriteWithAttribute]()
    var palette = Palette()
    var scrollX: Byte = 0
    var scrollY: Byte = 0
    
    var bus: PPU_BUS
    var interrupts: Interrupts
    var config: PPUConfig
    
    var cartridge: Cartridge?
    
    var vRAMOffset: Byte {
        get {
            return (registers[0x00][2] ? 32 : 1)
        }
    }
    
    var nameTableId: Byte {
        get {
            return registers[0x00] & 0x03
        }
    }
    
    var hasVBlankIRQEnabled: Bool {
        get {
            return registers[0][7]
        }
    }
    
    var isBackgroundEnable: Bool {
        get {
            return registers[0x01][3]
        }
    }
    
    var isSpriteEnable: Bool {
        get {
            return registers[0x01][4]
        }
    }
    
    var scrollTileX: Byte {
        get {
            return Byte((Word(scrollX) + (Word(nameTableId % 2) * 256)) / 8)
        }
    }
    
    var scrollTileY: Byte {
        get {
            return Byte((scrollY + ((nameTableId / 2) * 240)) / 8)
        }
    }
    
    var tileY: Byte {
        get {
            return Byte(line / 8) + scrollTileY
        }
    }
    
    var backgroundTableOffset: Word {
        get {
            return registers[0][4] ? 0x1000 : 0x0000
        }
    }
    
    var spriteTableOffset: Word {
        get {
            return registers[0][3] ? 0x1000 : 0x0000
        }
    }
    
    init(bus: PPU_BUS, interrupts: Interrupts, config: PPUConfig) {
        self.bus = bus
        self.interrupts = interrupts
        self.config = config
        
        super.init()
    }
    
    func getPalette() -> Palette.PaletteRAM {
        return palette.read()
    }
    
    func clearSpriteHit() {
        registers[0x02][6] = false
    }
    
    func setSpriteHit() {
        registers[0x02][6] = true
    }
    
    func hasSpriteHit() -> Bool {
        let y: Byte = spriteRAM.read(0)
        return (y == line) && isBackgroundEnable && isSpriteEnable
    }
    
    func setVBlank() {
        registers[0x02][7] = true
    }
    
    func isVBlank() -> Bool {
        return registers[0x02][7]
    }
    
    func clearVBlank() {
        registers[0x02][7] = false
    }
    
    
    //
    //  step
    //
    func run(_ cycle: Int) -> RenderingData? {
        self.cycle += cycle
        if line == 0 {
            background.removeAll()
            sprites.removeAll()
            buildSprites()
        }
        
        //
        //  finish 1 line
        //
        if self.cycle >= 341 {
            self.cycle -= 341
            line += 1
            
            if hasSpriteHit() {
                setSpriteHit()
            }
            
            //
            //  each 8 line, prepare 1 row of tile data (background tile)
            //
            if line <= 241 && (line - 1) % 8 == 0 && scrollY <= 240 {
                buildBackground()
            }
            
            //
            //  start VBlank
            //
            if line == 241 {
                setVBlank()
                if hasVBlankIRQEnabled {
                    interrupts.assertNMI()
                }
            }
            
            //
            //  ned VBlank and return 1 screen rendering data
            //
            if line == 262 {
                clearVBlank()
                clearSpriteHit()
                line = 0
                interrupts.deassertNMI()
                return RenderingData(palette: getPalette(),
                                     background: isBackgroundEnable ? background : nil,
                                     sprites: isSpriteEnable ? sprites : nil)
            }
        }
        
        return nil
    }
}
