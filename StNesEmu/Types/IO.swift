//
//  IO.swift
//  StNesEmu
//
//  Created by paraches on 2018/10/31.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

protocol Read {
    func read(_ address: Address) -> Byte
    func read(_ address: Address) -> Word
}

protocol Write {
    func write(_ address: Address, _ data: Byte)
    func write(_ address: Address, _ data: Word)
}
