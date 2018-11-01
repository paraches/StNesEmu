//
//  ROM.swift
//  StNesEmu
//
//  Created by paraches on 2018/10/31.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

class ROM: NSObject, Read {
    var memory: [UInt8]
    
    init(memory: [UInt8]) {
        self.memory = memory
        super.init()
    }
    
    func read(_ address: Address) -> Byte {
        return memory[Int(address)]
    }
    
    func read(_ address: Address) -> Word {
        return Word(page: memory[Int(address &+ 1)], offset: memory[Int(address)])
    }

    func size() -> Word {
        return Word(memory.count)
    }
}
