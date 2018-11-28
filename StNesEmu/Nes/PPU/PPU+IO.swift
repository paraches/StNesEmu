//
//  PPU+IO.swift
//  StNesEmu
//
//  Created by paraches on 2018/11/23.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation


extension Address {
    static let ppuCtrl: Address = 0x2000
    static let ppucMask: Address = 0x2001
    static let ppuStatus: Address = 0x2002
    static let oamAddress: Address = 0x2003
    static let oamData: Address = 0x2004
    static let ppuScroll: Address = 0x2005
    static let ppuAddress: Address = 0x2006
    static let ppuData: Address = 0x2007
    static let oamDMA: Address = 0x4014
}

extension PPU {
    //
    //  Character RAM
    //
    func readCharacterRAM(_ addr: Word) -> Byte {
        return bus.read(addr)
    }
    
    func writeCharacterRAM(_ addr: Word, _ data: Byte) {
        bus.write(addr, data)
    }

    //
    //  VRAM
    //
    func readVRam() -> Byte {
        let buf = vRAMReadBuf
        if vRAMAddr >= 0x2000 {
            let addr = calcVRAMAddr()
            vRAMAddr += Word(vRAMOffset)
            if addr >= 0x3F00 {
                return vRAM.read(addr)
            }
            vRAMReadBuf = vRAM.read(addr)
        }
        else {
            vRAMReadBuf = readCharacterRAM(vRAMAddr)
            vRAMAddr += Word(vRAMOffset)
        }
        return buf
    }

    //
    //
    //
    func read(_ addr: Word) -> Byte {
        switch 0x2000 + addr {
        case .ppuStatus:
            isHorizontalScroll = true
            let data = registers[Int(addr)]
            clearVBlank()
            return data
        case .oamData:
            return spriteRAM.read(Word(spriteRAMAddr))
        case .ppuData:
            return readVRam()
        default:
            return 0
        }
    }
    
    func write(_ addr: Word, _ data: Byte) {
        switch 0x2000 + addr {
        case .oamAddress:
            writeSpriteRAMAddr(data)
        case .oamData:
            writeSpriteRAMData(data)
        case .ppuScroll:
            writeScrollData(data)
        case .ppuAddress:
            writeVRAMAddr(data)
        case .ppuData:
            writeVRAMData(data)
        default:
            registers[Int(addr)] = data
        }
    }

    //
    //  Sprite RAM  (OAM)
    //
    func writeSpriteRAMAddr(_ data: Byte) {
        spriteRAMAddr = data
    }
    
    func writeSpriteRAMData(_ data: Byte) {
        spriteRAM.write(Word(spriteRAMAddr), data)
        spriteRAMAddr = spriteRAMAddr &+ 1
    }

    //
    //  Scroll data
    //
    func writeScrollData(_ data: Byte) {
        if isHorizontalScroll {
            isHorizontalScroll = false
            scrollX = data
        }
        else {
            scrollY = data
            isHorizontalScroll = true
        }
    }

    //
    //  VRAM
    //
    func writeVRAMAddr(_ data: Byte) {
        if isLowerVRAMAddr {
            vRAMAddr += Word(data)
            isLowerVRAMAddr = false
            isValidVRAMAddr = true
        }
        else {
            vRAMAddr = Word(data) << 8
            isLowerVRAMAddr = true
            isValidVRAMAddr = false
        }
    }
    
    func calcVRAMAddr() -> Word {
        if vRAMAddr >= 0x3000 && vRAMAddr < 0x3F00 {
            vRAMAddr -= 0x3000
            return vRAMAddr
        }
        else {
            return vRAMAddr - 0x2000
        }
    }

    func writeVRAMData(_ data: Byte) {
        if vRAMAddr >= 0x2000 {
            if vRAMAddr >= 0x3F00 && vRAMAddr < 0x4000 {
                palette.write(vRAMAddr - 0x3F00, data)
            }
            else {
                writeVRAM(calcVRAMAddr(), data)
            }
        }
        else {
            writeCharacterRAM(vRAMAddr, data)
        }
        vRAMAddr += Word(vRAMOffset)
    }
    
    func writeVRAM(_ addr: Word, _ data: Byte) {
        vRAM.write(addr, data)
    }

    //
    //  OAM DMA
    //
    func transferSprite(_ index: Byte, _ data: Byte) {
        let addr = Word(index) + Word(spriteRAMAddr)
        spriteRAM.write(addr % 0x0100, data)
    }

}
