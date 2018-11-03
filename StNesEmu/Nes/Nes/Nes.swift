//
//  Nes.swift
//  StNesEmu
//
//  Created by paraches on 2018/11/03.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

class Nes: NSObject {
    var cpubus: CPU_BUS?
    
    private var loaded = false

    func loadCartridge(cartridge: Cartridge) -> Bool {
        //
        // Create 16K RAM and copy character data from Cartridge
        //
        let characterMem = RAM(memory: [UInt8](repeating: 0x00, count: 0x4000)) // Create 16K RAM
        for i: Address in 0..<cartridge.characterROM.size() {
            let data: Byte = cartridge.characterROM.read(i)
            characterMem.write(i, data)
        }

        //
        //  Working RAM 2K
        //
        let wRam = RAM(memory: [UInt8](repeating: 0x00, count: 0x0800))

        //
        //  CPU BUS
        //
        cpubus = CPU_BUS(ram: wRam, programROM: cartridge.programROM)
        guard let cpubus = cpubus else { return false }

        loaded = true
        return loaded
    }
}