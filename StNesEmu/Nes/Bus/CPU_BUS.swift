//
//  CPU_BUS.swift
//  StNesEmu
//
//  Created by paraches on 2018/11/03.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

class CPU_BUS: NSObject, Read, Write {
    var programROM: ROM     // Program ROM from Cartridge
    var ram: RAM            // Work RAM 2K
    var ppu: PPU
    var dma: DMA
    var keyPad: KeyPad
    
    init(ram: RAM, programROM: ROM, ppu: PPU, dma: DMA, keyPad: KeyPad) {
        self.programROM = programROM
        self.ram = ram
        self.ppu = ppu
        self.dma = dma
        self.keyPad = keyPad
        
        super.init()
    }
    
    func read(_ address: Address) -> Byte {
        if address < 0x0800 {           // Read Work RAM
            return ram.read(address)
        }
        else if address < 0x2000 {      // Read Work RAM Mirror
            return ram.read(address % 0x0800)
        }
        else if address < 0x4000 {
            let data = ppu.read((address - 0x2000) % 8)
            return data
        }
        else if address == 0x4016 {     // KeyPad
            let val: Byte = keyPad.read() ? 1 : 0
            return val
        }
        else if address >= 0xC000 {
            if programROM.size() <= 0x4000 {            // Cartridge size 16K
                return programROM.read(address - 0xC000)
            }
            return programROM.read(address - 0x8000)    // Cartridge size 32K
        }
        else if address >= 0x8000 {     // Cartridge size 32K
            return programROM.read(address - 0x8000)
        }
        else {
            return 0
        }
    }
    
    func read(_ address: Address) -> Word {
        if address < 0x0800 {           // Read Work RAM
            return ram.read(address)
        }
        else if address < 0x2000 {      // Read Work RAM Mirror
            let adrs = address & 0x0800
            return ram.read(adrs)
        }
        else if address >= 0xC000 {
            if programROM.size() <= 0x4000 {            // Cartridge size 16K
                return programROM.read(address - 0xC000)
            }
            return programROM.read(address - 0x8000)    // Cartridge size 32K
        }
        else if address >= 0x8000 {     // Cartridge size 32K
            return programROM.read(address - 0x8000)
        }
        else {
            return 0
        }
    }
    
    func write(_ address: Address, _ data: Byte) {
        if address < 0x0800 {
            ram.write(address, data)
        }
        else if address < 0x2000 {
            ram.write(address % 0x0800, data)
        }
        else if address < 0x4000 {
            ppu.write((address - 0x2000) % 8, data)
        }
        else if address == .oamDMA {
            dma.write(data)
        }
        else if address == 0x4016 {
            keyPad.write(data)
        }
        else {
            if let ram = programROM as? RAM {
                if ram.size() > 0x4000 {
                    ram.write(address - 0x8000, data)
                }
                else {
                    ram.write(address - 0x4000, data)
                }
            }
        }
    }
    
    func write(_ address: Address, _ data: Word) {
        if address < 0x0800 {
            ram.write(address, data)
        }
        else if address < 0x2000 {
            ram.write(address % 0x0800, data)
        }
        else {
            if let ram = programROM as? RAM {
                if ram.size() > 0x4000 {
                    ram.write(address - 0x8000, data)
                }
                else {
                    ram.write(address - 0x4000, data)
                }
            }
        }
    }
}

