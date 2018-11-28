//
//  DMA.swift
//  StNesEmu
//
//  Created by paraches on 2018/11/23.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

class DMA: NSObject {
    var isProcessing = false
    var ramAddr: Word = 0x0000
    var ram: RAM
    var ppu: PPU
    var addr: Byte = 0x00
    var cycle: Int = 0
    
    init(ram: RAM, ppu: PPU) {
        self.ram = ram
        self.ppu = ppu
        
        super.init()
    }
    
    
    //
    //  Transfer 64 Sprite data (0x0100) from Main memory to OAM (Sprite Memory)
    func runDMA() {
        if !isProcessing { return }
        
        for i in 0..<0x0100 {
            ppu.transferSprite(Byte(i), ram.read(ramAddr + Word(i)))
        }
        
        isProcessing = false
    }
    
    func write(_ data: Byte) {
        ramAddr = Word(data) << 8
        isProcessing = true
    }
}
