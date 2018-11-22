//
//  CPU+AddressingMode.swift
//  StNesEmu
//
//  Created by paraches on 2018/11/09.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

extension CPU {
    func getAddrOrDataWithAdditionalCycle(_ mode: AddressingMode) -> (Word, Int) {
        switch mode {
        case .accumulator:
            return (0x00, 0)
        case .implied:
            return (0x00, 0)
        case .immediate:
            let data: Byte = fetch(PC)
            return (Word(data), 0)
        case .relative:
            let baseAddr: Byte = fetch(PC)
            let addr = baseAddr < 0x0080 ? Address(baseAddr) &+ PC : Address(baseAddr) &+ PC &- 256
            return (addr, addr.page != PC.page ? 1 : 0)
        case .zeroPage:
            let data: Byte = fetch(PC)
            return (Address(data), 0)
        case .zeroPageX:
            let addr = fetch(PC)
            return (Address(addr &+ X), 0)
        case .zeroPageY:
            let addr = fetch(PC)
            return (Address(addr &+ Y), 0)
        case .absolute:
            return (fetchWord(PC), 0)
        case .absoluteX:
            let addr = fetchWord(PC)
            let additionalCycle = addr.page != (addr &+ Address(X)).page ? 1 : 0
            return (addr &+ Address(X), additionalCycle)
        case .absoluteY:
            let addr = fetchWord(PC)
            let additionalCycle = addr.page != (addr &+ Address(Y)).page ? 1 : 0
            return (addr &+ Address(Y), additionalCycle)
        case .preIndexedIndirect:
            let baseAddr = fetch(PC) &+ X
            let addr = Address(page: read(Address(baseAddr &+ 1)), offset: read(Address(baseAddr)))
            return (addr, addr.page != Address(baseAddr).page ? 1 : 0)
        case .postIndexedIndirect:
            let addrOrData = Address(page: 0x00, offset: fetch(PC))
            let baseAddr = indexYRead(addrOrData)
            let addr = baseAddr &+ Address(Y)
            return (addr, addr.page != baseAddr.page ? 1 : 0)
        case .indirectAbsolute:
            let addrOrData = fetchWord(PC)
            let address = Address(page: addrOrData.page, offset: addrOrData.offset &+ 1)
            let addr = Address(page: read(address), offset: read(addrOrData))
            return (addr, 0)
        }
    }
}
