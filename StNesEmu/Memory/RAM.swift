//
//  RAM.swift
//  StNesEmu
//
//  Created by paraches on 2018/10/31.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

class RAM: ROM, Write {
    func write(_ address: Address, _ data: Byte) {
        memory[Int(address)] = data
    }
    
    func write(_ address: Address, _ data: Word) {
        memory[Int(address)] = data.offset
        memory[Int(address &+ 1)] = data.page
    }
}
