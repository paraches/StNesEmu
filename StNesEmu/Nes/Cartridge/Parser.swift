//
//  Parser.swift
//  StNesEmu
//
//  Created by paraches on 2018/10/31.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

class Parser {
    static let NES_HEADER_SIZE = 0x0010
    static let PROGRAM_ROM_SIZE = 0x4000    // 16K
    static let CHARACTER_ROM_SIZE = 0x2000
    static let NES_ROM_ID = [0x4E, 0x45, 0x53, 0x1A]
    
    static func parse(_ data: Data) -> Cartridge? {
        guard data.count > NES_HEADER_SIZE else { return nil }
        
        let idData = data.subdata(in: 0 ..< NES_ROM_ID.count)
        let result = idData.elementsEqual(NES_ROM_ID) {$0 == $1}
        if !result {
            return nil
        }
        
        let programRomPages = Int(data[0x0004])
        let characterRomPages = Int(data[0x0005])
        let isHorizontalMirror = data[0x0006][0]    // Bit 0

        let mapper: UInt8 = ((data[0x0006] & 0xF0) >> 4) | (data[0x0007] & 0xF0)
        guard mapper == 0 || mapper == 2 else { return nil }

        let characterRomStart = NES_HEADER_SIZE + programRomPages * PROGRAM_ROM_SIZE
        let characterRomEnd = characterRomStart + characterRomPages * CHARACTER_ROM_SIZE

        let programRom = ROM(memory: [UInt8](data.subdata(in: NES_HEADER_SIZE..<characterRomStart)))
        let characterRom = ROM(memory: [UInt8](data.subdata(in: characterRomStart..<characterRomEnd)))

        return Cartridge(isHorizontalMirror: isHorizontalMirror,
                         characterROM: characterRom,
                         programROM: programRom,
                         mapper: mapper)
    }
}
