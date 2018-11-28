//
//  Palette.swift
//  PaNES
//
//  Created by paraches on 2018/11/23.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

class Palette: NSObject {
    typealias PaletteRAM = Array<UInt8>
    
    var ram: PaletteRAM
    
    override init() {
        ram = Array<UInt8>(repeating: 0, count: 0x20)
        
        super.init()
    }
    
    func isSpriteMirror(_ addr: Byte) -> Bool {
        return (addr == 0x10) || (addr == 0x14) || (addr == 0x18) || (addr == 0x1c)
    }
    
    func isBackgroundMirror(_ addr: Byte) -> Bool {
        return (addr == 0x04) || (addr == 0x08) || (addr == 0x0c)
    }
    
    func read() -> PaletteRAM {
        return ram.enumerated().map { (index, element) -> Byte in
            if (isSpriteMirror(Byte(index))) { return ram[index - 0x10] }
            if (isBackgroundMirror(Byte(index))) { return ram[0x00] }
            return element
        }
    }
    
    func getPaletteAddr(_ addr: Byte) -> Byte {
        let mirrorDowned = (addr % 0x20)
        //NOTE: 0x3f10, 0x3f14, 0x3f18, 0x3f1c is mirror of 0x3f00, 0x3f04, 0x3f08, 0x3f0c
        return isSpriteMirror(mirrorDowned) ? mirrorDowned - 0x10 : mirrorDowned
    }
    
    func write(_ addr: Word, _ data: Byte) {
        ram[Int(getPaletteAddr(addr.offset))] = data
    }
}
