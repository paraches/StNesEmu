//
//  CPU.swift
//  StNesEmu
//
//  Created by paraches on 2018/11/09.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

class CPU: NSObject, Read, Write {
    enum AddressingMode: String {
        case accumulator = "accumulator"
        case implied = "implied"
        case immediate = "immediate"
        case relative = "relative"
        case zeroPage = "zeroPage"
        case zeroPageX = "zeroPageX"
        case zeroPageY = "zeroPageY"
        case absolute = "absolute"
        case absoluteX = "absoluteX"
        case absoluteY = "absoluteY"
        case preIndexedIndirect = "preIndexedIndirect"
        case postIndexedIndirect = "postIndexedIndirect"
        case indirectAbsolute = "indirectAbsolute"
    }
    
    struct F {
        static let CARRY = 0
        static let ZERO = 1
        static let INTERRUPT = 2
        static let DECIMAL = 3
        static let BREAK = 4
        static let RESERVED = 5
        static let OVERFLOW = 6
        static let NEGATIVE = 7
    }
    
    var PC: Word = 0x0000
    var SP: Byte = 0xFD
    var A: Byte = 0x00
    var X: Byte = 0x00
    var Y: Byte = 0x00
    var P: Byte = 0x24
    
    var hasBranched: Bool = false
    
    var bus: CPU_BUS
    var interrupts: Interrupts
    
    init(bus: CPU_BUS, interrupts: Interrupts) {
        self.bus = bus
        self.interrupts = interrupts
        
        super.init()
    }

    //
    //  Read, Write to CPU_BUS
    //
    func read(_ address: Address) -> Byte {
        return bus.read(address)
    }
    
    func read(_ address: Address) -> Word {
        return bus.read(address)
    }
    
    func write(_ address: Address, _ data: Byte) {
        bus.write(address, data)
    }
    
    func write(_ address: Address, _ data: Word) {
        bus.write(address, data)
    }

    //
    //  Fetch code from memory
    //
    func fetch(_ address: Address) -> Byte {
        PC = PC &+ 1
        return read(address)
    }
    
    func fetchWord(_ address: Address) -> Word {
        PC = PC &+ 2
        return read(address)
    }
    
    //
    //  Stack
    //
    func push(_ data: Byte) {
        write(0x0100 | Address(SP), data)
        SP = SP &- 1
    }
    
    func pop() -> Byte {
        SP = SP &+ 1
        return read(0x0100 | Address(SP))
    }
    
    func pushStatus() {
        push(P)
    }
    
    func popStatus() {
        P = pop()
    }
    
    func pushPC() {
        push(PC.page)
        push(PC.offset)
    }
    func popPC() {
        let lpc = pop()
        let hpc = pop()
        PC = Address(page: hpc, offset: lpc)
    }
    
    //
    //  Jump
    //
    func branch(_ address: Address) {
        PC = address
        hasBranched = true
    }
    
    //
    //  Interrupts
    //
    func processNMI() {
        interrupts.deassertNMI()
        P[F.BREAK] = false
        pushPC()
        pushStatus()
        P[F.INTERRUPT] = true
        PC = read(0xFFFA)
    }
    
    func processIRQ() {
        if P[F.INTERRUPT] { return }
        
        interrupts.deassertIRQ()
        P[F.BREAK] = false
        pushPC()
        pushStatus()
        P[F.INTERRUPT] = true
        PC = read(0xFFFE)
    }
    
    //
    //  Reset
    //
    func resetRegisters() {
        SP = 0xFD
        A = 0x00
        X = 0x00
        Y = 0x00
        P = 0x24        //  Reserved, Interrupt
    }
    
    func reset() {
        resetRegisters()
        PC = read(0xFFFC)
    }
    
    //
    //  Step
    //
    @discardableResult
    func run(_ debug: Bool=false) -> Int {
        if interrupts.isNMIAssert() {
            processNMI()
        }
        
        if interrupts.isIRQAssert() {
            processIRQ()
        }
        
        let pc = PC
        let code: Byte = fetch(PC)
        if let opcode = OpCode.opcodeTable[code] {
            if let modeName = opcode["mode"] as? String,
                let mode = AddressingMode(rawValue: modeName),
                let baseName = opcode["baseName"] as? String,
                let cycle = opcode["cycle"] as? Int {
                let (addrOrData, additionalCycle) = getAddrOrDataWithAdditionalCycle(mode)
                if debug {
                    showStep(opcode: code, mode: mode, pc: pc)
                }
                execInstruction(baseName, addrOrData, mode)
                return cycle + additionalCycle + (hasBranched ? 1 : 0)
            }
        }
        
        return 1
    }
}
