//
//  CPU+Instruction.swift
//  StNesEmu
//
//  Created by paraches on 2018/11/09.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

extension CPU {
    struct Bit {
        static let MSB = 7
        static let LSB = 0
    }
    
    func updateNZ(_ data: Byte) {
        P[F.NEGATIVE] = data[Bit.MSB]
        P[F.ZERO] = data == 0
    }

    func execInstruction(_ baseName: String, _ addrOrData: Word, _ mode: AddressingMode) {
        hasBranched = false
        
        switch baseName {
        case "LDA":
            A = (mode == .immediate ? Byte(addrOrData) : read(addrOrData))
            updateNZ(A)
        case "LDX":
            X = (mode == .immediate ? Byte(addrOrData) : read(addrOrData))
            updateNZ(X)
        case "LDY":
            Y = (mode == .immediate ? Byte(addrOrData) : read(addrOrData))
            updateNZ(Y)
        case "STA":
            write(addrOrData, A)
        case "STX":
            write(addrOrData, X)
        case "STY":
            write(addrOrData, Y)
        case "TAX":
            X = A
            updateNZ(X)
        case "TAY":
            Y = A
            updateNZ(Y)
        case "TSX":
            X = SP
            updateNZ(X)
        case "TXA":
            A = X
            updateNZ(A)
        case "TXS":
            SP = X
        case "TYA":
            A = Y
            updateNZ(A)
        case "ADC":
            let data = mode == .immediate ? Byte(addrOrData) : read(addrOrData)
            let carry: Byte = P[F.CARRY] ? 1 : 0
            let operated = data &+ A &+ carry
            P[F.OVERFLOW] = (A ^ data) & 0x80 == 0 && (A ^ operated) & 0x80 != 0
            P[F.CARRY] = Word(data) + Word(A) + Word(carry) > 0xFF
            updateNZ(operated)
            A = operated
        case "AND":
            let data = mode == .immediate ? Byte(addrOrData) : read(addrOrData)
            A &= data
            updateNZ(A)
        case "ASL":
            if (mode == .accumulator) {
                P[F.CARRY] = A[Bit.MSB]
                A <<= 1
                updateNZ(A)
            }
            else {
                var data: Byte = read(addrOrData)
                P[F.CARRY] = data[Bit.MSB]
                data <<= 1
                write(addrOrData, data)
                updateNZ(data)
            }
        case "BIT":
            let data: Byte = read(addrOrData)
            P[F.NEGATIVE] = data[Bit.MSB]
            P[F.OVERFLOW] = data[6]
            P[F.ZERO] = (A & data) == 0
        case "CMP":
            let data = mode == .immediate ? Byte(addrOrData) : read(addrOrData)
            let operated = A &- data
            P[F.CARRY] = A >= data
            updateNZ(operated)
        case "CPX":
            let data = mode == .immediate ? Byte(addrOrData) : read(addrOrData)
            let operated = X &- data
            P[F.CARRY] = X >= data
            updateNZ(operated)
        case "CPY":
            let data = (mode == .immediate ? Byte(addrOrData) : read(addrOrData))
            let operated = Y &- data
            P[F.CARRY] = Y >= data
            updateNZ(operated)
        case "DEC":
            let data: Byte = read(addrOrData) &- 1
            updateNZ(data)
            write(addrOrData, data)
        case "DEX":
            X = X &- 1
            updateNZ(X)
        case "DEY":
            Y = Y &- 1
            updateNZ(Y)
        case "EOR":
            let data = mode == .immediate ? Byte(addrOrData) : read(addrOrData)
            A ^= data
            updateNZ(A)
        case "INC":
            let data: Byte = read(addrOrData) &+ 1
            updateNZ(data)
            write(addrOrData, data)
        case "INX":
            X = X &+ 1
            updateNZ(X)
        case "INY":
            Y = Y &+ 1
            updateNZ(Y)
        case "LSR":
            if mode == .accumulator {
                P[F.CARRY] = A[Bit.LSB]
                A >>= 1
                updateNZ(A)
            }
            else {
                var data: Byte = read(addrOrData)
                P[F.CARRY] = data[Bit.LSB]
                data >>= 1
                updateNZ(data)
                write(addrOrData, data)
            }
        case "ORA":
            let data = mode == .immediate ? Byte(addrOrData) : read(addrOrData)
            A |= data
            updateNZ(A)
        case "ROL":
            let carry: Byte = P[F.CARRY] ? 0x01 : 0x00
            if mode == .accumulator {
                P[F.CARRY] = A[Bit.MSB]
                A = A << 1 | carry
                updateNZ(A)
            }
            else {
                let data: Byte = read(addrOrData)
                P[F.CARRY] = data[Bit.MSB]
                let writeData = data << 1 | carry
                write(addrOrData, writeData)
                updateNZ(writeData)
            }
        case "ROR":
            let carry: Byte = P[F.CARRY] ? 0x80 : 0x00
            if mode == .accumulator {
                P[F.CARRY] = A[Bit.LSB]
                A = A >> 1 | carry
                updateNZ(A)
            }
            else {
                let data: Byte = read(addrOrData)
                P[F.CARRY] = data[Bit.LSB]
                let writeData = data >> 1 | carry
                write(addrOrData, writeData)
                updateNZ(writeData)
            }
        case "SBC":
            let data = mode == .immediate ? Byte(addrOrData) : read(addrOrData)
            let carry: Byte = P[F.CARRY] ? 1 : 0
            let operated = A &- data &- (1 - carry)
            let overflow = (A ^ data) & 0x80 != 0 && (A ^ operated) & 0x80 != 0
            P[F.OVERFLOW] = overflow
            P[F.CARRY] = Int(A) - Int(data) - Int(1 - carry) >= 0
            updateNZ(operated)
            A = operated
        case "PHA":
            push(A)
        case "PHP":
            push(P | 0x10)
        case "PLA":
            A = pop()
            updateNZ(A)
        case "PLP":
            popStatus()
            P[F.BREAK] = false
            P[F.RESERVED] = true
        case "JMP":
            PC = addrOrData
        case "JSR":
            let pc = PC &- 1
            push(pc.page)
            push(pc.offset)
            PC = addrOrData
        case "RTS":
            popPC()
            PC = PC &+ 1
            break
        case "RTI":
            popStatus()
            P[F.RESERVED] = true
            P[F.BREAK] = false
            popPC()
        case "BCC":
            if !P[F.CARRY] {
                branch(addrOrData)
            }
        case "BCS":
            if P[F.CARRY] {
                branch(addrOrData)
            }
        case "BEQ":
            if P[F.ZERO] {
                branch(addrOrData)
            }
        case "BNE":
            if !P[F.ZERO] {
                branch(addrOrData)
            }
        case "BMI":
            if P[F.NEGATIVE] {
                branch(addrOrData)
            }
        case "BPL":
            if !P[F.NEGATIVE] {
                branch(addrOrData)
            }
        case "BVS":
            if P[F.OVERFLOW] {
                branch(addrOrData)
            }
        case "BVC":
            if !P[F.OVERFLOW] {
                branch(addrOrData)
            }
        case "CLC":
            P[F.CARRY] = false
        case "CLD":
            P[F.DECIMAL] = false
        case "CLI":
            P[F.INTERRUPT] = false
        case "CLV":
            P[F.OVERFLOW] = false
        case "SEC":
            P[F.CARRY] = true
        case "SED":
            P[F.DECIMAL] = true
        case "SEI":
            P[F.INTERRUPT] = true
        case "BRK":
            PC = PC &+ 1
            push(PC.page)
            push(PC.offset)
            P[F.BREAK] = true
            pushStatus()
            P[F.INTERRUPT] = true
            PC = read(0xFFFE)
        case "NOP":
            break
//
//  Unofficial instructions
//
        case "NOPD":
            PC = PC &+ 1
        case "NOPI":
            PC = PC &+ 2
        case "LAX":
            X = read(addrOrData)
            A = X
            updateNZ(A)
        case "SAX":
            let operated = A & X
            write(addrOrData, operated)
        case "DCP":
            let operated: Byte = read(addrOrData) &- 1
            write(addrOrData, operated)
            updateNZ(A &- operated)
            P[F.CARRY] = A >= operated
        case "ISB":
            let data: Byte = read(addrOrData) &+ 1
            let carry: Byte = P[F.CARRY] ? 1 : 0
            let operated = ~data &+ A &+ carry
            let overflow = (A ^ data) & 0x80 != 0 && (A ^ operated) & 0x80 != 0
            P[F.OVERFLOW] = overflow
            P[F.CARRY] = Word(~data) + Word(A) + Word(carry) > 0xFF
            updateNZ(operated)
            A = operated
            write(addrOrData, data)
        case "SLO":
            var data: Byte = read(addrOrData)
            P[F.CARRY] = data[Bit.MSB]
            data = data << 1
            A |= data
            updateNZ(A)
            write(addrOrData, data)
        case "RLA":
            let carryValue: Byte = P[F.CARRY] ? 0x01 : 0x00
            let value: Byte = read(addrOrData)
            P[F.CARRY] = (value & 0x80) != 0
            let v: Byte = value << 1 | carryValue
            updateNZ(v)
            write(addrOrData, v)
            A &= v
        case "SRE":
            var data: Byte = read(addrOrData)
            P[F.CARRY] = data[Bit.LSB]
            data >>= 1
            A ^= data
            updateNZ(A)
            write(addrOrData, data)
        case "RRA":
            let carryValue: Byte = P[F.CARRY] ? 0x80 : 0x00
            let value: Byte = read(addrOrData)
            P[F.CARRY] = (value & 0x01) != 0
            
            let v: Byte = (value >> 1) | carryValue
            updateNZ(v)
            write(addrOrData, v)
            
            //  ADC
            let accumulator = A
            let carry: Byte = P[F.CARRY] ? 1 : 0
            
            let operated = v &+ A &+ carry
            A = operated
            updateNZ(A)
            
            P[F.CARRY] = Int16(accumulator) + Int16(v) + Int16(carry) > 0x00FF
            P[F.OVERFLOW] = (accumulator ^ v) & 0x80 == 0 && (A ^ accumulator) & 0x80 != 0
        default:
            print("Not implemented instruction: \(baseName), \(mode)")
        }
    }
}
