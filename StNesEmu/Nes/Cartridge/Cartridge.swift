//
//  Cartridge.swift
//  StNesEmu
//
//  Created by paraches on 2018/10/31.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

struct Cartridge {
    let isHorizontalMirror: Bool
    let characterROM: ROM
    let programROM: ROM
    let mapper: UInt8
}

extension Cartridge: CustomStringConvertible {
    var description: String {
        let h = "isHorizontalMirror: \(isHorizontalMirror)\n"
        let cROM = "characterROM: \(characterROM.size())\n"
        let pROM = "programROM: \(programROM.size())\n"
        let m = "mapper: \(mapper)"
        return h + cROM + pROM + m
    }
}
