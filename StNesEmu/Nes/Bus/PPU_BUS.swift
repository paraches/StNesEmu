//
//  PPU_BUS.swift
//  StNesEmu
//
//  Created by paraches on 2018/11/06.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

class PPU_BUS: NSObject, Read, Write {
    var characterRAM: RAM
    
    init(characterRAM: RAM) {
        self.characterRAM = characterRAM
        
        super.init()
    }

    func read(_ address: Address) -> Byte {
        return characterRAM.read(address)
    }
    
    func read(_ address: Address) -> Word {
        return characterRAM.read(address)
    }
    
    func write(_ address: Address, _ data: Byte) {
        characterRAM.write(address, data)
    }
    
    func write(_ address: Address, _ data: Word) {
        characterRAM.write(address, data)
    }
}
